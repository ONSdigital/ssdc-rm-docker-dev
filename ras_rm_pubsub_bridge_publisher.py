from google.cloud import pubsub_v1

from flask import Flask
from flask import request
from flask import jsonify

app = Flask(__name__)


@app.route("/")
def get_info():
    return "<p>RAS-RM Pub/Sub Bridge is running!</p>"


@app.route('/message', methods=['POST'])
def handle_post_message():
    print("Forwarding message from bridge to RAS-RM pubsub.")
    message = request.get_data()
    # send_message('ssdc-rm-nickgrant12', 'event_case-update', message)
    send_message('ras-rm-dev', 'case-notification-grantn', message)
    return jsonify({'sent': True})


def send_message(project, topic, message):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project, topic)

    future = publisher.publish(topic_path, data=message)
    future.result(timeout=30)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port='5000')
