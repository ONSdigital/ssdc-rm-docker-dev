#!/bin/sh

if [ $# -ne 1 ]
then
    echo "Usage: publish_message.sh <TOPIC>"
    exit -1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python publish_message.py $1
