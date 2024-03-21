from functools import wraps
from time import sleep
from typing import Callable
from .db.db_utility import Session


def pubsub_transaction(func: Callable) -> Callable:
    @wraps(func)
    def with_pubsub_error_handling(*args, **kwargs):
        pubsub_message = args[0]

        try:
            func(*args, **kwargs)
            pubsub_message.nack()
        except Exception as e:
            print(f"PubSub decorator caugth error: {e}")
            pubsub_message.nack()
            print(f"Message nacked: {pubsub_message.data}")

    return with_pubsub_error_handling


def sqlalchemy_transaction(func: Callable) -> Callable:

    @wraps(func)
    def with_transaction_handling(*args, **kwargs):
        local_session = Session()
        try:
            func(*args, **kwargs, session=local_session)
            local_session.commit()
            Session.remove()

        except Exception as e:
            Session.remove()
            print("DB transaction decorator caught exception: {e}")
            raise Exception("SQL transaction error")

    return with_transaction_handling
