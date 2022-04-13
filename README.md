# Stand up a local SSDC RM App Environment

The goal of this repository is to enable team members to stand up a dockerized local census application using **docker
compose** and **docker network**.

## Pre-requisites

1. You can access the google cloud docker registry
1. Ask to become a team member of sdcplatform
1. Run `gcloud auth configure-docker europe-west2-docker.pkg.dev` to associate your docker with the GCR registry
1. Run `docker network create ssdcrmdockerdev_default` to create the docker network
1. Connect to the gcr registry and perform a `make pull` do bring down docker-compose images

Important is to configure your python environment - that's covered next.

## Configure Local Python Environments to Run Acceptance Tests

#### Currently Supported Python Version is 3.6.10 and Machine Version is 3.7.7

The goal is to setup our python environments ready to run Python 3.X.X (whaterver is currently supported). It is good
practise to keep your machine version in line with the latest (today it is 3.P.Q).

Validate your python versions with **`python -V`** and printenv.

Initializing pyenv is one of those boring things that must always be done. You can circumnavigate this by adding the
below command to the .zshrc (if using a z shell) or .inputrc or .profile or .bash_profile (if using a bash on a Mac).

```
eval "$(pyenv init -)"
```

- **`pyenv --version`**      # check whether pyenv is installed
- **`brew install pyenv`**   # install pyenv with brew
- **`pyenv install 3.X.Y`**  # the app needs python 3.6
- **`pyenv local 3.x.y`**    # whenever you come to this directory this python will be used

pyenv loal will create a **.python-version** file so that whenever you return to the directory your python env is set.
Note that this has been put into `.gitignore`

## PipEnv | Upgrading Python | Projects with a Pip File

As this project maintains a pip file you can ascertain validity by running **`pipenv check`** - whenever Python is
upgraded the Pipfile change is all that is required. To ensure you are in sync use

- **`pipenv check`**  # check whether the environments match
- **`pipenv --rm`**   # if the check fails remove the current environment

## Setup Based on python 3.X.Y

