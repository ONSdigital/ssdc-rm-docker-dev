import argparse

from google.api_core import retry
from google.api_core.exceptions import DeadlineExceeded
from google.cloud import pubsub_v1


def clear_messages(project, subscription):
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project, subscription)

    NUM_MESSAGES = 1000

    # Wrap the subscriber in a 'with' block to automatically call close() to
    # close the underlying gRPC channel when done.
    with subscriber:
        # The subscriber pulls a specific number of messages. The actual
        # number of messages pulled may be smaller than max_messages.
        response = subscriber.pull(
            request={"subscription": subscription_path, "max_messages": NUM_MESSAGES},
            retry=retry.Retry(deadline=15),
        )

        ack_ids = []
        for received_message in response.received_messages:
            ack_ids.append(received_message.ack_id)

        # Acknowledges the received messages so they will not be sent again.
        subscriber.acknowledge(
            request={"subscription": subscription_path, "ack_ids": ack_ids}
        )

        if ack_ids:
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
