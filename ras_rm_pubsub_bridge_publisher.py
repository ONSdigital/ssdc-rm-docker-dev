import os

from google.cloud import pubsub_v1

from flask import Flask
from flask import request
from flask import jsonify

app = Flask(__name__)
ras_rm_gcp_dev_username = os.getenv("RASRM_DEV_USERNAME")


@app.route("/")
def get_info():
    return "<p>RAS-RM Pub/Sub Bridge is running!</p>"


@app.route('/message', methods=['POST'])
def handle_post_message():
    print("Forwarding message from bridge to RAS-RM pubsub.")
    message = request.get_data()
    send_message('ras-rm-dev', f'case-notification-{ras_rm_gcp_dev_username}', message)
    return jsonify({'sent': True})


def send_message(project, topic, message):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project, topic)

    future = publisher.publish(topic_path, data=message)
    future.result(timeout=30)


if __name__ == "__main__":
    if not ras_rm_gcp_dev_username:
        print ('ERROR: Must set RASRM-DEV-USERNAME')
        exit(-1)

    print(f"Forwarding for messages to {ras_rm_gcp_dev_username} RAS-RM dev GCP pubsub topic..\n")

    app.run(host='0.0.0.0', port='5634')
