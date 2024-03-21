from google.cloud import pubsub_v1

"""
Code copied from:
https://github.com/googleapis/python-pubsub/tree/main/samples/snippets
And edited for the purposes of the Spike
"""

def list_topics(project_id: str) -> None:
    """Lists all Pub/Sub topics in the given project."""
    publisher = pubsub_v1.PublisherClient()
    project_path = f"projects/{project_id}"

    for topic in publisher.list_topics(request={"project": project_path}):
        print(topic)

def create_topic(project_id: str, topic_id: str) -> None:
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)

    topic = publisher.create_topic(request={"name": topic_path})

    print(f"Created topic: {topic.name}")


def create_fresh_topic(project_id: str, topic_id: str):
    try:
        delete_topic(project_id, topic_id)
    except:
        # topic doesn't exist - do nothing
        pass
    create_topic(project_id, topic_id)


def publish_messages(project_id: str, topic_id: str) -> None:
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)

    for n in range(1, 3):
        data_str = f"Message number {n}"
        data = data_str.encode("utf-8")
        future = publisher.publish(topic_path, data, number=str(n))
        print(f"Future.result: {future.result()}")

    print(f"Published messages to {topic_path}.")


def delete_topic(project_id: str, topic_id: str) -> None:
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)

    publisher.delete_topic(request={"topic": topic_path})

    print(f"Topic deleted: {topic_path}")

