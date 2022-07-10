#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

echo "-------------------------------------"
echo "Installing the Event Streams Operator"
echo "-------------------------------------"

echo "> adding the IBM Catalog Source"
oc apply -f ./resources/catalogsource.yaml

echo "> wait for the catalog pod to be created"
PODS_COUNT="0"
while [ "$PODS_COUNT" = "0" ]
do
    PODS_COUNT=`oc get pods -l "olm.catalogSource=ibm-operator-catalog" -n openshift-marketplace --no-headers | wc -l | tr -d ' '`
    sleep 3
done

echo "> wait for the catalog pod to finish starting"
POD_PHASE="Pending"
while [ "$POD_PHASE" = "Pending" ]
do
    POD_PHASE=`oc get pods -l "olm.catalogSource=ibm-operator-catalog" -n openshift-marketplace -ojsonpath='{.items[0].status.phase}'`
    sleep 10
done
if [ "$POD_PHASE" != "Running" ]; then
    exit 1
fi

echo "> install the Event Streams operator"
oc apply -f ./resources/subscription.yaml

echo "> wait for the Event Streams operator install plan to be created"
INSTALL_PLAN=""
while [ -z "$INSTALL_PLAN" ]
do
    INSTALL_PLAN=`oc get subscription ibm-eventstreams -n openshift-operators -ojsonpath='{.status.installPlanRef.name}'`
done

echo "> wait for the Event Streams operator install plan to complete"
INSTALL_PHASE="Installing"
while [ "$INSTALL_PHASE" = "Installing" ]
do
    INSTALL_PHASE=`oc get installplan $INSTALL_PLAN -n openshift-operators -ojsonpath='{.status.phase}'`
    sleep 10
done
if [ "$INSTALL_PHASE" != "Complete" ]; then
    exit 1
fi


echo "-----------------------------------"
echo "Event Streams Operator is available"
echo "-----------------------------------"
