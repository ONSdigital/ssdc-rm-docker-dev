#!/bin/sh

source .env

# Wait for pubsub-emulator to come up
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' '$PUBSUB_SETUP_HOST')" != "200" ]]; do sleep 1; done'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/$RECEIPT_TOPIC_NAME
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/$SUBSCRIPTION_NAME -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/'$RECEIPT_TOPIC_NAME'"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/caseApi.caseProcessor.telephoneCapture.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/caseApi.caseProcessor.telephoneCapture.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/caseApi.caseProcessor.telephoneCapture.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/supportTool.caseProcessor.sample.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/supportTool.caseProcessor.sample.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/supportTool.caseProcessor.sample.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.response.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.response.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.response.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.refusal.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.refusal.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.refusal.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/caseProcessor.printFileSvc.printBatchRow.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/caseProcessor.printFileSvc.printBatchRow.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/caseProcessor.printFileSvc.printBatchRow.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.invalidAddress.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.invalidAddress.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.invalidAddress.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.surveyLaunched.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.surveyLaunched.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.surveyLaunched.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.fulfilment.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.fulfilment.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.fulfilment.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.deactivateUac.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.deactivateUac.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.deactivateUac.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseProcessor.updateSampleSensitive.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseProcessor.updateSampleSensitive.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseProcessor.updateSampleSensitive.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.caseUpdate.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.caseUpdate.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.caseUpdate.topic"}'

curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/topics/events.uacUpdate.topic
curl -X PUT http://$PUBSUB_SETUP_HOST/v1/projects/$RECEIPT_TOPIC_PROJECT_ID/subscriptions/events.uacUpdate.subscription -H 'Content-Type: application/json' -d '{"topic": "projects/'$RECEIPT_TOPIC_PROJECT_ID'/topics/events.uacUpdate.topic"}'

