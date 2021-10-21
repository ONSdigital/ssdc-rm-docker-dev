#!/bin/sh
if [ $# -ne 1 ]
then
    echo "Usage: ras_rm_pubsub_bridge.sh <username>"
    exit 1
fi

echo "Starting the RM local dev <--> RAS-RM GCP dev bridge..."
PIPENV_DONT_LOAD_ENV=1 RASRM_DEV_USERNAME=$1 pipenv run python ras_rm_pubsub_bridge_publisher.py &
PIPENV_DONT_LOAD_ENV=1 PUBSUB_EMULATOR_HOST=localhost:8538 pipenv run python ras_rm_pubsub_bridge_listener.py &
