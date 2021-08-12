#!/bin/sh

if [ $# -ne 1 ]
then
    echo "Usage: publish_message.sh <TOPIC>"
    exit -1
fi

source .env

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=$PUBSUB_SETUP_HOST pipenv run python publish_message.py $1