Use [Pyenv](https://github.com/pyenv/pyenv) to manage installed Python versions

[Pipenv](https://docs.pipenv.org/) is required locally for running setup scripts

```bash
pip install -U pipenv
```

## Quickstart

![make up](https://media.giphy.com/media/xULW8lyhMJjzyO33sA/giphy.gif)

```
make up
```

## Slowstart

There are 2 docker-compose files in this repository:

- dev.yml - spins up the core development containers such as postgres
- rm-services.yml - spins up the Java and Go services such as survey service and action service

These can be run together as per the Quickstart section or individually. Additionally individual services can be
specified at the end of the command. For example:

```
docker-compose -f dev.yml -f rm-services.yml up -d
```

This will spin up the development containers and the rm-services.

```
docker-compose -f rm-services.yml up -d collex
```

This will spin up just the collection exercise service.

## Development

Both RM and RH services can be started and stopped.
The makefile contains targets that can start and stop eithr the RM services, RH services or both using:

| Make target   | Result                          |
|---------------|---------------------------------|
| rmrh-_target_ | Affects both RH and RM services |
| rm-_target_   | Only affects RM services        |
| rh-_target_   | Only affects RH services        |

e.g. `make rm-up` to start the RM services.

**Note**
If you are running both the RM and RH services, and you stop one of them using their `make` target, then the pubsub-emulator will stop so this will need to be brought up again.

### Running in docker with local changes

Development using this repo can be done by doing the following:

1. Move to the repository directory and make the code changes in the service repository locally
1. Rebuild the image and tag it as the latest to 'trick' the build into thinking we already have the latest and don't
   need to pull down the image from dockerhub.
    - `make build-no-test`
1. Finally, return to the docker-dev repository and restart the service with `make rm-up`. You should see the image you
   have rebuilt get recreated.

### Running natively with local changes

1. Ensure you have all your services running with `make up`
1. Stop the service you're changing with `docker stop service`
1. Delete the image with `docker rm service`
1. Make changes to whichever repository.
1. Depending on the repository, run it from either the command line using the appropriate command (e.g. for a python
   flask app: `flask run`) or by pressing run in your IDE.

### pgAdmin 4

1. Start all the services `make rm-up`
2. Navigate to `localhost:80` in your browser
3. Login with `ons@ons.gov` / `secret`
4. Object -> Create -> Server...
5. Give it a suitable name then in the connection tab:
    1. `postgres` for the host name
    1. `5432` for the port
    1. `postgres` for the maintenance database
    1. `postgres` for the username
6. Click save to close the dialog and connect to the postgres docker container

## Troubleshooting

### Not logged in

```
Pulling iac (sdcplatform/iacsvc:latest)...
ERROR: pull access denied for sdcplatform/iacsvc, repository does not exist or may require 'docker login'
make: *** [pull] Error 1
```

1. Create a docker hub account
1. Ask to become a team member of sdcplatformras
1. Run `docker login` in a terminal and use your docker hub account

### Database already running

- `sm-postgres` container not working? Check there isn't a local postgres running on your system as it uses port 5432
  and won't start if another service is running on this port.

### Port already bound to

```
ERROR: for collection-instrument  Cannot start service collection-instrument-service: driver failed programming external connectivity on endpoint collection-instrument (7c6ad787c9d57028a44848719d8d705b14e1f82ea2f393ada80e5f7e476c50b1): Error starting userland pStarting secure-message ... done

ERROR: for collection-instrument-service  Cannot start service collection-instrument-service: driver failed programming external connectivity on endpoint collection-instrument (7c6ad787c9d57028a44848719d8d705b14e1f82ea2f393ada80e5f7e476c50b1): Error starting userland proxy: Bind for 0.0.0.0:8002 failed: port is already allocated
ERROR: Encountered errors while bringing up the project.
make: *** [up] Error 1
```

- Kill the process hogging that port by running `lsof -n -i:8002|awk 'FNR == 2 { print $2 }'|xargs kill` where 8002 is
  the port you are trying to bind to

### Docker network

```
ERROR: Network ssdcrmdockerdev_default declared as external, but could not be found. Please create the network manually using `docker network create ssdcrmdockerdev_default` and try again.
make: *** [up] Error 1
```

- Run `docker network create censusrmdockerdev_default` to create the docker network.

**NB:** Docker compose may warn you that the network is unused. This is a lie, it is in use.

### Unexpected behavior

1. Stop docker containers `make down`
1. Remove containers `docker rm $(docker ps -aq)`
1. Delete images `docker rmi $(docker images -qa)`
1. Pull and run containers `make up`

### Service not up?

Some services aren't resilient to the database not being up before the service has started. Rerun `make up`

### Services running sluggishly?

When rm is all running it takes a lot of memory. Click on the docker icon in the top bar of your Mac, then click on '
preferences', then go to the 'advanced' tab. The default memory allocated to Docker is 2gb. Bumping that up to 8gb and
the number of cores to 4 should make the service run much smoother. Note: These aren't hard and fast numbers, this is
just what worked for people.

## Publishing to Pub/Sub Topics in Emulator

Run `./publish_message.sh <TOPIC> <PROJECT>` and then paste in a JSON message. Press CTRL-D when you're done.

## Pulling from Pub/Sub Subscriptions in Emulator

Run `./get_message.sh <SUBSCRIPTION> <PROJECT>`.

## Purging Messages on a Pub/Sub Subscriptions in Emulator

Run `./clear_messages.sh <SUBSCRIPTION> <PROJECT>`.

## Checking out, building multiple branches from a PR

Run `SKIP_TESTS=<true/false> BRANCH_NAME=<branch name> ./checkout_and_build_pr.sh`

This will checkout and build a PR Branch for you. This script does not checkout docker-dev (what happens if the PR
includes an update to the script!)
Instead if the PR contains a docker-dev PR, checkout that docker dev. Run ./checkout_and_build_pr.sh and it'll look at
the branch you're on and checkout and install in ./PR_DIR/ under docker dev. It should bring up the new images and
unless SKIP_TESTS=true it will run the ATs too.

If the PR doesn't have a docker dev, then run the script from main and specify the BRANCH_NAME.

command defaut info BRANCH_NAME DEFAULTS TO DOCKER DEV BRANCH BRANCH TO CHECKOUT SKIP_TESTS FALSE SKIP BUILD AND
ACCEPTANCE TESTS KILL_DOCKER TRUE KILLS AND REMOVES RUNNING CONTAINERS