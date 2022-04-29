cloud-init-examples
===================

This repository includes some example of cloud-init YAML files for use with [multipass](https://multipass.run "Multipass website") in creating some virtual machines.

Examples
--------

This repositories includes the follow example virtual machines 
setup and configurations.

make-minimal-vm.bash, minimal-init.yaml
: This is a minimal cloud init YAML just a demo of a configuration

make-dev-vm.bash, dev-init.yaml
: This is a server like development environment for Golang 1.18

make-invenio-vm.bash
: This is a server like development environment for Invenio-RDM

The next set provide the ability to run as a full GUI environment on macOS or Windows using the Microsoft Remote Desktop viewer or Remmina on Linux. The are based on the previous terminal oriented VMs but add the "ubuntu-desktop" and "xrdp" package to handle the remote displays.  For you to use the GUI versions your VM accounts need to have a password associated with them. You can use the `multipass shell` command to get a shell and then use `sudo passwd USERNAME` to set the password for "USERNAME" (e.g. ubuntu, rsdoiel).

On a M1 Mac running under Monterey you can then use a web browser from the remote displayed VM to test services inside the VM without exposing it to your host machine.

make-dev-gui-vm.bash, dev-gui-init.yaml
: A development GUI environment for Golang 1.18, uses 4 cores and 8G of RAM

make-invenio-gui-vm.bash, invenio-gui-init.yaml
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

Set a VM as primary (e.g. a machine named "dev") so you don't
have to provide a name with each command. If you want to access 
a non-primary VM then give it a name and pass the name in the command.

```shell
    multipass set client.primary-name=dev
```

Access the primary VM

```shell
    multipass shell
```

Access the "dev" VM

```shell
    multipass shell dev
```

Stop/Start the primary VM 

```shell
    multipass stop
    multipass start
```

Stop/Start the "dev" VM

```shell
    multipass stop dev
    multipass start dev
```

Stop all the VM, delete them and purge them from disk.

```shell
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

```shell
    bash make-dev-vm.bash
```

Access VM as Ubuntu user.

```shell
    multipass shell
```

You can also access via SSH using the IP addressed assigned.

The YAML file is dev-init.yaml.

The InvenioRDM VM
--------------

The InvenioRDM VM is similar to the dev VM except it doesn't install as many packages and it adds imagemagick and installs nodejs 14.0.0 so the virtual machine is ready for use in a developer setting.

```shell
    bash make-invenio-vm.bash
```

Like previous example access with the `multipass` shell command.

```shell
    multipass shell
```

A more complete exploration of running InvenioRDM is found in the [InvenioRDM-Setup](InvenioRDM-Setup.html)

Trouble shooting
----------------

I've run into some challenges on the M1 Mac as well as when using Cisco's VPN. Here's some helpful links to explore.

- [Trouble shooting networking errors on macOS](https://multipass.run/docs/troubleshooting-networking-on-macos)

