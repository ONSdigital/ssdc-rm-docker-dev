import argparse

from google.cloud import pubsub_v1


def send_message(project, topic, message):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project, topic)

    future = publisher.publish(topic_path, data=message.encode('utf-8'))
    future.result(timeout=30)


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Publish a message to Google Pub/Sub (or the emulator)')
    parser.add_argument('topic', help='The topic to publish to', type=str)
    parser.add_argument('--project', help='The project the topic belongs to',
                        type=str, default='project')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()

    print("Enter/Paste your message. Ctrl-D or Ctrl-Z ( windows ) to send it.")
    message_lines = []
    while True:
        try:
            line = input()
        except EOFError:
            break
        message_lines.append(line)

    message_string = '\n'.join(message_lines)

    send_message(args.project, args.topic, message_string)
