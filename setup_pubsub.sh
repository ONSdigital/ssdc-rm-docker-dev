#!/bin/sh

source .env

# Wait for pubsub-emulator to come up
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' '$PUBSUB_SETUP_HOST')" != "200" ]]; do sleep 1; done'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/$RECEIPT_TOPIC_NAME
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/$SUBSCRIPTION_NAME -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/'$RECEIPT_TOPIC_NAME'"}'

