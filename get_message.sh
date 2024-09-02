#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: get_message.sh <SUBSCRIPTION> <PROJECT>"
    exit 1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python -m message_tools.get_message "$1" --project "$2"
