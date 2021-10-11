#!/usr/bin/python3
import os
import subprocess
from pathlib import Path
import time
from subprocess import call

# Order is important, it will run these and their build commands in order
repos = [
    # {
    #     "name": "ssdc-rm-ddl",
    #     "ssh_clone": "git@github.com:ONSdigital/ssdc-rm-ddl.git",
    #     "build_commands": ["make dev-build"]
    #     "sleep": 0
    # },
    # {
    #     "name": "ssdc-rm-case-api",
    #     "ssh_clone": "git@github.com:ONSdigital/ssdc-rm-case-api.git",
    #     "build_commands": ["mvn clean install"]
    #       "sleep": 0
    # },
    # {
    #     "name": "ssdc-rm-print-file-service",
    #     "ssh_clone": "git@github.com:ONSdigital/ssdc-rm-print-file-service.git",
    #     "build_commands": ["make install", "make test"],
    #     "sleep": 0
    # },
    # {
    #     "name": "ssdc-rm-docker-dev",
    #     "ssh_clone": "git@github.com:ONSdigital/ssdc-rm-docker-dev.git",
    #     "build_commands": ["make up"],
    #     "sleep": 0,
    #     "os": []
    # },
    {
        "name": "ssdc-rm-acceptance-tests",
        "ssh_clone": "git@github.com:ONSdigital/ssdc-rm-acceptance-tests.git",
        "build_commands": ["make install"],
        "sleep": 60,
        "os": ["make test"]
    },
]


def checkout_and_build_repo(repo, branch_name):
    print("Checking out Repo: ", repo["name"])
    git_clone_cmd = "git clone " + repo["ssh_clone"]
    print("Running: ", git_clone_cmd)

    subprocess.run(git_clone_cmd, shell=True, check=True)

    new_dir = os.getcwd() + "/" + repo["name"]
    os.chdir(new_dir)

    checkout_branch_cmd = "git checkout " + branch_name
    print("For repo: " + repo["name"] + " Attempting to checkout branch: " + branch_name)

    # If this fails we just want to pull the image?  Save time on building it?
    # Also we always want the real main/prod image, not our potentially locally built one
    # Also record the 'failed to checkout and print this out at the end, along with successes?
    # Why? so the user can compare to what they expect?
    subprocess.run(checkout_branch_cmd, shell=True)

    # really struggling with ATs to wait until it's all ready?  some docker isms?
    # docker ps | grep caseprocessor?
    # docker ps | grep "starting" until it returns nothing?


    for build_cmd in repo["build_commands"]:
        subprocess.run(build_cmd, shell=True, check=True)
        # subprocess.run(build_cmd, shell=True)

    # Hmmm  even with really big sleeps printfile stuff keeps failing??  fuck knows why too.
    time.sleep(repo["sleep"])

    # desparate attempt to make tests not SFTP fail?
    for os_cmd in repo["os"]:
        os.system(os_cmd)


def create_new_base_dir(branch_name):
    grandparent_dir = Path(os.getcwd()).parent.parent
    checkout_base_dir = str(grandparent_dir) + "/HACK_TEST_DIR/" + branch_name

    print("Making base_dir: ", checkout_base_dir)
    os.mkdir(checkout_base_dir)

    return checkout_base_dir


def checkout_branch(branch_name):
    kill_off_existing_docker()

    checkout_base_dir = create_new_base_dir(branch_name)

    print("Changing current working dir to: ", checkout_base_dir)
    os.chdir(checkout_base_dir)

    for repo in repos:
        # reset this each time
        os.chdir(checkout_base_dir)
        checkout_and_build_repo(repo, branch_name)


def kill_off_existing_docker():
    print("Cleaning up docker")
    subprocess.run('docker stop $(docker ps -aq)', shell=True)
    subprocess.run('docker rm $(docker ps -a -q)', shell=True)
    #     Also check docker images.  You don't want anything that isn't on the same as up to date in ssdc-rm-ci
    #     Don't want to blanket remove all the images though, re getting them takes blooming ages.


def test_running_printfilesvc():
    os.chdir("/Users/lozel/projects/ssdc/ssdc-rm-print-file-service")
    call(["make", "test"])

    subprocess.run("make test", shell=True, check=True)
    # subprocess.run("docker ps | grep sftp", shell=True, check=True)


if __name__ == '__main__':
    # args = parse_arguments()
    #
    test_running_printfilesvc()
    #
    #

    print("Enter the branch to checkout")

    branch_name = input()
    #     check not zero length,

    # # option now to skip tests
    # print('Skip application build tests Y/N?')
    # # make this a bool, fail if not Y/N etc
    # skip_build_tests = input()
    #
    #
    # print('Skip Acceptance tests')
    # # make this a bool, fail if not Y/N etc
    # skip_acceptance_tests = input()

    # Option to specify directory instead of ~/projects/ssdc/<branch_name>

    # Stop all current dockering?

    checkout_branch(branch_name)
