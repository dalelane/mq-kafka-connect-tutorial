#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

# check that we have an entitlement key that we can put in a secret
if [[ -z "$IBM_ENTITLEMENT_KEY" ]]; then
    echo "You must set an IBM_ENTITLEMENT_KEY environment variable" 1>&2
    echo "Create your entitlement key at https://myibm.ibm.com/products-services/containerlibrary" 1>&2
    echo "Set it like this:" 1>&2
    echo " export IBM_ENTITLEMENT_KEY=..." 1>&2
    exit 1
fi

echo "-----------------------------"
echo "Creating the MQ queue manager"
echo "-----------------------------"

echo "> Creating namespace where the queue manager will run"
oc create namespace ibmmq --dry-run=client -o yaml | oc apply -f -

echo "> Creating entitlement key for accessing MQ docker images"
oc create secret docker-registry ibm-entitlement-key \
    --docker-username=cp \
    --docker-password=$IBM_ENTITLEMENT_KEY \
    --docker-server=cp.icr.io \
    --namespace=ibmmq --dry-run=client -o yaml | oc apply -f -

echo "> Creating secrets with certificates needed by the queue manager"
oc create secret tls mq-server-tls -nibmmq \
    --key="../02-generate-certs/certs/streamingdemo-mq-server.key" \
    --cert="../02-generate-certs/certs/streamingdemo-mq-server.crt" \
    --dry-run=client -oyaml | oc apply -f -
oc create secret generic mq-ca-tls -nibmmq \
    --from-file=ca.crt=../02-generate-certs/certs/streamingdemo-ca.crt \
    --dry-run=client -oyaml | oc apply -f -

echo "> Preparing the configuration for the queue manager"
oc apply -f ./resources/configure-qmgr.yaml

echo "> Creating the queue manager"
oc apply -f ./resources/qmgr.yaml

echo "> Setting up route for connecting to the queue manager"
oc apply -f ./resources/approute.yaml

echo "> Waiting for queue manager to be ready"
PHASE="Pending"
while [ "$PHASE" != "Running" ]
do
    PHASE=`oc get queuemanager -nibmmq queuemanager -o jsonpath='{.status.phase}'`
    sleep 10
done


echo "-------------------------------"
echo "Queue manager MYQMGR is created"
echo "-------------------------------"
