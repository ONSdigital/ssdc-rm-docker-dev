#!/bin/bash


function checkout_repo_branch() {
    REPO_NAME=$1
    BRANCH_NAME_TO_CHECKOUT=$2
    GIT_SSH="git@github.com:ONSdigital/${REPO_NAME}.git"

    echo "Getting cloning ${GIT_SSH}"
    git clone $GIT_SSH
    cd $REPO_NAME

    echo "Attempting to checkout Branch ${BRANCH_NAME_TO_CHECKOUT}"
    git checkout $BRANCH_NAME_TO_CHECKOUT
}

function checkout_and_build_repo_branch() {
    REPO_NAME=$1
    BRANCH_NAME_TO_CHECKOUT=$2
    RUN_TESTS_CMD=$3
    SKIP_TESTS_CMD=$4

    checkout_repo_branch $REPO_NAME $BRANCH_NAME_TO_CHECKOUT

    if [ "$SKIP_TESTS" = true ] ; then
        echo "Skipping Tests: Running CMD: ${SKIP_TESTS_CMD}"
        $SKIP_TESTS_CMD | tee file.txt 
    else
        echo "Running Tests: Running CMD: ${RUN_TESTS_CMD}"
        $RUN_TESTS_CMD | tee file.txt 
    fi
}

function killOffRunningDocker() {

    # Not sure if you'd never want to do this?  Doesn't cost any time if already clear
    if [ "$KILL_DOCKER" = false ] ; then
        echo "Leaving Docker alone"
    else
        echo 'Stopping any running Docker containers'
        docker stop $(docker ps -aq)

        echo 'Removing any stopped Docker containers'
        docker rm $(docker ps -a -q)
    fi

}

function createNewBaseDir() {
    
    BASE_DIR="/Users/lozel/projects/HACK_TEST_DIR/${BRANCH_NAME}"

    echo "Making new base dir ${BASE_DIR}"
    mkdir $BASE_DIR

    cd $BASE_DIR
    echo "Now in new DIR: ${PWD}"
}


########################################################################################################################
#
#         START OF SCRIPT
#
########################################################################################################################

# Check Branch name is set
if [ -z "$BRANCH_NAME" ]; then
    echo "You Must set BRANCH_NAME=<branch to test>, use main, if you want main"
    exit 2;
fi

# Internal Variable, will use to record time
SECONDS=0

if [ "$SKIP_TESTS" = true ] ; then
    echo "Script will Skip Tests"
else
    echo "Script will be Running Tests"
fi


killOffRunningDocker
createNewBaseDir

########################################################################################################################
#  Build, Install and Test DDL and Applications
########################################################################################################################

# Install DDL
checkout_and_build_repo_branch "ssdc-rm-ddl" $BRANCH_NAME "make dev-build" "make dev-build"
cd ..

# Case Processor
checkout_and_build_repo_branch "ssdc-rm-caseprocessor" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# Case API
checkout_and_build_repo_branch "ssdc-rm-case-api" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# Notify Service
checkout_and_build_repo_branch "ssdc-rm-notify-service" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# Printfilesvc
checkout_and_build_repo_branch "ssdc-rm-print-file-service" $BRANCH_NAME "build_and_test" "docker_build"
cd ..

# Support Tool
checkout_and_build_repo_branch "ssdc-rm-support-tool" $BRANCH_NAME "./build.sh" "./build.sh"
cd ..

# ROPS
checkout_and_build_repo_branch "ssdc-rm-response-operations" $BRANCH_NAME "./build.sh" "./build.sh"
cd ..

#Qid Service
checkout_and_build_repo_branch "ssdc-rm-uac-qid-service" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

#Exception Manger
checkout_and_build_repo_branch "ssdc-rm-exception-manager" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

########################################################################################################################
#  Set up Docker Dev
########################################################################################################################
checkout_repo_branch "ssdc-rm-docker-dev" $BRANCH_NAME 
pipenv install --dev
make pull
make up
cd ..


########################################################################################################################
#  Acceptance Tests
########################################################################################################################
checkout_repo_branch "ssdc-rm-acceptance-tests" $BRANCH_NAME_TO_CHECKOUT
pipenv install --dev

if [ "$SKIP_TESTS" = true ] ; then
    echo "Skipping ATs"
else
    echo "Running ATs. Sleeping 60 to allow all services to be up"
    sleep 60
    make test
fi
cd ..


########################################################################################################################
# Output runtime
########################################################################################################################
echo "Total Runtime ${SECONDS} seconds"
