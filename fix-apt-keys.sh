#!/usr/bin/env bash
# ----------------------------------------------------------
# Author:          damiancypcar
# Modified:        10.03.2023
# Version:         1.1
# Desc:            Fix missing APT keys
# ----------------------------------------------------------

set -euo pipefail

# shellcheck disable=SC2046
if [ $(id -u) -ne 0 ]; then
    echo "You must be ROOT to run this script"
    exit 1
fi

echo -n "Updating the package list (may take a while)... " && \
    apt-get update >/dev/null 2>/tmp/apt-get-update-errors && echo "OK"

if ! grep -q NO_PUBKEY /tmp/apt-get-update-errors; then
    echo "All the keys are ok, nothing to do."
    rm -f /tmp/apt-get-update-errors
    exit 0
fi

# shellcheck disable=SC2013
for KEY in $(awk '/NO_PUBKEY/ {print $NF}' /tmp/apt-get-update-errors); do
    echo "Processing $KEY:"
    echo -n " -> getting the key from the server... " && \
        gpg --keyserver pgp.mit.edu --recv-keys "$KEY" >/dev/null 2>&1 && \
        echo "OK" && echo -n " -> adding a key to the database... " && \
        gpg --armor --export "$KEY" | apt-key add -
done
rm -f /tmp/apt-get-update-errors
