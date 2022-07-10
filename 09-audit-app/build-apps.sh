#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

echo "----------------------------------------------------------------------------"
echo "Building the audit apps that will replay messages from the MQ.COMMANDS topic"
echo "----------------------------------------------------------------------------"

echo "> download certificate for the audit app to use"
oc extract -nkafka secret/eventstreams-cluster-ca-cert --keys=ca.p12 --confirm

echo "> create credentials for the audit app to use"
oc apply -f ./resources/audit-creds.yaml
STATUS="False"
while [ "$STATUS" = "False" ] || [ "$STATUS" = "" ]
do
  STATUS=`oc get kafkauser -n kafka audit-app -ojsonpath='{.status.conditions[?(@.type=="Ready")].status}'`
  sleep 5
done

echo "> updating app config with bootstrap address"
BOOTSTRAP=$(oc get eventstreams eventstreams -nkafka -ojsonpath='{.status.kafkaListeners[?(@.type=="external")].bootstrapServers}')
gsed -i -e 's/PLACEHOLDERBOOTSTRAP/'$BOOTSTRAP'/' kafka-simple/src/main/java/com/ibm/clientengineering/kafka/samples/Config.java

echo "> updating app config with password for CA cert"
CA_PASSWORD=$(oc get secret eventstreams-cluster-ca-cert -nkafka -o 'go-template={{index .data "ca.password"}}' | base64 -d)
gsed -i -e 's/PLACEHOLDERTRUSTSTOREPASSWORD/'$CA_PASSWORD'/' kafka-simple/src/main/java/com/ibm/clientengineering/kafka/samples/Config.java

echo "> updating app config with Kafka password"
PASSWORD=$(oc get secret audit-app -nkafka -o jsonpath='{..password}' | base64 -d)
gsed -i -e 's/PLACEHOLDERAPPPASSWORD/'$PASSWORD'/' kafka-simple/src/main/java/com/ibm/clientengineering/kafka/samples/Config.java

echo "> building audit app"
cd kafka-simple
mvn package

echo "----------------------------------------------------------------------"
echo "Audit app is ready to run"
echo "----------------------------------------------------------------------"
