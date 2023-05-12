#!/bin/bash
#

function usage() {
    APP_NAME=$(basename "$0")
    cat <<EOT
%$APP_NAME(1) user manual
%R. S. Doiel
%2022-10-10

# NAME

$APP_NAME

# SYNOPSIS

$APP_NAME USERNAME [GITHUB_USERNAME]

# DESCRIPTION

$APP_NAME sets up an admin user account per DLD group practice for
Ubuntu GNU/Linux machines. In addition to adding the user it adds
the groups we use to admin a machine, creates a README.1st file in
the home directory with instructions to change the password
and pulls ssh public keys from GitHub for the user we're creating.

The script should be run by root or with sudo.

# EXAMPLE

	sudo $APP_NAME jane.doe

This would create an admin account for jane.doe.

	sudo $APP_NAME jane.doe jdeo

This could create an account for jane.doe with the GitHub username
of jdoe.

EOT

}

#
# Main processing: generate accounts per DLD practices
#
echo "Running sanity check."
OS=$(uname)
if [ "$OS" != "Linux" ]; then
    echo "This script works goes not work on $OS, aborting"
    exit 1
fi

for CMD in makepasswd adduser; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} not found, aborting"
        exit 1
    fi
done

ADMIN_USERNAME="$1"
GITHUB_USERNAME="$2"

if [ "${ADMIN_USERNAME}" = "" ]; then
    usage
fi
if [ -d "/home/${ADMIN_USERNAME}" ]; then
    echo "It appears ${ADMIN_USERNAME} already exists"
    exit 1
fi

echo "Generating random passwords copy one)"
TMP_PASSWORD=$(makepasswd --minchars 12 --maxchars 24)
echo "Temporary password will be $TMP_PASSWORD"
echo ""
adduser "$ADMIN_USERNAME"
for GROUP in ubuntu adm sudo dip www-data video plugdev staff netdev lxd docker; do
    adduser "$ADMIN_USERNAME" "${GROUP}"
done
cat <<EOT >"/home/$ADMIN_USERNAME/README.1st"

Please reset your password.

    ${TMP_PASSWORD}

EOT
chmod 600 "/home/$ADMIN_USERNAME/README.1st"

echo "Changing directory to /home/$ADMIN_USERNAME"
cd "/home/$ADMIN_USERNAME" || exit 1
if [ ! -d "/home/$ADMIN_USERNAME/.ssh" ]; then
    mkdir "/home/$ADMIN_USERNAME/.ssh"
    chmod 700 "/home/$ADMIN_USERNAME/.ssh"
fi
cd "/home/$ADMIN_USERNAME/.ssh/" || exit 1
echo "Retrieving authorized keys from https://github.com/$ADMIN_USERNAME.keys"
if [ ! -f authorized_keys ]; then
    if [ "$GITHUB_USERNAME" = "" ]; then
        GITHUB_USERNAME="$ADMIN_USERNAME"
    fi
    if curl -o authorized_keys "https://github.com/$GITHUB_USERNAME.keys"; then

        chmod 660 authorized_keys
    else
        echo "Failed to fetch keys from https://github.com/$GITHUB_USERNAME.keys"
        exit 1
    fi
else
    echo "/home/$ADMIN_USERNAME/.ssh/authorized_keys already exist, aborting"
    exit 1
fi
# Make sure the admin users owns the files in their home directory.
chown -R "$ADMIN_USERNAME.$ADMIN_USERNAME" "/home/$ADMIN_USERNAME"
