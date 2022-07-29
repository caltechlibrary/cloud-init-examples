Shibboleth IdP Test
===================

This is a recipe for setting a local Shibboleth IdP for testing
web applications intending to support Shibboleth SSO. It uses
Shibboleth IdP version 4, OpenJDK 11, Tomcat and Apache2. 

Documentation is found at
https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview.
This document is a summary of the installation instructions adapted
to run under cloud-init and Multipass. The idea is you would run
a local IdP to test against in one VM and then develop your application
in another that uses the test IdP instance.


Requirements
------------

- Tomcat 9 (e.g. Ubuntu 20.04 LTS, tomcat9)
- OpenJDK 11   (e.g. Ubuntu 20.04 LTS, default-jdk)
- The latest identity provider from https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview

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

Additional prep in your VM
---------------------------

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
    sudo ./bin/install.sh -Didp.keysize=2048
```

The installer will ask for some base level configuration. You can
accept the defaults but you will need to provide a "hostname" which
can be the IP address of the VM. You get the IP address of the VM
you can run `multipass info shib-idp` on the host machine.

You will also be asked for a "Back channel Password", you need to come
up with something appropriate (i.e. not something simple an guessable,
use a password generator)

You will also be asked to create a "Cookie Encrypt Password", same
advice as the "Back channel Password".

The SAML Entity ID I just accepted the default which used the IP
address I had use for the "hostname". I also accepted the default
scope.

When the installer has completed it will have created a "war" file.
In my case it installed it in `/opt/shibboleth-idp/war/idp.war`.

Getting Jetty to know about IdP
---------------------------------

Jetty is the recommended servelet engine. I mostly have experience with Tomcat. The documentation for Shibboleth stops at actually getting it running under Jetty. I found an article in Turkish about how to do it but I don't read Turkish (though the list of commands was extremely helpful compared to the Official Shibboleth IdP documentation). 


FIXME: Need to figure out how to get the Jetty9 Ubuntu install to see the Shibboleth package/war file installed in `/opt/shibboleth-idp`. After then the Shibboleth documentation about should make sense.


Checking the configuration
--------------------------

The script `./bin/status.sh` can be used to check if the install was
successful. On my intial try it was not.

```
    sudo ./bin/status.sh
```


