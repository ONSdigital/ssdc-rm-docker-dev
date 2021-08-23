import argparse

from google.api_core.exceptions import DeadlineExceeded
from google.cloud import pubsub_v1


def clear_messages(project, subscription):
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project, subscription)

    try:
        response = subscriber.pull(subscription_path, max_messages=1000, timeout=30)

        if not response.received_messages:
            print("No messages on subscription")
    except DeadlineExceeded:
        print("No messages on subscription")
        return False

    ack_ids = [message.ack_id for message in response.received_messages]

    if ack_ids:
        subscriber.acknowledge(subscription_path, ack_ids)
        return True

    return False


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Clear messages from a Google Pub/Sub subscription (or the emulator)')
    parser.add_argument('subscription', help='The subscription clear messages from', type=str)
    parser.add_argument('--project', help='The project the subscription belongs to',
                        type=str, default='project')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()

    while clear_messages(args.project, args.subscription):
        print(".")

    print("Messages purged")
