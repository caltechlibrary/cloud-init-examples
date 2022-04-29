Invenio RDM setup
=================

This is a recipe for getting a development version of Invenio-RDM running inside a multipass VM with a GUI environment (using Microsoft Remote Desktop) so that you can check out the local development with a web browser (e.g. Firefox) without going outside of the VM.

NOTE: On macOS on a M1 processor the InvenioRDM package may not install properly. YMMV

Pre-requisites
--------------

You need the following installed to follow along with these instructions. It assumes you're running macOS though it should work for Windows too.

1. Install [multipass](https://multipass.run "Multipass website has a link tand instruction to install it based on host operating system, macOS -- Windows or Linux")
2. Install a remote desktop viewer, e.g. Microsoft Remote Desktop works for both Windows and macOS machines. On macOS install it from the app store.
3. Git client so you can download our cloud init examples repository assumeed by these instructions

If you're already running Linux (e.g. Ubuntu 20.04 LTS), you can install multipass using [snap](https://snapscraft.io "The snaps website"). You can then use a remote desktop view that support xrdp protocol such as the [Remmina](https://remmina.org/ "Remote access screen and file sharing to your desktop website") package via `sudo apt install remmina` or `sudo snap install remmina`.


VM Setup Recipe
---------------

1. Clone the cloud-init-examples repository
2. change to that directory
3. Use `make-invenio-gui-vm.bash` to create the VM and start it the first time
4. Add a password for the user you're going to log in with, e.g. ubuntu user
5. Before you reboot, make sure xrdp and ubuntu-desktop are installed and updated
6. Reboot the VM just to make sure everything is working correctly
7. Use `multipass info invenio-gui` to find the IP address and running state of the VM before proceeding to the next section

On your host machine where you've installed [multipass](https://multipass.run "Multipass website") you can issuing the following commands.

```shell
git clone git@github.com:caltechlibrary/cloud-init-examples
cd cloud-init-examples
./make-invenio-gui-vm.bash
multipass shell invenio-gui
sudo passwd ubuntu
sudo apt update
sudo apit dist-upgrade
sudo apt install ubuntu-desktop
sudo apt install xrdp
sudo apt autoremove && sudo apt autoclean
sudo reboot
multipass info invenio-gui
```

Before we go forward Ubuntu gets updates. It's a good idea to also update your VM's Ubuntu even when running a LTS.

NOTE: When you reboot the VM you'll be dumpted out at your host system's shell. Wait a minute or then use Use the last command `multipass info invenio-gui` to get the reboot status and to show the IP addresses we need to connect to the VM with Microsoft Remote Desktop.

Microsoft Remote Desktop Recipe
-------------------------------

We're now ready to work with the GUI via Microsoft Remote Desktop (or other rdp remote desktop viewer). Lauch the Microsoft Remote Desktop application.

![Image of Microsoft Remote Desktop on macOS](images/ms-remote-desktop-01.png)

Click the "+", then click "Add PC". A modal dialog will appear to define the connection.

![Image of the connection setup, general setup](images/ms-remote-desktop-02.png)

 Under "PC Name" enter the IP address you discovered from runing `multipass info invenio-gui` previously. In my case the IP address assigned was `192.168.64.67` yours will be different.  Leave the "Use account" set to "Ask when required". Below that is a set of buttons for a tabbed style dialog.
 Current the "General" butten is active. Click the "display" button.

 ![Image of the connection setup, display controls](images/ms-remote-desktop-03.png)

 I set my resolution to 1024x768 and uncheck the "Start session full screen" checkbox.

 ![Image of the connection setup, display controls edited](images/ms-remote-desktop-04.png)

This should leave you with a new connection, named for the IP address.

![Image of Microsoft Remote Desktop on macOS, after setting up the connection](images/ms-remote-desktop-05.png)

You can now open your new connection to the desktop. The first time you open it you'll have a dialog to finish setting up the desktop in the VM. Click through those as needed (I usually just accept the defaults and skip things like allowing location).

![Image of Ubuntu desktop setup, step 1](images/ms-remote-desktop-06.png)

![Image of Ubuntu desktop setup, step 2](images/ms-remote-desktop-07.png)

![Image of Ubuntu desktop setup, step 3](images/ms-remote-desktop-08.png)

![Image of Ubuntu desktop setup, step 3](images/ms-remote-desktop-09.png)

Sometimes you might need to update the VM further (new releases have happened), if you so may see a display like this. If so restart the VM by clicking the restart button.

![Image of Ubuntu desktop, step 4](images/ms-remote-desktop-10.png)

Next you need to start up a "Terminal" so we can install a local development of Invenio. To do that click on the "Activities" menu in the top left of the screen.

![Image of Ubuntu desktop, step 4](images/ms-remote-desktop-11.png)

In the upper left corner of the VM's GUI Window you should see "Activities" 

![Image of Ubuntu desktop, no apps running yet](images/ms-remote-desktop-12.png)

This will make the "dock" appear on the left side of the window. 

![Image of Ubuntu desktop, no apps running yet](images/ms-remote-desktop-13.png)

You can also type in the name of the application you want to start (e.g. Terminal).  In the search bubble visible in the middle of the menu bar at the top of the window. 

![Image of Ubuntu desktop, no apps running yet](images/ms-remote-desktop-14.png)

 
 You will need to use the "Terminal" application to follow along with the steps to create your Invenio-RDM instance.

![Image of Ubuntu desktop, with terminal running](images/ms-remote-desktop-15.png)


Generating an Invenio-RDM instance
----------------------------------

In the terminal window you can following instructions are based on https://inveniordm.docs.cern.ch/install/build-setup-run/.

Below is an example of checking if all the requirements for an Invenio Development instance if are available.

![Image of Ubuntu Desktop with Terminal running](images/ms-remote-desktop-16.png)

In the terminal I run the following to bring up a basic development instance.

```
invenio-cli init rdm -c v8.0
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

![Image of Ubuntu Desktop and Terminal running, part 1](images/ms-remote-desktop-17.png)

![Image of Ubuntu Desktop and Terminal running, part 2](images/ms-remote-desktop-18.png)


In the terminal run the following commands

```shell
cd demo
invenio-cli install
invenio-cli services setup
invenio-cli run
```

Sometimes you need to tare down and start over an development InvenioRDM instance.

```shell
invenio-cli services stop
invenio-cli services destroy
invenio-cli destroy
```


