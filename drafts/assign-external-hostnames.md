---
title: Setting up external hostnames
---

Setting up external hostnames
-----------------------------

There are times when it would be convient to refer to your VM with an external hostname during development.  That can be done by configuring it in the VM as well as on the host system.


VM Hostname setup
-----------------

You can setup your multipass instance to use an external host name.
This can be done in these steps. 

1. Get the IP address the VM is running under
2. Define the new IP address/name relationship in `/etc/hosts`
3. Use `hostnamectl` to update the VM's hostname

In the example blow the VM name is called `minimal-dev`.

To get the VM's IP address you can run `multipass info` command. For
the a machine called `minimal-dev` run

```shell
    multipass info minimal-dev
```

On my system it reported the IP address 192.168.64.166. I want my
VM to be visible from the host system as minimal-dev.example.edu. I now
using the `multipass shell` command to access my VM then follow
these steps. I will add a line to my `/etc/hosts` file on the VM
for minimal-dev.example.edu using the vi text editor. The added lines
should look like

```
# minimal-dev.example.edu IP mapping
192.168.64.166 minimal-dev.example.edu
```

The commands to add this are

```shell
   sudo vi /etc/hosts
   sudo hostnamectl set-hostname minimal-dev.example.edu
```

You can then check the setup with

```shell
    hostname -f
    hostname -i
```

This should report the fully qualified hostname and IP associated with it. 

Host system setup
-----------------

On your host Unix-like system you can usually modify the `/etc/hosts`
to include the same lines added in the VM's `/etc/hosts` file.

If all's gone well you should be to run the following command successfully
(my example the hostname is called `minimal-dev.example.edu`)

```shell
    host minimal-dev.example.edu
```


