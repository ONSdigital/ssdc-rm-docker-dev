from .db.db_utility import create_tables
from .decorators import pubsub_transaction, sqlalchemy_transaction
from .pubsub_util.publisher import *
from .pubsub_util.subscriber import *
from .db.entity_table import Entity, print_all_entities, drop_example_table
from sqlalchemy.orm import Session

PROJECT = "PROJECT_TEST"
TOPIC = "TOPIC_TEST"
SUBSCRIPTION = "SUBSCRIPTION_TEST"


@pubsub_transaction
@sqlalchemy_transaction
def callback(message: pubsub_v1.subscriber.message.Message, session: Session) -> None:
    survey = Entity(id=1, text="Test Entity")
    session.add(survey)
    print(f"Message {message.attributes.get('number')} received!")
    message.ack()


if __name__ == "__main__":
    create_tables()
    create_fresh_topic(PROJECT, TOPIC)
    create_fresh_subscription(PROJECT, TOPIC, SUBSCRIPTION)

    publish_messages(PROJECT, TOPIC)

    receive_messages_async(PROJECT, SUBSCRIPTION, callback=callback, timeout=1.0)

    print_all_entities()
    drop_example_table()

