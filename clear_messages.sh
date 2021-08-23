#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: clear_messages.sh <SUBSCRIPTION> <PROJECT>"
    exit -1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python clear_messages.py $1 --project $2
