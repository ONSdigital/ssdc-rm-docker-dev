from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import Session
from .db_utility import Session,Base


class Entity(Base):
    __tablename__ = "test_entity_table"
    id = Column(Integer, primary_key=True)
    text = Column(String)

def print_all_entities():
    session = Session()
    print('Entities: ')
    for user in session.query(Entity):
        print(f"Entity.id: {user.id}")

def drop_example_table():
    session = Session()
    session.query(Entity).delete()
    print("Entity table emptied")
    session.commit()

