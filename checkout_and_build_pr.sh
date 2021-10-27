#!/bin/bash

# This records important cmd results, so we can output it at the end
REPO_CMD_HISTORY=""

# This will store the PR_DIR/<branch_name> created.  Bash doesn't like function returns
BRANCH_PR_DIR=""

function execute_and_record_command() {
    CMD_TO_EXECUTE=$1
    FAILURE_UNEXPECTED=$2

    echo "${CMD_TO_EXECUTE}"
    $CMD_TO_EXECUTE

    EXIT_CODE=$?

    # The exciting \033[1;32m code is colouring,  Green for good, yellow for Info, Red for Error
    if [ "$EXIT_CODE" = 0 ] ; then
        REPO_CMD_HISTORY+="\033[1;32m     SUCCESS: running command [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
    else
        if [ "$FAILURE_UNEXPECTED" = true ] ; then
            REPO_CMD_HISTORY+="\033[1;31m     ERROR: running [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
        else
            REPO_CMD_HISTORY+="\033[0;33m     INFO: running [${CMD_TO_EXECUTE}], exit code ${EXIT_CODE} \n\033[0m"
        fi
    fi

    return $EXIT_CODE
}


function checkout_repo_branch() {
    REPO_NAME=$1
    BRANCH_NAME_TO_CHECKOUT=$2
    GIT_SSH="git@github.com:ONSdigital/${REPO_NAME}.git"

    REPO_CMD_HISTORY+="REPO: ${REPO_NAME} \n"

    # echo "Git cloning ${GIT_SSH}"
    execute_and_record_command "git clone ${GIT_SSH} " true
    pushd $REPO_NAME

    execute_and_record_command "git checkout ${BRANCH_NAME_TO_CHECKOUT}" false

    # This is safety for pulling a 2nd time etc
    execute_and_record_command "git pull" true

    # TODO: If there's no branch for this repo (quite likely),  then just pull the image
    # This would save a lot of building time.  Needs thinking about etc
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

    popd
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
    PR_DIR="${PWD}/PR_DIR"

    echo "PR_DIR: "
    mkdir -p $PR_DIR
    cd $PR_DIR

    echo "Making branch dir to make ${BRANCH_DIR_TO_MAKE}"
    mkdir -p $BRANCH_DIR_TO_MAKE

    cd $BRANCH_DIR_TO_MAKE
    echo "Now in new DIR: ${PWD}"

    # because Bash is a painful, set a global
    BRANCH_PR_DIR=$PWD
}

# This gives a rough guide, support tool is usually the slowest to start. And needs to be up
# for the ATs to consume it's APIs.  
function wait_until_containers_are_running_or_timeout() {
    WAIT_FOR_DOCKER_UP_TIMEOUT_SECONDS=180

    for (( i=0; i<=$WAIT_FOR_DOCKER_UP_TIMEOUT_SECONDS; i++ ))
    do
        support_tool_logs=$(docker logs --tail=10 supporttool)

        if [[ $support_tool_logs == *"Started Application in"* ]]; then
            echo "Looks like containers are up, well support tool anyways.."
            return
        fi
            
        # Wait and try again in a second
        sleep 1
        
        echo "Still waiting for healthy containers: after ${i} seconds"
    done

    echo -e "\033[1;31m  ERROR: Docker Containers did not come up with expected time of ${WAIT_FOR_DOCKER_UP_TIMEOUT_SECONDS} seconds \n \033[0m"
    exit 1
}

########################################################################################################################
#
#         START OF SCRIPT
#
########################################################################################################################

# Internal Variable, will use to record time
SECONDS=0

# We'll need to return here
DOCKER_DEV_DIR=$PWD

# Check Branch name is set
if [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

    echo "Branch name not set, going to use BRANCH_NAME: ${BRANCH_NAME}"
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
MVN_INSTALL_TEST_CMD="mvn clean install"
MVN_INSTALL_ONLY_CMD="mvn clean install -Dmaven.test.skip=true -DdockerCompose.skip=true"

# Install Shared 
checkout_and_build_repo_branch "ssdc-shared-sample-validation" $BRANCH_NAME "${MVN_INSTALL_TEST_CMD}" "${MVN_INSTALL_ONLY_CMD}"

# Install DDL
checkout_and_build_repo_branch "ssdc-rm-ddl" $BRANCH_NAME "make dev-build" "make dev-build"

# Case Processor
checkout_and_build_repo_branch "ssdc-rm-caseprocessor" $BRANCH_NAME "make build" "make build_no_test"

# Case API
checkout_and_build_repo_branch "ssdc-rm-case-api" $BRANCH_NAME "make build" "make build_no_test"

# Notify Service
checkout_and_build_repo_branch "ssdc-rm-notify-service" $BRANCH_NAME "make build" "make build_no_test"

# Export File Service
checkout_and_build_repo_branch "ssdc-rm-print-file-service" $BRANCH_NAME "make build_and_test" "make docker_build" # TODO update repo name

# Support Tool
checkout_and_build_repo_branch "ssdc-rm-support-tool" $BRANCH_NAME "make build" "make build_no_test"

# ROPS
checkout_and_build_repo_branch "ssdc-rm-response-operations" $BRANCH_NAME "make build" "make build_no_test"

#Qid Service
checkout_and_build_repo_branch "ssdc-rm-uac-qid-service" $BRANCH_NAME "${MVN_INSTALL_TEST_CMD}" "${MVN_INSTALL_ONLY_CMD}"

#Exception Manger
checkout_and_build_repo_branch "ssdc-rm-exception-manager" $BRANCH_NAME "${MVN_INSTALL_TEST_CMD}" "${MVN_INSTALL_ONLY_CMD}"

########################################################################################################################
#  Set up Docker Dev
########################################################################################################################
cd $DOCKER_DEV_DIR
execute_and_record_command "make up" true

########################################################################################################################
#  Acceptance Tests
########################################################################################################################
cd $BRANCH_PR_DIR
checkout_repo_branch "ssdc-rm-acceptance-tests" $BRANCH_NAME_TO_CHECKOUT
execute_and_record_command "pipenv install --dev" true

if [ "$SKIP_TESTS" = true ]
then
    echo "Skipping ATs"
else
    echo "Sleeping to allow for docker containers to be running ${PRE_AT_SLEEP} seconds"
    wait_until_containers_are_running_or_timeout
    # sleep $PRE_AT_SLEEP
    execute_and_record_command "make test" true
fi

popd

########################################################################################################################
# Output Record
########################################################################################################################

echo -e "\n\n"
echo -e $REPO_CMD_HISTORY
echo -e "\n\n"

########################################################################################################################
# Output runtime
########################################################################################################################
printf 'Total Runtime %dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
