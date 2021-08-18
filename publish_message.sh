#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: publish_message.sh <PROJECT> <TOPIC>"
    exit -1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python publish_message.py $1 --project $2
