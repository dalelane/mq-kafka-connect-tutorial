#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

echo "----------------------------------------------------------"
echo "Setting up Kafka Connect to copy messages from MQ to Kafka"
echo "----------------------------------------------------------"

echo "> Modify the MQ queue manager to prepare it for the Connector"
oc apply -f ./resources/modify-qmgr.yaml
oc apply -f ./resources/qmgr.yaml

echo "> Create the route that the Connector will use to access the queue manager"
oc apply -f ./resources/kafkaroute.yaml

echo "> Creating the Kafka topic to use as the target for the connector"
oc apply -f ./resources/topic.yaml

echo "> Creating Event Streams credentials that the Connector will use to access Kafka"
oc apply -f ./resources/kafka-creds.yaml
STATUS="False"
while [ "$STATUS" = "False" ] || [ "$STATUS" = "" ]
do
  STATUS=`oc get kafkauser -n kafka kafka-connect-credentials -ojsonpath='{.status.conditions[?(@.type=="Ready")].status}'`
  sleep 5
done

echo "> Storing MQ credentials that the Connector will use to access MQ"
oc apply -f ./resources/mq-creds.yaml

echo "> Storing certificates that the Connector will use for the SSL connection to MQ"
oc create secret generic jms-client-truststore \
  --from-file=ca.jks=../02-generate-certs/certs/streamingdemo-ca.jks \
  --from-literal=password='passw0rd' \
  -n kafka --dry-run=client -oyaml | oc apply -f -
oc create secret generic jms-client-keystore \
  --from-file=client.jks=../02-generate-certs/certs/streamingdemo-kafka-client.jks \
  --from-literal=password='passw0rd' \
  -n kafka --dry-run=client -oyaml | oc apply -f -
oc create secret generic mq-ca-tls \
  --from-file=ca.crt=../02-generate-certs/certs/streamingdemo-ca.crt \
  -n kafka --dry-run=client -oyaml | oc apply -f -


echo "> Exposing the OpenShift Image Registry so a new Kafka Connect image can be pushed to it"
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

echo "> Build Kafka Connect Docker image with the MQ source connector"
image_registry_route="$(oc get routes -n openshift-image-registry -o custom-columns=:.spec.host --no-headers)"
docker login "$image_registry_route" -u oc -p "$(oc whoami -t)"
docker build -t "$image_registry_route"/kafka/kafkaconnectwithmq:latest .

echo "> Push Kafka Connect image to the OpenShift Image Registry"
docker push "$image_registry_route"/kafka/kafkaconnectwithmq:latest

echo "> Create the Kafka Connect cluster"
oc apply -f ./resources/connect-cluster.yaml

echo "> Start the MQ connector"
oc apply -f ./resources/connector.yaml


echo "-------------------------"
echo "Kafka Connect is starting"
echo "-------------------------"
