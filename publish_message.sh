#!/bin/sh

if [ $# -ne 1 ]
then
    echo "Usage: publish_message.sh <TOPIC>"
    exit -1
fi

source .env

echo "Pipe in message to send to topic '$1', or paste and it ctrl-d when done"
message=$(cat)

PUBSUB_EMULATOR_HOST=$PUBSUB_SETUP_HOST python publish_message.py $1 $message