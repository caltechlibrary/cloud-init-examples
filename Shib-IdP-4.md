Shibboleth IdP 4
================

This is a recipe for setting a local Shibboleth IdP 4 (IdP stands for identity provider). The recipe use case is setting up an IdP for testing web applications that integrate Shibboleth SP (SP stands for "Service Provider", e.g. the application you're going to write that uses single sign-on via Shibboleth) . It uses
Shibboleth IdP version 4, OpenJDK 11, Tomcat and Apache2. 

The Official Shibboleth IdP 4 documentation is at
https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview.

This document summarizes the installation process for running under Ubuntu 20.04 LTS using standard Ubuntu packages (e.g. Apache2, Jetty9, OpenJDK 11) where appropriate. This hopely will ease running an IdP service under cloud-init and Multipass.


Requirements
------------

- Tomcat 9 (e.g. Ubuntu 20.04 LTS, tomcat9)
- OpenJDK 11   (e.g. Ubuntu 20.04 LTS, default-jdk)
- The latest identity provider from linked on https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview

Creating our VM
---------------

Since we're running a development instance I've made assumptions about
the prefer for limited resources and have chosen a "small" VM.

```shell
    ./start-vm shib-idp small
```

You can access the VM as with

```shell
    ./multipass shell shib-idp
```

Additional prep
---------------

I recommend doing the following to easy setup later. We're going
to give our multipass instance a name, "idp.example.edu". To do
that we need to update the "hostname" and `/etc/hosts` files.
From your multipass shell you can do the following. I happen
to use the editor "vi" but you can use whatever is your favorite
editor (e.g. emacs, nano)

```shell
    sudo hostnamectl set-hostname idp.example.edu
    sudo vi /etc/hosts
```

In the last command you need to add the hostname for idp.example.edu.
In my case the IP address was 192.168.64.154 and I added the following
lines

```
# Setup local idp.example.edu name
192.168.64.154 idp.example.edu
```

On your host machine you can run `multipass info shib-ipd` to get
your IP address.

Make sure JAVA_HOME is set in `/etc/environment`. You can find out
the JAVA_HOME value needed with

```shell
jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));'
```

On the VM I create that script returned `/usr/lib/jvm/java-11-openjdk-arm64`. I added the following line after the PATH setting in `/etc/environment`.

```
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-arm64"
```



At this point we should be ready to install the Shibboleth IdP 4
service following the Shibboleth IdP 4 documentation and installation
scripts.


Installing the Shibboleth IdP 4 software
----------------------------------------

While cloud init goes a long way to setting things up there are
things I still need to do by hand. 

1. Download the latest shibboleth-identity-provider zip files
2. Unpack and verify them
3. Run the `install.sh` script to install the idp
4. Deploy the war file so it is available to Jetty (the servlet engine)
5. Proceed to configure shibboleth idp service

```
    multipass shell shib-idp
    
    curl -L -O https://shibboleth.net/downloads/identity-provider/latest4/shibboleth-identity-provider-4.2.1.zip
    
    unzip shibboleth-identity-provider-4.2.1.zip
    cd shibboleth-identity-provider-4.2.1
    sudo ./bin/bash install.sh \
       -Didp.host.name=$(hostname -f) \
       -Didp.keysize=3072
```

The installer will ask for some base level configuration. You can
accept the defaults but you will need to provide a "hostname" which
can be the IP address of the VM. You get the IP address of the VM
you can run `multipass info shib-idp` on the host machine.

You will also be asked for a "Back channel Password", you need to come up with something appropriate (i.e. not something simple an guessable, use a password generator). You will also be asked to create a "Cookie Encrypt Password", same advice as the "Back channel Password".

The installer conversation looks something like (Note the comments "###" where it asks for passwords)

```
Buildfile: /home/ubuntu/shibboleth-identity-provider-4.2.1/bin/build.xml

install:
Source (Distribution) Directory (press <enter> to accept default): [/home/ubuntu/shibboleth-identity-provider-4.2.1] ? 

Installation Directory: [/opt/shibboleth-idp] ? 

New Install.  Version: 4.2.1
Creating idp-signing, CN = idp.example.edu URI = https://idp.example.edu/idp/shibboleth, keySize=3072
Creating idp-encryption, CN = idp.example.edu URI = https://idp.example.edu/idp/shibboleth, keySize=3072
Backchannel PKCS12 Password:     ###_PASSWORD_FOR_BACK_CHANNEL_###
Re-enter password:               ###_PASSWORD_FOR_BACK_CHANNEL_###
Creating backchannel keystore, CN = idp.example.edu URI = https://idp.example.edu/idp/shibboleth, keySize=3072
Cookie Encryption Key Password:  ###_PASSWORD_FOR_COOKIE_ENCRYPTION_###
Re-enter password:               ###_PASSWORD_FOR_COOKIE_ENCRYPTION_###
Creating backchannel keystore, CN = idp.example.edu URI = https://idp.example.edu/idp/shibboleth, keySize=3072
INFO  - No existing versioning property, initializing...
SAML EntityID: [https://idp.example.edu/idp/shibboleth] ? 

Attribute Scope: [example.edu] ? 

INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/admin/admin.properties
INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/services.properties
INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/saml-nameid.properties
INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/authn/authn.properties
INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/c14n/subject-c14n.properties
INFO  - Including auto-located properties in /opt/shibboleth-idp/conf/ldap.properties
Creating Metadata to /opt/shibboleth-idp/metadata/idp-metadata.xml
Rebuilding /opt/shibboleth-idp/war/idp.war, Version 4.2.1
Initial populate from /opt/shibboleth-idp/dist/webapp to /opt/shibboleth-idp/webpapp.tmp
Overlay from /opt/shibboleth-idp/edit-webapp to /opt/shibboleth-idp/webpapp.tmp
Creating war file /opt/shibboleth-idp/war/idp.war

BUILD SUCCESSFUL
Total time: 36 seconds
```

When the installer has completed it will have created a "war" file.
In my case it installed it in `/opt/shibboleth-idp/war/idp.war`.

Now we need to update the ownership of some of the directories so
`jetty` user can manage them.

```shell
   cd /opt/shibboleth-idp && sudo chown -R jetty logs/ metadata/ credentials/ conf/ war/
```

Getting Jetty to know about IdP
---------------------------------

We need to tell Jetty9 where to find the Shibboleth IdP 4 service. We 
do this by creating a `idp.xml` file in `/usr/share/jetty9/webapps/`.
The command I used to do this is `sudo vi /usr/share/jetty9/webapps/idp.xml` and adding the following content before saving the file.

```xml
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
  <Set name="war"><SystemProperty name="idp.home"/>/opt/shibboleth-idp/war/idp.war</Set>
  <Set name="contextPath">/idp</Set>
  <Set name="extractWAR">false</Set>
  <Set name="copyWebDir">false</Set>
  <Set name="copyWebInf">true</Set>
  <Set name="persistTempDirectory">false</Set>
</Configure>
```

We should not restart the Jeyy9 service.

```shell
    sudo systemctl restart jetty9
```

Configuring Apache 2
--------------------

We use Apache2 to "reverse proxy" to our Jetty service.  That
takes some additional setup.  Let's create some content
to know when things are finally working.

```
    sudo su
    mkdir -p /var/www/html/idp.example.edu
    echo 'It Works!' > /var/www/html/idp.example.edu/index.html
    exit
```

You'll need your Apache 2 setup support SSL as well as reverse proxy.
On Ubuntu the certificates should go in `/etc/ssl/certs` for the
public key certific and `/etc/ssl/private` for the private key. You
can use ACME certs (Let's Encrypt) if you like. The main thing
is you need to know the full paths to the parts as we need that
for our virtual host definition we complete later.

Update your Apache 2 to enable these the following modules

- proxy_http
- ssl
- headers
- alias
- include
- negotation

```shell
    sudo a2enmod proxy_http ssl headers alias include negotiation
```

Disable the default sites.

```
    sudo a2dissite 000-default.conf default-ssl.conf
```

Next we want to add our Virtual Host for functioning as a 
reverse proxy to the IdP service.

NOTE: the following was based on the virtual host file found at https://registry.idem.garr.it/idem-conf/shibboleth/IDP4/apache2/idp.example.org.conf.

You can find my example `idp.example.edu.conf` file in the https://github.com/caltechlibrary/cloud-init-examples repository under `etc/apache2/sites-available/idp.example.edu.conf`. It uses the default
"snake oil" SSL certs for the machine. You'll probably want to 
improve on that.

You can get a copy locally using cURL.

```shell
    cd $HOME
    curl -L -o idp.example.edu.conf \
       https://registry.idem.garr.it/idem-conf/shibboleth/IDP4/apache2/idp.example.org.conf
```

Edit this file in your favorite editor. Make sure apply your
hostname (e.g. I used idp.example.edu not idp.example.org so I did
a find and replace on that). I also changed the `ServerAdmin` values
to match what I wanted. Also VERY IMPORTANT you will need to change
the path to the SSL setup to 

Once you get the virtual host file the way you want you can copy
that to `/etc/apache2/site-available` and then use the Apache 2
`a2ensite` command to enable it before restarting Apache 2.

```shell
    cd $HOME
    vi idp.example.edu.conf
    sudo cp idp.example.edu.conf /etc/apache2/sites-available/
    sudo a2ensite idp.example.edu.conf
    sudo systemctl restart apache2
```

You should now have Apache 2 configure to talk to our IdP.


Checking our configuration
--------------------------

The script `./bin/status.sh` can be used to check if the install was
successful. On my intial try it was not.

```shell
    cd /opt/shibboleth-idp/
    ./bin/status.sh
```

This reported 

```
(http://localhost/idp/status) http://localhost/idp/status
```

We can use `lynx` to see the status at the URLs provided.

```
    lynx http://localhost/idp/status
```

So it looks like things are setup and our Shibboleth IdP is now running.

If you get errors. The Shibboleth documentation is less than helpful.
I found this tutorial helpful, https://github.com/ConsortiumGARR/idem-tutorials/blob/master/idem-fedops/HOWTO-Shibboleth/Identity%20Provider/Debian-Ubuntu/HOWTO%20Install%20and%20Configure%20a%20Shibboleth%20IdP%20v4.x%20on%20Debian-Ubuntu%20Linux%20with%20Apache2%20%2B%20Jetty9.md as well as this page https://cloudinfrastructureservices.co.uk/install-shibboleth-sso-on-ubuntu-20-04/

Note unlike the GitHub example I didn't compile anything. I used the stock Ubuntu 20.04 LTS apache2, Jetty9, default-jdk except the downloaded Shibboleth-IdP-4 which I compiled using its installer script. All my challenges was getting the JAVA / Jetty environment correct. That took me a while to sort out, hopefully you get up and running quickly.

Unfornately we're not done quite yet.

Wrapping things up
------------------

On my host system I should now be able to use the multipass VM as my IdP. To do that