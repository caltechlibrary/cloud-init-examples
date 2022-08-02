
This is a collection of links that may be helpful if you're setting up a Shibboleth IdP 4 service.

- https://shibboleth.atlassian.net/wiki/spaces/IDP4/overview
- https://github.com/ConsortiumGARR/idem-tutorials/blob/master/idem-fedops/HOWTO-Shibboleth/Identity%20Provider/Debian-Ubuntu/HOWTO%20Install%20and%20Configure%20a%20Shibboleth%20IdP%20v4.x%20on%20Debian-Ubuntu%20Linux%20with%20Apache2%20%2B%20Jetty9.md
    - this one was actually pretty useful in figuring things out but it did not conform to the path of using stock Ubuntu 20.04 LTS packages as much as possible
- https://cloudinfrastructureservices.co.uk/install-shibboleth-sso-on-ubuntu-20-04/
    - useful overview, particularly the opening diagram
    - focus is on Tomcat not Jetty (which is recommended)
- https://registry.idem.garr.it/idem-conf/shibboleth/IDP4/apache2/idp.example.org.conf
    - Starting point of figuring out what should be in our site configuration for our Apache 2 idp.example.edu virtual host file
- https://www.baeldung.com/deploy-to-jetty
    - General description of deploying to Jetty
- Documentation for Shibboleth IdP 3 that setup
    - https://www.switch.ch/aai/guides/idp/installation/
        - uses Postgres to manage the accounts
- Example Shibboleth SP setups
    - [harvard](https://iam.harvard.edu/resources/saml-shibboleth-integration)
    - [USC](https://shibboleth.usc.edu/docs/sp/install/)

# Configuring our IdP

- https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631611/PasswordAuthnConfiguration
- https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1274544392/HTPasswdAuthnConfiguration
    - this documents using an Apache htpasswd type file




## cut text, save if I need later

-------- START CUT --------------------
The is hinted at in two places of the Shibboleth confluence documentation site: [PasswordAuthentication](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631611/PasswordAuthnConfiguration) and [HTPasswdAuthnConfiguration](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1274544392/HTPasswdAuthnConfiguration). The later actually shows an example of what needs to change in the "bean" element so the Java class and use the htpasswd file. Unfortunetly that is about all it shows. In the former page there is a mention of a `modules.sh` program to enable modules like Password base authentication. Fortunately that does respond to the `--help`. Based on that I know their example is first tests if the module is already enabled and stops or proceeds to enable it (we'll also going to enable the "Hello World" flow to support testing).


```shell
    sudo su
    cd /opt/shibboleth-idp
    ./bin/module.sh -t idp.authn.Password
    ./bin/module.sh -e idp.authn.Password
```

In comment the `<bean parent="shibboleth.HTPasswdValidator" p:resource="%{idp.home}/credentials/demo.htpasswd" />` and save the file.

```shell
    vi conf/authn/password-authn-config.xml
```

You can create our `demo.htpasswd` file in `credentials/demo.htpasswd`
using Apache `htpasswd` program. That file needs to be owned by `jetty.adm`. 

```
   htpasswd -c credentials/demo.htpasswd testuser
   chown jetty:adm credentials/demo.htpasswd
   chmod 660 credentials/demo.htpasswd
```

The "views" or HTML pages supplied by Shibboleth are found in the "views" directory. At this point you should see ones for `login.vm` as well as other parts of the "flow" like `logout.vm` and `login-error.vm`.

But, at least in my build the test does actually detact that is enabled. Run the command separately yields better results and ensure 0that the login view have been created.

Checking the `/idp/status` end point to make sure the IdP software is working, we can then try the 



If we see the Shibboleth IdP 4 status page we're ready to proceed to
setting up Apache 2 as a reverse proxy for our IdP.

-------- END CUT ----------------------
