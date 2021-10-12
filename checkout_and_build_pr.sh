#!/bin/bash

########################################################################################################################
# This script will run and attempt to create a new dir in the parent directory of where it's run
# It will then attempt to checkout, build, test (optional) all the required repos to make a running system
# This includes running docker-dev and the ATs. 
# 
#   command              required/defaut           info
#  BRANCH_NAME                REQUIRED             BRANCH TO CHECKOUT
#  SKIP_TESTS                 FALSE                SKIP BUILD AND ACCEPTANCE TESTS 
#  KILL_DOCKER                TRUE                 KILLS AND REMOVES RUNNING CONTAINERS
########################################################################################################################

# This records important cmd results, so we can output it at the end
REPO_CMD_HISTORY=""

function execute_and_record_command() {
    CMD_TO_EXECUTE=$1
    FAILURE_UNEXPECTED=$2

    echo "${CMD_TO_EXECUTE}"
    $CMD_TO_EXECUTE

    EXIT_CODE=$?

    # The exciting \033[1;32m  is colouring,  Green for good, yellow for Info, Red for Error
    if [ "$EXIT_CODE" = 0 ] ; then
        REPO_CMD_HISTORY+="\033[1;32m     SUCCESS: running command [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
    else
        if [ "$FAILURE_UNEXPECTED" = true ] ; then
            REPO_CMD_HISTORY+="\033[1;31m     ERROR: running [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
        else
            REPO_CMD_HISTORY+="\033[0;33m     INFO: running [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
        fi
    fi
}


function checkout_repo_branch() {
    REPO_NAME=$1
    BRANCH_NAME_TO_CHECKOUT=$2
    GIT_SSH="git@github.com:ONSdigital/${REPO_NAME}.git"

    REPO_CMD_HISTORY+="REPO: ${REPO_NAME} \n"

    # echo "Getting cloning ${GIT_SSH}"
    execute_and_record_command "git clone ${GIT_SSH} " true
    cd $REPO_NAME

    execute_and_record_command "git checkout ${BRANCH_NAME_TO_CHECKOUT}" false
}

function checkout_and_build_repo_branch() {
    REPO_NAME=$1
    BRANCH_NAME_TO_CHECKOUT=$2
    RUN_TESTS_CMD=$3
    SKIP_TESTS_CMD=$4

    checkout_repo_branch $REPO_NAME $BRANCH_NAME_TO_CHECKOUT

    if [ "$SKIP_TESTS" = true ] ; then
        echo "${REPO_NAME} Skipping Tests: Running CMD: ${SKIP_TESTS_CMD}"
        execute_and_record_command "${SKIP_TESTS_CMD}" true        
    else
        echo "${REPO_NAME} Running Tests: Running CMD: ${RUN_TESTS_CMD}"
        execute_and_record_command "${RUN_TESTS_CMD}" true  
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
    BRANCH_DIR_TO_MAKE=$1

    echo "Passed branch dir to make ${BRANCH_DIR_TO_MAKE}"
    
    # TODO: Get to grandparent Dir. this could be an optional argument instead
    cd ../../

    BASE_DIR="${PWD}/${BRANCH_DIR_TO_MAKE}"

    # TODO:  What to do if dir alerady exists? rm it, fail etc.. 

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

# Internal Variable, will use to record time
SECONDS=0

# Check Branch name is set
if [ -z "$BRANCH_NAME" ]; then
    echo "You Must set BRANCH_NAME=<branch to test>, use main, if you want main"
    exit 2;
fi

# Create the baseDir
createNewBaseDir $BRANCH_NAME

if [ "$SKIP_TESTS" = true ] ; then
    echo "Script will Skip Tests"
else
    echo "Script will be Running Tests"
fi

# Kill and remove running containers, Flag to disable exists
killOffRunningDocker

########################################################################################################################
#  Build, Install and Test DDL and Applications
########################################################################################################################

# TODO: Maven -Dmaven.test.skip=true stops maven running tests.  However the pre & post integration steps are still 
# run. Ideally we'd skip these too.  May require pom changes though.

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
checkout_and_build_repo_branch "ssdc-rm-print-file-service" $BRANCH_NAME "make build_and_test" "make docker_build"
cd ..

# Support Tool
checkout_and_build_repo_branch "ssdc-rm-support-tool" $BRANCH_NAME "./build.sh" "./build_no_test.sh"
cd ..

# ROPS
checkout_and_build_repo_branch "ssdc-rm-response-operations" $BRANCH_NAME "./build.sh" "./build_no_test.sh"
cd ..

#Qid Service
checkout_and_build_repo_branch "ssdc-rm-uac-qid-service" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..

#Exception Manger
checkout_and_build_repo_branch "ssdc-rm-exception-manager" $BRANCH_NAME "mvn clean install" "mvn clean install -Dmaven.test.skip=true"
cd ..


# ########################################################################################################################
# #  Set up Docker Dev
# ########################################################################################################################
checkout_repo_branch "ssdc-rm-docker-dev" $BRANCH_NAME
execute_and_record_command "pipenv install --dev" true
execute_and_record_command "make pull" true
execute_and_record_command "make up" true
cd ..


# ########################################################################################################################
# #  Acceptance Tests
# ########################################################################################################################
checkout_repo_branch "ssdc-rm-acceptance-tests" $BRANCH_NAME_TO_CHECKOUT
execute_and_record_command "pipenv install --dev" true

if [ "$SKIP_TESTS" = true ] ; then
    echo "Skipping ATs"
else
    echo "Running ATs. Sleeping 60 to allow all services to be up"
    sleep 60
    execute_and_record_command "make test" true
fi
cd ..


########################################################################################################################
# Output Record
########################################################################################################################

echo -e "\n\n"
echo -e $REPO_CMD_HISTORY
echo -e "\n\n"

########################################################################################################################
# Output runtime
########################################################################################################################
echo "Total Runtime ${SECONDS} seconds"
