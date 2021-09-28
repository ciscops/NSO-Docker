#!/bin/sh
# baseimage will make env variables available
if [ -f /etc/container_environment.sh ]; then . /etc/container_environment.sh; fi
echo username=$GIT_USERNAME; echo password=$OAUTH_TOKEN
