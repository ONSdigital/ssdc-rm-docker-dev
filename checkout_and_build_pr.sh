#!/bin/bash

BUILD_AND_TEST_ERRORS=""


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
        echo "${REPO_NAME} Skipping Tests: Running CMD: ${SKIP_TESTS_CMD}"
        $SKIP_TESTS_CMD
    else
        echo "${REPO_NAME} Running Tests: Running CMD: ${RUN_TESTS_CMD}"
        $RUN_TESTS_CMD
    fi

    # If there's a Non Zero Exit this was a failure.  We should record this
    EXIT_CODE=$?
    echo "${REPO_NAME} build cmd, EXIT_CODE ${EXIT_CODE}"

    if [ "$EXIT_CODE" = 0 ] ; then
        echo "${REPO_NAME} Running CMD: ${SKIP_TESTS_CMD}, EXIT CODE 0"
    else
        echo "${REPO_NAME} Running CMD: ${SKIP_TESTS_CMD}, EXIT CODE ${EXIT_CODE}"
        BUILD_AND_TEST_ERRORS+="${REPO_NAME} Running CMD: ${SKIP_TESTS_CMD}, EXIT CODE ${EXIT_CODE}\n"
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

    if [ -d $BASE_DIR ] 
    then
        echo "Directory ${BASE_DIR} exists." 
    else
        echo "Error: Directory ${BASE_DIR} does not exists."
    fi
    #  RM it if it already exists
    # rm $BASE_DIR


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

# # Install DDL
checkout_and_build_repo_branch "ssdc-rm-ddl" $BRANCH_NAME "make dev-build" "make dev-build"
cd ..

# Case Processor
checkout_and_build_repo_branch "ssdc-rm-caseprocessor" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# # Case API
checkout_and_build_repo_branch "ssdc-rm-case-api" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# # Notify Service
checkout_and_build_repo_branch "ssdc-rm-notify-service" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# # Printfilesvc
checkout_and_build_repo_branch "ssdc-rm-print-file-service" $BRANCH_NAME "build_and_test" "docker_build"
cd ..

# Support Tool
checkout_and_build_repo_branch "ssdc-rm-support-tool" $BRANCH_NAME "./build.sh" "./build.sh"
cd ..

# # ROPS
checkout_and_build_repo_branch "ssdc-rm-response-operations" $BRANCH_NAME "./build.sh" "./build.sh"
cd ..

#Qid Service
checkout_and_build_repo_branch "ssdc-rm-uac-qid-service" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

# #Exception Manger
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
# Output Errors
########################################################################################################################

echo -e "\n\n"

if [ -z "$BUILD_AND_TEST_ERRORS"]; then
    echo -e  "\033[1;32m This script did not record any errors in build or test. Take with a pinch of saltt: \033[0m"
else
    echo -e  "\033[1;31m ERRORS in build and test: \033[0m"
    echo -e "\033[1;31m ${BUILD_AND_TEST_ERRORS} \033[0m"
fi

echo -e "\n\n"

########################################################################################################################
# Output runtime
########################################################################################################################
echo "Total Runtime ${SECONDS} seconds"
