
# RDM test and development

Caltech Library maintains a collection of [cloud init](https://cloudinit.readthedocs.io/en/latest/index.html) examples capability of being run via AWS or for local development purposes via [Multipass](https://multipass.run). The [cloud init examples](https://github.com/caltechlibrary/cloud-init-examples) GitHub repository includes both Bash scripts for working with Multipass and the cloud init YAML files for various projects. This includes setting up test and development instances of Invenio RDM.

If you are developing with Multipass then getting a Ubuntu instance up with right Python, NodeJS, NPM is as easy running `./invenio_rdm_machine.bash`. This will create an Ubuntu Jammy instance with Python 3.9, NodeJS 14.x and NPM 5.x as is required for the v11 STS releaseof RDM. After running the Bash script you can then log into your VM instance using the Multipass command `multipass shell invenio-rdm`.

Three scripts are provided to install one of three RDM configurations.

`setup_rdm_caltechauthors.bash`
: This will setup an empty instance of RDM based on <https://github.com/caltechlibrary/caltechauthors>

`setup_rdm_caltechdata.bash`
: This will setup an empty instance of RDM base on <https://github.com/caltechlibrary/caltechdata>

`setup_rdm_instance.bash`
: This will setup a vanilla (unmodified) instance of RDM

Additional scripts are provided for managing your RDM instance running in your multipass VM, dumping and restoring the OpenSearch indexes as well as scripts to backup, restore and run SQL command against the containerized Postgres that
manages RDM's metadata.

`invenio_ctl.bash`
: This provides a simple script to bring RDM up, check the status and bring it down.

`opensearch_indexes_dump.bash`
: This script will dump the OpenSearch indexes (including RDM status) in a format that they can be reloaded.

`opensearch_indexes_restore.bash`
: This script will restore a previously dumped set of indexes.

`invenio_sql_command.bash`
: Run a SQL command from the command line in the RDM container holding Postgres

`invenio_sql_backups.bash`
: Backup the SQL data running in the Postgres container.

`invenio_sql_restore.bash`
: Restore a previosly backed up SQL data to the Postgres in th RDM ontainer.
