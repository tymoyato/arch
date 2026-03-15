#!/bin/bash

password="$1"

# Initialize and update the keyring
pacman-key --init
pacman-key --populate archlinux
pacman -Sy archlinux-keyring

# Download the config and creds
curl -H 'Cache-Control: no-cache' -O https://raw.githubusercontent.com/tymoyato/pim/main/user_configuration.json
curl -H 'Cache-Control: no-cache' -O https://raw.githubusercontent.com/tymoyato/pim/main/user_credentials.json

# Run archinstall with passed password
archinstall --config user_configuration.json --creds user_credentials.json --creds-decryption-key "$password"
