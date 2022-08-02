Shibboleth IdP 4
================

This is a recipe for setting a local Shibboleth IdP 4 (IdP stands for identity provider). The recipe use case is setting up an IdP for testing web applications that integrate Shibboleth SP (SP stands for "Service Provider", e.g. the application you're going to write that uses single sign-on via Shibboleth) . It uses
Shibboleth IdP version 4, OpenJDK 11, Jetty9 and Apache2. 

The Official Shibboleth IdP 4 documentation is at
[https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview](https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview).

This document summarizes the installation process for running under Ubuntu 20.04 LTS using standard Ubuntu packages (e.g. Apache2, Jetty9, OpenJDK 11) where appropriate. This hopely will ease running an IdP service under cloud-init and Multipass.


Requirements
------------

- Jetty 9 (e.g. Ubuntu 20.04 LTS, tomcat9)
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
    multipass shell shib-idp
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
192.168.64.154 idp.example.edu idp
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

You should logout and back in to pickup the JAVA_HOME environment
variable.

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

(from your multipass shell)

```
    cd $HOME
    curl -L -O https://shibboleth.net/downloads/identity-provider/latest4/shibboleth-identity-provider-4.2.1.zip
    
    unzip shibboleth-identity-provider-4.2.1.zip
    cd shibboleth-identity-provider-4.2.1
    sudo ./bin/install.sh \
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

Getting Jetty to know about IdP
---------------------------------

Since we've install Shibboleth IdP 4 `/opt/shibboleth-idp` we need
to provide a "context XML file" to tell Jetty where to find it.

For Jetty a context file lets us leave the WAR file in our Shibboleth-ipd directory and just point at it. The context file must
match the name as the WAR file, i.e. `idp.xml` for a war file called `idp.war`. Use the command below to create our `idp.xml` in the 
`/var/lib/jetty9/webapps` directory.

```shell
    sudo bash -c 'cat <<EOF > /var/lib/jetty9/webapps/idp.xml 
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
  <Set name="contextPath">/idp</Set>
  <Set name="war">/opt/shibboleth-idp/war/idp.war</Set>
  <Set name="extractWAR">false</Set>
  <Set name="copyWebDir">false</Set>
  <Set name="copyWebInf">true</Set>
  <Set name="persistTempDirectory">false</Set>
</Configure>
EOF'
```

The context file along with the war file and several directories in
our `/opt/shibboleth-idp` need to be owned by the jetty user.

```shell
    sudo su
    cd /opt/shibboleth-idp
    chown -R jetty:adm logs metadata credentials conf war
    chown -R jetty:adm /var/lib/jetty9/webapps/idp.xml
    exit
    cd $HOME
```

Now we can restart jetty and test our setup.

```shell
   sudo systemctl restart jetty9
   sudo systemctl status jetty9
   # NOTE: You need to wait a while, Jetty is slow to restart!!
   lynx http://localhost:8080/idp/status
```

NOTE: The status end point describes the IdP setup. It indicates only
that the WAR file is installed and running in Jetty. You don't
have a working IdP yet!!


Configuring Apache 2
--------------------

We use Apache2 to "reverse proxy" to our Jetty service.  That
takes some additional setup.  Let's create some content
to know when things are finally working.

```
    sudo su
    mkdir -p /var/www/html/idp.example.edu
    echo 'It Works!' > /var/www/html/idp.example.edu/index.html
    chown -R www-data: /var/www/html/idp.example.edu
    exit
```

You'll need your Apache 2 setup support SSL as well as reverse proxy.
On Ubuntu the certificates should go in `/etc/ssl/certs` for the
public certificates (e.g. ".crt", ".pem") and `/etc/ssl/private` for the private key files (e.g. ".key").

Since your VM will likely NOT be on a public network I've included
a Bash script that will create self signed certificates using
openssl.  The script is called `setup-self-signed-SSL-certs.bash`
and can be found in either the GitHub repository under "scripts" directory at https://github.com/caltechlibrary/cloud-init-examples and
should have been "transfered" into your VM's home directory if you created the VM using `start-vm.bash`.

NOTE: `setup-self-signed-SSL-certs.bash` is interactive you'll need to answer the questions posed by `openssl` as it prompts.

```shell
    bash setup-self-signed-SSL-certs.bash
```


The script will create an "etc/ssl" directory tree in your home directory (e.g. /home/ubuntu). These should be copied to host machines `/etc/ssl/` directory. That can be done with

```
   sudo cp -vi etc/ssl/certs/* /etc/ssl/certs/
   sudo cp -vi etc/ssl/private/* /etc/ssl/private/
```

NOTE: The default Apache configuration described below assumes certs in matching those created by the script. If you get your certificates another way (e.g. use ACME certs) you'll need to update the configuration appropriately.

Next we need to enable some Apache modules to support using SSL.
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

Download the example from https://caltechlibrary.github.io/cloud-init-examples/etc/apache2/sites-available/idp.example.org.conf

```
    cd $HOME
    curl -L -O https://caltechlibrary.github.io/cloud-init-examples/etc/apache2/sites-available/idp.example.edu.conf
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
    sudo apache2ctl -t
    sudo systemctl restart apache2
```

You should now have Apache 2 configure to talk to our IdP.

You can check your Apache setup with

```
lynx https://localhost
lynx https://idp.example.edu
```

You should see the "It Works!" page for both URLs after accepting
the certificate (that is because the configuration is using the 
"snakeoil" certs).

Now let's see if our reverse proxy setup works.

```
lynx https://idp.example.edu/idp/status
```

If we see the Shibboeth IdP status page we're good to proceed.


Configuring our IdP
-------------------

FIXME: Need to describe actually configuring the IdP service. 

See [Shibboleth IdP References](Shib-IdP-References.html)

