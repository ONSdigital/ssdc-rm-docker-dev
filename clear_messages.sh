#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: clear_messages.sh <SUBSCRIPTION> <PROJECT>"
    exit 1
fi

PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python -m message_tools.clear_messages "$1" --project "$2"
