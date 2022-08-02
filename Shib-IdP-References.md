
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

