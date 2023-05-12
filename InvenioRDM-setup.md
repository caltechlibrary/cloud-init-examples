Invenio RDM Setup
=================

This is a recipe for getting a development version of InvenioRDM running inside a multipass VM 

Pre-requisites
--------------

You need the following installed to follow along with these instructions. It assumes you're running macOS though it should work for Windows too.

1. Install [multipass](https://multipass.run "Multipass website has a link tand instruction to install it based on host operating system, macOS -- Windows or Linux")
2. Git client so you can download our cloud init examples repository assumeed by these instructions

If you're already running Linux (e.g. Ubuntu 20.04 LTS), you can install multipass using [snap](https://snapscraft.io "The snaps website"). 

Optional: If you want to access the web browser inside your VM, install a remote desktop viewer. Microsoft Remote Desktop works for both Windows and macOS machines. On macOS install it from the app store. You can then use a remote desktop view that support xrdp protocol such as the [Remmina](https://remmina.org/ "Remote access screen and file sharing to your desktop website") package via `sudo apt install remmina` or `sudo snap install remmina`.


VM Setup Recipe
---------------

Here are a summary of the steps. The full commands can be found below.
1. Clone the cloud-init-examples repository
2. change to that directory
3. Use `start-vm.bash invenio-rdm xlarge focal` to create the VM and start it the first time
4. Add a password for the user you're going to log in with, e.g. ubuntu user
5. Install `nvm`, the node version manager
6. Before you reboot, make sure xrdp and ubuntu-desktop are installed and updated
7. Reboot the VM just to make sure everything is working correctly
8. Use `multipass info invenio-rdm` to find the IP address and running state of the VM before proceeding to the next section

On your host machine where you've installed [multipass](https://multipass.run "Multipass website") you can issue the following commands.

```shell
    git clone git@github.com:caltechlibrary/cloud-init-examples
    cd cloud-init-examples
    ./start-vm.bash invenio-rdm xlarge
    multipass shell invenio-rdm
    sudo passwd ubuntu
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    sudo apt update
    sudo apt dist-upgrade
    sudo apt autoremove
    sudo apt autoclean
    sudo reboot
    multipass info invenio-rdm
```

Before we go forward Ubuntu gets updates. It's a good idea to also update your VM's Ubuntu even when running a LTS.

NOTE: When you reboot the VM you'll be dumpted out at your host system's shell. Wait a minute or then use Use the last command `multipass info invenio-rdm` to get the reboot status and to show the IP addresses we need to connect to the VM.


InvenioRDM Configuration
-------------------------------

Now we can connect to our vm in our terminal window 

```shell
    multipass shell invenio-rdm
```

If you're going to do development InvenioRDM needs NodeJS 14.0.0 to build properly.  We need to install NodeJS
using `nvm` to meet that requirement.


```shell
    nvm install 14
```

Now we can follow the instructions based on https://inveniordm.docs.cern.ch/install/build-setup-run/.

```
    invenio-cli init rdm -c v9.1
```

I answered the questions as follows

- project_name: demo
- project_shortname: demo
- project_site: demo.local
- github_repo: rsdoiel/invenio-demo
- desciption: Demo InvenioRDM Instance
- author_name: Caltech Library
- author_email: rsdoiel@caltech.edu
- year: 2022
- then accepted all the defaults.

In the terminal run the following commands

```shell
    cd demo
    invenio-cli install
    invenio-cli services setup
```

Now edit the 'invenio.cfg' file to add your VM IP address. In this example mine was 192.168.64.8; please change this to the IP for your VM. You can
get the IP address of the VM from running `multipass info invenio` on
your host machine.

```
APP_ALLOWED_HOSTS = ['0.0.0.0', 'localhost', '127.0.0.1', '192.168.64.8']

SITE_UI_URL = "https://192.168.64.8"

SITE_API_URL = "https://192.168.64.8/api"
```

Now we can run the application

```shell
    invenio-cli run --host 192.168.64.8
```

NOTE: The first to you use `invenio-cli run` it will install system vocabularies, this takes a few minutes. You can press ctl-C once the process once log messages stop appearing. 

NOTE: Invenio runs on port 5000 by default, the URL would look like https://192.168.64.8:5000 for our example.


You can now open firefox and go to your VM's IP address port 5000 to see your Invenio instance. Other browsers may work, but have more annoying warnings about the self-signed SSL certificate that is used. Chrome will just fail unless you get Let's Encrypt and cerbot working.

Sometimes you need to tear down and start over an development InvenioRDM instance. These need to be run from the directory where you installed the Invenio demo.

```shell
    invenio-cli services stop
    invenio-cli services destroy
    invenio-cli destroy
```


