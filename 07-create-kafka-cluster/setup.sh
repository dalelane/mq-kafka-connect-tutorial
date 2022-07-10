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

echo "----------------------------------------"
echo "Creating the Event Streams Kafka cluster"
echo "----------------------------------------"

echo "> Creating namespace where the Kafka cluster will run"
oc create namespace kafka --dry-run=client -o yaml | oc apply -f -

echo "> Creating entitlement key for accessing Event Streams docker images"
oc create secret docker-registry ibm-entitlement-key \
    --docker-username=cp \
    --docker-password=$IBM_ENTITLEMENT_KEY \
    --docker-server=cp.icr.io \
    --namespace=kafka --dry-run=client -o yaml | oc apply -f -

echo "> Creating the Kafka cluster"
oc apply -f ./resources/cluster.yaml

echo "> Waiting for Event Streams to be ready"
PHASE="Pending"
while [ "$PHASE" != "Ready" ]
do
    PHASE=`oc get eventstreams -nkafka eventstreams -o jsonpath='{.status.phase}'`
    sleep 10
done


echo "--------------------------------"
echo "Event Streams cluster is created"
echo "--------------------------------"
