#!/bin/bash
#
# Generate a random password.
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 | base64 | tr -d "\n"
