# README 

This is the prototype pattern for transaction/ error handling in Python. 
It leverages the SQLAlchemy [Scoped Sessions](https://docs.sqlalchemy.org/en/20/orm/contextual.html) to deal with concurrent database interactions and PubSub nacking to implement the retry mechainsm on error.