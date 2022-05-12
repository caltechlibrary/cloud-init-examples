cloud-init-examples
===================

This repository includes some example of cloud-init YAML files for use with [multipass](https://multipass.run "Multipass website") in creating some virtual machines.

Examples
--------

This repositories includes the follow example virtual machines 
setup and configurations.

start-minimal-vm.bash, minimal-init.yaml
: This is a minimal cloud init YAML just a demo of a configuration, it includes the Debian build-essentials package

start-dev-server-vm.bash, dev-server-init.yaml
: This is a server like development environment for Golang 1.18

start-invenio-server-vm.bash, invenio-server-init.yaml
: This is a server like development environment for Invenio-RDM

The next set provide the ability to run as a full GUI environment on macOS or Windows using the Microsoft Remote Desktop viewer or Remmina on Linux. The are based on the previous terminal oriented VMs but add the "ubuntu-desktop" and "xrdp" package to handle the remote displays.  For you to use the GUI versions your VM accounts need to have a password associated with them. You can use the `multipass shell` command to get a shell and then use `sudo passwd USERNAME` to set the password for "USERNAME" (e.g. ubuntu, rsdoiel).

If you would like to have a Ubuntu Desktop available for use in your multipass VM Ihave provided several examples.
start-dev-gui-vm.bash, dev-gui-init.yaml
: A development GUI environment for Golang 1.18, uses 4 cores and 8G of RAM

start-invenio-gui-vm.bash, invenio-gui-init.yaml
: A development GUI environment for Invenio-RDM, uses 4 cores and 8G of RAM


Multipass
---------

[Mulitpass](https://multipass.run "Multipass website") is a tool for running and managing Ubuntu VMs. It is lighter weight then running VirtualBox, works across operating systems (e.g. Windows, macOS, Linux) and processor types (e.g. Intel an ARM). This means you can easily run VMs on Raspberry Pi or your favor macOS or Windows machine.  The VM will match your host CPU architecture (i.e. you're not running full emulation but using running as a Intel box on an Intel host or a ARM box on a Raspberry Pi or M1 Mac).  VM's can be easily create, started, stopped and destroy.  The setup script is YAML rather than Ruby like with vagrant. There are a small number of commands to learn (i.e. `multipass --help` covers them all). Multipass is NOT as featureful as VirtualBox or Parallels but it does seem to be much lighter weight and the things you can adjust (e.g. RAM, CPU cores) are the ones you likely want to adjust anyway. It is focused on easily bringing up a server like environment for testing and development.

Common multipass commands
-------------------------

Get a list of VMs available 

```shell
    multipass list
```

Set a VM as primary (e.g. a machine named "dev-server") so you don't
have to provide a name with each command. If you want to access 
a non-primary VM then give it a name and pass the name in the command.

```shell
    multipass set client.primary-name=dev-server
```

Access the primary VM

```shell
    multipass shell
```

Access the "dev-server" VM

```shell
    multipass shell dev-server
```

Stop/Start the primary VM 

```shell
    multipass stop
    multipass start
```

Stop/Start the "dev-server" VM

```shell
    multipass stop dev-server
    multipass start dev-server
```

Stop all the VM, delete them and purge them from disk.

```shell
    multipass stop --all
    multipass delete --all
    multipass purge
```

Move a file (e.g. staff-favorites.absh) to the "dev-server" VM

```
   multipass transfer staff-favorites.bash dev-server:.
```

Cloud Init Files
----------------

[Cloud Init](https://cloud-init.io) is a specification for bringing up a virtual machine (or container) using a YAML syntax. It can be relatively simple (see the minimal example) to elaborate (the dev example). You can specify things like users, packages to be installed, host files to be mounted or even shell scripts to run.

Minimal Py
----------

The `start-minimal-py-vm.bash` scripts creates a minimal python development box described in minimal-py-init.yaml. It doens't create users or install more than python3 and pip.

The Dev VM
----------

This will create a VM named "dev-server". It includes a more complete server development environment including support for Go version 1.18.x.  It includes examples of installing packages via apt and snaps.

```shell
    bash start-dev-server-vm.bash
```

Access VM as Ubuntu user.

```shell
    multipass shell
```

You can also access via SSH using the IP addressed assigned.

The YAML file is dev-server-init.yaml.

The InvenioRDM VM
-----------------

The InvenioRDM VM is similar to the dev VM except it doesn't install as many packages and it adds imagemagick and installs nodejs 14.0.0 so the virtual machine is ready for use in a developer setting.

```shell
    bash start-invenio-server-vm.bash
```

Like previous example access with the `multipass` shell command.

```shell
    multipass shell
```

A more complete exploration of running InvenioRDM is found in the [InvenioRDM-Setup](InvenioRDM-Setup.html)

General purpose Bash scripts
----------------------------

I have provided three Bash scripts for starting/launching, getting info and stopping your multipass VM.

1. start-vm.bash - starts an existing or launches a new virtual machine based on a related cloud init YAML file
2. stats-vm.bash - will return information about the machine (i.e. it runs `multipass info $MACHINE`)
3. stop-vm-.bash - will stop the machine

If you've devined a primary name for the machine the Bash scripts can be used without any additoinal parameters. If
you provide a machine name as a parameter then the scripts will work with that machine name.

For creating new machines (aka multipass launch) the start-vm.bash script looks for a cloud init YAML file that
defines the new machine. By default it first looks for the name `$MACHINE-local.yaml` and if that is not available
it looks for `$MACHINE-init.yaml`.   The `*-init.yaml` files provided in this repository are a good starting point but
the cloud init support in multipass goes much further.  The YAML file called `dev-server-local.yaml` is provided as an
example of including full login setup for the developers in the DLD group of Caltech Library. This includes setting them
up with sudo access, assigning them to additoinal groups and enabling login via SSH keys hosted on GitHub.  By using the
filename convension of `*-init.yaml` I can provide a general purpose machine definition while allowing for local modification
via a version of the same file matching `*-local.yaml`.


Trouble shooting
----------------

I've run into some challenges on the M1 Mac as well as when using Cisco's VPN. Here's some helpful links to explore.

- [Trouble shooting networking errors on macOS](https://multipass.run/docs/troubleshooting-networking-on-macos)

