import argparse
import json

from google.api_core.exceptions import DeadlineExceeded
from google.cloud import pubsub_v1


def get_message(project, subscription):
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project, subscription)

    try:
        response = subscriber.pull(subscription_path, max_messages=1, timeout=2)

        if response.received_messages:
            print(json.dumps(json.loads(response.received_messages[0].message.data), indent=2))
        else:
            print("No messages on subscription")
    except DeadlineExceeded:
        print("No messages on subscription")
        return

    ack_ids = [message.ack_id for message in response.received_messages]

    if ack_ids:
        subscriber.acknowledge(subscription_path, ack_ids)


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Pull a message from a Google Pub/Sub subscription (or the emulator)')
    parser.add_argument('subscription', help='The subscription to pull from', type=str)
    parser.add_argument('--project', help='The project the subscription belongs to',
                        type=str, default='project')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()

    get_message(args.project, args.subscription)
