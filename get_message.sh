#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: get_message.sh <PROJECT> <SUBSCRIPTION>"
    exit -1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python get_message.py $1 --project $2
