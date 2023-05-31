#!/bin/bash -e

source .env

check_curl_response() {
  # Expects one argument, the curl response written with "HTTPSTATUS:%{http_code}"
  HTTP_RESPONSE=$1
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
  HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  if [ ! "$HTTP_STATUS" -eq 200 ] && [ ! "$HTTP_STATUS" -eq 409 ]; then
    echo "Error response: $HTTP_BODY"
  fi
}

create_topic() {
  # Expects two arguments: project name and topic name
  HTTP_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT "http://$PUBSUB_SETUP_HOST/v1/projects/$1/topics/$2")
  ERROR=$(check_curl_response "$HTTP_RESPONSE")
  if [ -n "$ERROR" ]; then
    echo
    echo "Error creating topic:"
    echo "  project: \"$1\", topic: \"$2\""
    echo "  $ERROR"
    return 1
  fi
  echo -n "."
}

create_subscription() {
  # If statement to check if there needs to be a pushconfig set for a subscription
  if [ -z "$4" ]; then
  # Expects three arguments: project name, topic name, and subscription name
    HTTP_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT "http://$PUBSUB_SETUP_HOST/v1/projects/$1/subscriptions/$3" -H "Content-Type: application/json" -d "{\"topic\": \"projects/$1/topics/$2\"}");
  else
  # Expects four arguments: project name, topic name, subscription name and push config host
    HTTP_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT "http://$PUBSUB_SETUP_HOST/v1/projects/$1/subscriptions/$3" -H "Content-Type: application/json" -d "{\"topic\": \"projects/$1/topics/$2\", \"pushConfig\":{\"pushEndpoint\":\"http://$4:8100/projects/$1/topics/$2\" }}")
  ERROR=$(check_curl_response "$HTTP_RESPONSE")
  fi
  if [ -n "$ERROR" ]; then
    echo
    echo "Error creating subscription:"
    echo "  project: \"$1\", topic: \"$2\", subscription: \"$3\""
    echo "  $ERROR"
    return 1
  fi
  echo -n "."
}

#######################################
# Expects four arguments: project name, topic name, subscription name and push config host
# Project name: Mandatory
# Topic name: Mandatory
# Subscription name: Mandatory
# Push Config Host: Optional, passed in via ./setup_pubsub.sh
#######################################
create_topic_and_subscription() {
  create_topic "$1" "$2"
  create_subscription "$1" "$2" "$3" "$4"
}

# Wait for pubsub-emulator to come up
echo -n "Waiting for pubsub-emulator to respond"
while [[ "$(curl -s -o /dev/null -w '%{http_code}' "$PUBSUB_SETUP_HOST")" != "200" ]]; do
  echo -n '.'
  sleep 1
done
echo
echo -n "pubsub-emulator is ready, running setup..."

# Internal Topics
create_topic_and_subscription our-project rm-internal-sms-request rm-internal-sms-request_notify-service
create_topic_and_subscription our-project rm-internal-sms-request-enriched rm-internal-sms-request-enriched_notify-service
create_topic_and_subscription our-project rm-internal-sms-confirmation rm-internal-sms-confirmation_case-processor
create_topic_and_subscription our-project rm-internal-email-request rm-internal-email-request_notify-service
create_topic_and_subscription our-project rm-internal-email-request-enriched rm-internal-email-request-enriched_notify-service
create_topic_and_subscription our-project rm-internal-email-confirmation rm-internal-email-confirmation_case-processor

# Event Topics: RM Subscriptions
create_topic_and_subscription our-project event_new-case event_new-case_rm-case-processor
create_topic_and_subscription our-project event_receipt event_receipt_rm-case-processor
create_topic_and_subscription our-project event_refusal event_refusal_rm-case-processor
create_topic_and_subscription our-project event_invalid-case event_invalid-case_rm-case-processor
create_topic_and_subscription our-project event_eq-launch event_eq-launch_rm-case-processor
create_topic_and_subscription our-project event_print-fulfilment event_print-fulfilment_rm-case-processor
create_topic_and_subscription our-project event_deactivate-uac event_deactivate-uac_rm-case-processor
create_topic_and_subscription our-project event_update-sample event_update-sample_rm-case-processor
create_topic_and_subscription our-project event_update-sample-sensitive event_update-sample-sensitive_rm-case-processor

# Event Topics: RH Subscriptions & AT Subscriptions
create_topic_and_subscription our-project event_case-update event_case-update_rh
create_subscription our-project event_case-update event_case-update_rh_at
create_topic_and_subscription our-project event_uac-update event_uac-update_rh
create_subscription our-project event_uac-update event_uac-update_rh_at
create_topic_and_subscription our-project event_survey-update event_survey-update_rh
create_subscription our-project event_survey-update event_survey-update_rh_at
create_topic_and_subscription our-project event_collection-exercise-update event_collection-exercise-update_rh
create_subscription our-project event_collection-exercise-update event_collection-exercise-update_rh_at
create_topic_and_subscription our-project sdx_receipt sdx-receipt_sdx-receipt-adapter sdx-receipt-adapter

# Cloud Tasks
create_topic our-project cloud_task_queue
create_subscription our-project cloud_task_queue cloud_task_queue_at

echo
 