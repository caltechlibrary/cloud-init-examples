# InvenioRDM Fast Deployment Strategy — Implementation Spec for Clasm

## Purpose of this document

This is an implementation-ready spec for extending our internal AWS automation tool, **Clasm**, to support fast InvenioRDM environment provisioning for two use cases: dev/bugfix spin-ups and major-release migrations. It's written to be handed to an engineer or an AI coding agent (e.g. Claude Code) as the basis for implementation — it includes exact commands, required inputs/config, error-handling expectations, and acceptance criteria for each proposed Clasm subcommand.

**Before implementing:** inspect the existing Clasm codebase structure (CLI framework used, existing command patterns, config file format, existing AWS credential handling) and adapt the command names, flag conventions, and code organization below to match. The subcommand names used here (`clasm snapshot pg`, etc.) are illustrative — match Clasm's existing naming conventions instead if they differ.

---

## Problem statement

Current process to spin up a new InvenioRDM environment from production data:

1. Load Postgres from a plain SQL dump — ~45 minutes.
2. Rebuild OpenSearch indices from Postgres via `invenio index init` + `invenio rdm rebuild-all-indices` — most of a business day for 100,000+ records.
3. Step 2 also **permanently loses usage statistics**, because `invenio-stats` (the module powering InvenioRDM's view/download counts) stores raw events and pre-aggregated stats *only* in OpenSearch indices (`events-*`, `stats-*`), never in Postgres. There is no way to regenerate this data from the database.

This makes full-scale production clones impractical for routine dev work (teams fall back to small unrepresentative samples) and slow for major-version migrations.

## Solution overview

Split data by source of truth and use the cheapest correct recovery method for each:

| Data | Source of truth | Recovery method | Rebuildable from Postgres? |
|---|---|---|---|
| Records, vocabularies, communities | Postgres | Fast Postgres restore (parallel `pg_restore` or EBS clone) + OpenSearch reindex | Yes |
| Usage stats (events/aggregations) | OpenSearch only | OpenSearch snapshot → S3 → restore | **No — must be preserved via snapshot** |
| Digital objects | S3 | Unchanged, already shared | N/A |

Two deployment paths:

- **Path A — Same-version clone (dev/bugfix use case):** EBS volume snapshot/clone of both the Postgres and OpenSearch data volumes. No dump/restore, no reindex. Minutes end to end. Requires source and target to run identical Postgres and OpenSearch major versions.
- **Path B — Cross-version migration (major release use case):** parallel Postgres dump/restore, OpenSearch stats-only snapshot/restore via S3, and a full record-index rebuild from the restored Postgres data (needed anyway since RDM releases often change index mappings).

---

## Prerequisites / assumed environment

- AWS CLI configured with an IAM principal that has: `ec2:CreateSnapshot`, `ec2:CreateVolume`, `ec2:AttachVolume`, `ec2:DescribeSnapshots`, `ec2:DescribeVolumes`, and S3 read/write on the snapshot bucket.
- An S3 bucket dedicated to OpenSearch snapshot repositories (separate from the InvenioRDM file-storage bucket), e.g. `s3://<org>-rdm-os-snapshots/`.
- The `repository-s3` OpenSearch plugin installed on every node of both source and target OpenSearch clusters, with credentials in the OpenSearch keystore or via an attached IAM role:
  ```bash
  bin/opensearch-plugin install repository-s3
  bin/opensearch-keystore add s3.client.default.access_key
  bin/opensearch-keystore add s3.client.default.secret_key
  ```
- Network/security-group access from Clasm's execution environment to both the source and target OpenSearch REST endpoints and Postgres instances.
- `pg_dump`/`pg_restore` client tools matching the Postgres server major version, available in Clasm's execution environment.

---

## Command specs

### 1. `clasm snapshot pg`

**Purpose:** produce a fast, restorable Postgres backup.

**Inputs:**
- `--mode [dump|ebs]` (default `dump`)
- `--db-host`, `--db-name`, `--db-user` (password via env var `PGPASSWORD` or secrets manager reference, never as a plain CLI flag)
- `--ebs-volume-id` (required if `--mode ebs`)
- `--output-label` (used to name the resulting artifact/snapshot, default to `rdm-pg-<UTC timestamp>`)

**Behavior:**
- `--mode dump`: run
  ```bash
  pg_dump -Fc -f "${output_label}.custom" -h "$db_host" -U "$db_user" "$db_name"
  ```
  then upload the resulting file to a designated S3 backup bucket/prefix and record the S3 key.
- `--mode ebs`: call `aws ec2 create-snapshot --volume-id "$ebs_volume_id" --description "$output_label"`, poll `aws ec2 describe-snapshots` until `State == completed`, and record the resulting `SnapshotId`.

**Outputs:** JSON written to stdout (and optionally a Clasm state/log store) containing:
```json
{ "mode": "dump|ebs", "label": "...", "s3_key": "...", "snapshot_id": "...", "created_at": "ISO8601", "db_name": "...", "pg_version": "..." }
```
`pg_version` should be captured via `psql -h ... -c "SHOW server_version;"` at snapshot time and stored — this is needed later to validate Path A eligibility.

**Error handling:** fail loudly (non-zero exit, clear message) on: dump/snapshot command non-zero exit, S3 upload failure, or EBS snapshot entering an `error` state. Do not silently retry without surfacing at least one warning to the caller.

---

### 2. `clasm restore pg`

**Purpose:** restore a Postgres backup produced by `clasm snapshot pg` onto a target instance.

**Inputs:**
- `--source` (S3 key or EBS snapshot ID, or the JSON output object from step 1)
- `--target-db-host`, `--target-db-name`, `--target-db-user`
- `--target-ebs-volume-id` / `--target-az` (for EBS mode — creates a new volume and returns its ID for attachment)
- `--parallel-jobs` (default 8, used for dump-mode restore only)

**Behavior:**
- Dump mode:
  ```bash
  pg_restore -j "$parallel_jobs" --no-owner --no-privileges -h "$target_db_host" -U "$target_db_user" -d "$target_db_name" "${downloaded_dump_path}"
  ```
- EBS mode:
  ```bash
  aws ec2 create-volume --snapshot-id "$snapshot_id" --availability-zone "$target_az" --volume-type gp3
  ```
  Poll until `available`, then output the new `VolumeId` for Clasm's instance-provisioning step to attach and mount at the Postgres data directory.

**Validation before running EBS mode:** compare the `pg_version` recorded at snapshot time against the target Postgres server's version (`psql ... -c "SHOW server_version;"`). If they differ at the major-version level, refuse to proceed with EBS mode and instruct the caller to use dump mode instead. This is the Path A/Path B fork point — surface it as an explicit check, not an assumption.

**Outputs:** success/failure status, elapsed time, and (EBS mode) the new volume ID.

---

### 3. `clasm snapshot stats`

**Purpose:** back up only the InvenioRDM usage-statistics indices from OpenSearch — the data that has no Postgres equivalent and must never be handled by a destructive reindex.

**Inputs:**
- `--os-host` (source OpenSearch endpoint)
- `--repo-name` (default `rdm-stats-repo`)
- `--s3-bucket`, `--s3-base-path` (for first-time repo registration)
- `--snapshot-label` (default `stats-<UTC timestamp>`)

**Behavior:**
1. Idempotently ensure the S3 snapshot repository is registered:
   ```
   PUT /_snapshot/{repo_name}
   { "type": "s3", "settings": { "bucket": "{s3_bucket}", "base_path": "{s3_base_path}", "region": "<region>" } }
   ```
   (Skip if a `GET /_snapshot/{repo_name}` already returns the expected config.)
2. Trigger the snapshot, scoped explicitly to stats/events indices only — never omit the `indices` filter, to avoid accidentally sweeping in multi-hundred-GB record indices:
   ```
   PUT /_snapshot/{repo_name}/{snapshot_label}
   { "indices": "events-*,stats-*,stats-bookmarks", "include_global_state": false }
   ```
3. Poll `GET /_snapshot/{repo_name}/{snapshot_label}/_status` until `state == SUCCESS`. Treat `PARTIAL` or `FAILED` as an error and surface the failed shard details.

**Outputs:**
```json
{ "repo": "...", "snapshot_label": "...", "os_version": "...", "indices": ["events-*","stats-*","stats-bookmarks"], "created_at": "ISO8601" }
```
Capture `os_version` via `GET /` on the source cluster — needed for the cross-version compatibility check in the restore step.

---

### 4. `clasm restore stats`

**Purpose:** restore stats indices onto a new OpenSearch cluster.

**Inputs:**
- `--os-host` (target OpenSearch endpoint)
- `--repo-name`, `--snapshot-label` (or the JSON object from step 3)

**Behavior:**
1. Ensure the repository is registered on the target cluster (same call as above).
2. Check target OpenSearch major version against the `os_version` recorded at snapshot time. OpenSearch snapshots are only forward-compatible by one major version — if the gap is larger, fail with a clear message recommending an intermediate-cluster remote-reindex path rather than attempting the restore.
3. Restore:
   ```
   POST /_snapshot/{repo_name}/{snapshot_label}/_restore
   { "indices": "events-*,stats-*,stats-bookmarks" }
   ```
4. Poll cluster health / index recovery status until restored indices report `status: green` or `yellow` (not `red`).

**Outputs:** success/failure, list of restored index names, elapsed time.

---

### 5. `clasm rebuild records`

**Purpose:** rebuild record/vocabulary/community OpenSearch indices from a freshly restored Postgres database, with bulk-load performance tuning applied automatically.

**Inputs:**
- `--os-host`, `--index-pattern` (default covers all `invenio index init`-managed indices, excluding `events-*`/`stats-*` so this command never touches stats data)
- `--celery-concurrency` (temporarily scale worker count for the rebuild window; default: current setting × 4, revert after)
- `--invenio-cli-path` (how to invoke `invenio` in the target environment — container exec, SSH, etc.; match Clasm's existing pattern for running commands inside app containers)

**Behavior (sequence):**
1. For each matching index, apply bulk-load settings:
   ```
   PUT /{index_pattern}/_settings
   { "index": { "refresh_interval": "-1", "number_of_replicas": 0 } }
   ```
2. Scale Celery indexing-worker concurrency to `--celery-concurrency`.
3. Run, in order:
   ```bash
   invenio index destroy --yes-i-know
   invenio index init
   invenio rdm rebuild-all-indices
   ```
4. Poll for indexing queue drain (Celery queue length back to zero, or `invenio index list` showing expected doc counts vs. Postgres record counts).
5. Revert settings:
   ```
   PUT /{index_pattern}/_settings
   { "index": { "refresh_interval": "1s", "number_of_replicas": 1 } }
   ```
6. Revert Celery concurrency to its prior value.

**Important:** this command must never include `events-*`/`stats-*` in its index pattern — that data comes only from `clasm restore stats`, never from a rebuild. Add an explicit guard that refuses to run if the resolved index pattern would match a stats/events index.

**Outputs:** doc counts per rebuilt index, elapsed time, before/after settings diff for audit logging.

---

### 6. `clasm clone dev`

**Purpose:** one-command orchestration of Path A (same-version dev clone) — the primary lever for making full-scale production data practical for routine dev use.

**Inputs:**
- `--source-pg-volume-id`, `--source-os-volume-id`
- `--target-az`
- `--scrub-stats` (boolean flag, default `true` — see note below)

**Behavior:**
1. Version check: confirm target environment's intended Postgres and OpenSearch versions match the source (query source instances directly, or accept `--expected-pg-version`/`--expected-os-version` flags for a pre-provisioned target). Refuse and instruct the caller to use Path B commands instead if versions won't match.
2. `aws ec2 create-snapshot` for both volumes; poll to completion.
3. `aws ec2 create-volume --snapshot-id ... --availability-zone <target-az>` for both.
4. Hand off the resulting volume IDs to Clasm's existing instance/container provisioning flow for attachment and mount.
5. If `--scrub-stats` is true, after the new environment is up, run an anonymization pass over the `events-*` indices in the *new* environment only (strip/hash IP address and user-agent fields per existing anonymization logic already used by `invenio-stats` in production, if such a preprocessor is already configured — otherwise flag this as a follow-up item rather than skipping silently).

**Outputs:** new volume IDs, elapsed time, confirmation of scrub step (ran / skipped / not-applicable).

---

## End-to-end flows

### Dev/bugfix spin-up
```
clasm clone dev --source-pg-volume-id vol-xxxx --source-os-volume-id vol-yyyy --target-az us-east-1a
```
Single command; no dump/restore or reindex involved.

### Major-release migration
```
clasm snapshot pg --mode dump --db-host prod-db --db-name inveniordm
clasm snapshot stats --os-host prod-os.internal
clasm restore pg --source <pg-snapshot-output> --target-db-host new-db --target-db-name inveniordm --parallel-jobs 8
clasm restore stats --os-host new-os.internal --repo-name rdm-stats-repo --snapshot-label <label-from-step-2>
clasm rebuild records --os-host new-os.internal --celery-concurrency 16
# then proceed with standard RDM version upgrade steps on the new instance
```

---

## Acceptance criteria for this implementation

- [ ] `clasm snapshot stats` / `clasm restore stats` never touch record indices, and vice versa for `clasm rebuild records` (enforced by explicit guards, not just documentation).
- [ ] Every command that calls AWS or OpenSearch APIs handles and surfaces failure states (no silent success on partial completion).
- [ ] `clasm clone dev` refuses to proceed automatically if Postgres/OpenSearch major versions won't match, rather than producing a corrupted clone.
- [ ] All snapshot artifacts are labeled with enough metadata (timestamp, source version, index scope) to be identifiable months later.
- [ ] A dry-run/`--plan` flag exists on the multi-step commands (`clone dev`, `rebuild records`) so users can preview actions before executing against production-derived data.

## Open questions to resolve during implementation

- Retention/lifecycle policy for stats snapshots in S3 (e.g. S3 lifecycle rule to expire after N days, keep last N snapshots).
- Where Clasm should store run metadata/state (existing Clasm state store vs. a new DynamoDB table vs. local JSON log).
- Whether an existing `invenio-stats` anonymization preprocessor is already configured in production (needed to implement the `--scrub-stats` step in `clasm clone dev` correctly rather than as a stub).
