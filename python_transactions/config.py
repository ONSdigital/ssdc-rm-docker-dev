import os

class PubsubConfig:
    PROJECT = "test-project"
    TOPIC = "test-topic"
    SUBSCRIPTION = "test-subscription"


class DatabaseConfig:
    DB_USERNAME = os.getenv('DB_USERNAME', 'appuser')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = os.getenv('DB_PORT', '6432')
    DB_NAME = os.getenv('DB_NAME', 'rm')