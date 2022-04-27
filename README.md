cloud-init-examples
===================

This repository includes some example of cloud-init YAML files for use with multipass in creating some virtual machines.

Multipass
---------

[Mulitpass](https://multipass.run) is a tool for running and managing Ubuntu VMs. It is a little lighter wait then running VirtualBox, works across operating systems (e.g. Windows, macOS, Linux) and also processor types (e.g. Intel an ARM). This means you can easily run VMs on Raspberry Pi or your favor macOS or Windows machine.  The VM will match your host CPU architecture (i.e. you're not running full emulation but using running as a Intel box on an Intel host or a ARM box on a Raspberry Pi or M1 Mac).  VM's can be easily started, stopped and created.  The setup script is YAML rather than Ruby like with vagrant. There are a small number of commands to learn (i.e. `multipass --help` covers them all). Multipass is NOT as featureful as VirtualBox or Parallels but it does seem to be much lighter weight and the things you can adjust (e.g. RAM, CPU cores) are the ones you likely want to adjust anyway. It is focused on easily bringing up a server like environment for testing and development.

Common multipass commands
-------------------------

Get a list of VMs available 

```
multipass list
```

Set a VM as primary (e.g. a machine named "dev") so you don't
have to provide a name with each command.

```
multipass set client.primary-name=dev
```

Access the primary VM

```
multipass shell
```

Stop/Start the VM

```
multipass stop
multipass start
```

Stop all the VM, delete them and purge them from disk.

```
multipass stop --all
multipass delete --all
multipass purge
```


Cloud Init Files
----------------

[Cloud Init](https://cloud-init.io) is a specification for bringing up a virtual machine (or container) using a YAML syntax. It can be relatively simple (see the minimal example) to elaborate (the dev example). You can specify things like users, packages to be installed, host files to be mounted or even shell scripts to run.

Minimal Py
----------

The `make-minimal-py-vm.bash` scripts creates a minimal python development box described in minimal-py-init.yaml. It doens't create users or install more than python3 and pip.

The Dev VM
----------

This will create a VM named "dev". It includes a more complete server development environment including support for Go version 1.18.x.  It includes examples of installing packages via apt and snaps.

```
bash make-dev-vm.bash
```

Access VM as Ubuntu user.

```
multipass shell
```

You can also access via SSH using the IP addressed assigned.

The YAML file is dev-init.yaml.

The Invenio VM
--------------

The invenio VM is the same as the dev VM except I've added imagemagick to the installed software.

```
bash make-invenio-vm.bash
```

Like previous example access with the `multipass` shell command.

```
multipass shell
```


