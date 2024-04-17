from .db.db_utility import create_tables
from .decorators import pubsub_transaction, sqlalchemy_transaction
from .pubsub_util.publisher import *
from .pubsub_util.subscriber import *
from .db.entity_table import Entity, print_all_entities, drop_example_table
from sqlalchemy.orm import Session
from .config import PubsubConfig

@pubsub_transaction
@sqlalchemy_transaction
def callback(message: pubsub_v1.subscriber.message.Message, session: Session) -> None:
    survey = Entity(id=1, text="Test Entity")
    session.add(survey)
    print(f"Message {message.attributes.get('number')} received!")

if __name__ == "__main__":
    project_id = PubsubConfig.PROJECT
    topic_id = PubsubConfig.TOPIC
    subscription_id = PubsubConfig.SUBSCRIPTION

    create_tables()
    create_fresh_topic(project_id, topic_id)
    create_fresh_subscription(project_id, topic_id, subscription_id)

    publish_messages(project_id, topic_id)

    receive_messages_async(project_id, subscription_id, callback=callback, timeout=1.0)

    print_all_entities()
    drop_example_table()

