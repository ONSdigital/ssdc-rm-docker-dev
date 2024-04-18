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
            pubsub_message.ack()
            print(f"Message acked: {pubsub_message.data}\n")
        except Exception as e:
            print(f"\nPubSub decorator caugth error: {e}\n")
            pubsub_message.nack()
            print(f"Message nacked: {pubsub_message.data}\n")

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
            print(f"\nDB transaction decorator caught exception: {e}\n")
            raise Exception("SQL transaction error")

    return with_transaction_handling


def transaction(callback: Callable) -> Callable:

    @wraps(callback)
    def with_transaction_handling(*args, **kwargs):
        local_session = Session()
        pubsub_message = args[0]

        try:
            callback(*args, **kwargs, session=local_session)
            local_session.commit()
            Session.remove()
            print("Session commited OK")
            pubsub_message.ack()
            print(f"Message {pubsub_message.data} acked OK")
            
        except Exception as e:
            Session.remove()
            pubsub_message.nack()
            print(f"Transaction error: {e}")

    return with_transaction_handling

