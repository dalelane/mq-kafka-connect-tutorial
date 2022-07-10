#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

echo "------------------------------------------------------------------"
echo "Deploying a development ldap server for use by IBM MQ in OpenShift"
echo "------------------------------------------------------------------"

echo "> Creating namespace where the ldap server will run"
oc create namespace ldap --dry-run=client -o yaml | oc apply -f -

echo "> Granting privileged runtime permissions to the ldap pod"
oc create serviceaccount ldapaccount -n ldap --dry-run=client -o yaml | oc apply -f -
oc adm policy add-scc-to-user privileged system:serviceaccount:ldap:ldapaccount
oc adm policy add-scc-to-user anyuid system:serviceaccount:ldap:ldapaccount

echo "> Deploying LDAP server"
oc apply -f ./resources/config.yaml
oc apply -f ./resources/deployment.yaml
oc apply -f ./resources/service.yaml

echo "----------------------------------------------------------------------"
echo "LDAP service is available internally via ldap-service.ldap on port 389"
echo "----------------------------------------------------------------------"
