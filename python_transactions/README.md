# README 

This is the prototype pattern for transaction/ error handling in Python. 
It leverages the SQLAlchemy [Scoped Sessions](https://docs.sqlalchemy.org/en/20/orm/contextual.html) to deal with concurrent database interactions and PubSub nacking to implement the retry mechainsm on error.

### To see it work:
Run  `make up` from the root of the repo and wait for the PubSub emulator to come up.

Then, run `./test_python_transactions.sh`