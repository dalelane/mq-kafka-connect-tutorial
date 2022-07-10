#!/bin/bash

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
  cd -- "${BASH_SOURCE%/*}/" || exit
fi

echo "-------------------------------------------"
echo "Getting messages from the MQ.COMMANDS topic"
echo "-------------------------------------------"

java -cp ./kafka-simple/target/kafka-simple-0.0.1.jar com.ibm.clientengineering.kafka.samples.Audit

