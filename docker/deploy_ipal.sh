#!/bin/bash

set -eb

# If you want to use your own fork, change the *_REPO variable.

IDS_DIR=ids
IDS_REPO=https://github.com/fkie-cad/ipal_ids_framework

TRANSCRIBER_DIR=transcriber
TRANSCRIBER_REPO=https://github.com/fkie-cad/ipal_transcriber

EVALUATE_DIR=evaluate
EVALUATE_REPO=https://github.com/fkie-cad/ipal_evaluate

INCLUDE_DATASETS=false
DATASETS_DIR=datasets
DATASETS_REPO=https://github.com/fkie-cad/ipal_datasets

TUTORIAL_DIR=../tutorial

IMAGE_NAME=ipal_combined
CONTAINER_NAME=ipal

bold=$(tput bold)
normal=$(tput sgr0)

cd "$(dirname "$0")"

function check_executable {
    local cmd=$1
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd executable cannot be found. Aborting."
        exit 1
    fi
}

check_executable "docker"
# TODO check if docker daemon is running

# Docker container already exists
if [ "$(docker ps -a | grep " $CONTAINER_NAME$")" ]
then
    # ask to use existing container
    echo "An IPAL container already exists."
    read -p "${bold}Do you want to use it? $normal(Y/n) " -n 1 -r
    if [[ $REPLY ]]; then echo; fi #print newline, if necessary
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "To start a new container, the old one has to be removed."
        read -p "${bold}Remove the existing container? $normal(Y/n) " -n 1 -r
        if [[ $REPLY ]]; then echo; fi #print newline, if necessary
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Well, in that case; You're on your own."
            exit 0
        else
            echo "Removing container."
            docker rm --force ipal
        fi
    else
        echo "Using existing container."
        # start container if not running
        if [ ! "$(docker ps | grep " $CONTAINER_NAME$")" ]
        then
            echo "Container is not running. Starting it now."
            docker start ipal
        fi
        
        # use container
        exec docker exec -it $CONTAINER_NAME //bin/bash
    fi
fi

check_executable "git"

function setup_repository {
    local directory=$1
    local url=$2
    local has_submodule=$3
    # check if repository already exist
    if [ -d "$directory" ]; then
        # false permissions are set if a directory is mounted before it exists
        # because the docker daemon (root) creates it
        # this shouldn't be an issue if this script was used

        # ask to update
        echo "The $directory directory already exists."
        read -p "${bold}Do you want to update it? $normal(y/N) " -n 1 -r
        if [[ $REPLY ]]; then echo; fi #print newline, if necessary
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd $directory && git pull && cd -
            if [ "$has_submodule" = true ]; then
                git submodule update
            fi
        fi
    else
        # ask to clone repo from default (no input) or custom source
        echo "${bold}Enter the $directory repository $normal(default: $url): "
        read -p "" -r
        if [ ! -z "$REPLY" ]; then
            local directory=$REPLY
        fi
        git clone $url $directory
        if [ "$has_submodule" = true ]; then
            git submodule init && git submodule update
        fi
        # XXX
        chmod -R 777 $directory
    fi
}

setup_repository $IDS_DIR $IDS_REPO
# remove tr if ARM
if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
    sed -i "" '/ "tr",/d' $IDS_DIR/setup.py
    sed -i "" '/tr /d' $IDS_DIR/requirements.txt
fi
setup_repository $TRANSCRIBER_DIR $TRANSCRIBER_REPO
setup_repository $EVALUATE_DIR $EVALUATE_REPO

if [ "$INCLUDE_DATASETS" = true ]; then
    setup_repository "datasets" $DATASETS_DIR $DATASETS_REPO true
fi

# Docker image already exists
if [ "$(docker images | grep "^$IMAGE_NAME ")" ]
then
    # ask to make a clean build of the image
    echo "Docker image already exists."
    read -p "${bold}Do you want to rebuild? $normal(y/N) " -n 1 -r
    if [[ $REPLY ]]; then echo; fi #print newline, if necessary
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x entry.sh
        # fix line endings on windows
        if [[ "$(uname)" == MINGW* ]]; then
            dos2unix entry.sh
        fi
        echo "Rebuilding image without cache."
        docker build --no-cache -t $IMAGE_NAME:latest .
    else
        echo "Using existing image."
    fi
else
    chmod +x entry.sh
    # fix line endings on windows
    if [[ "$(uname)" == MINGW* ]]; then
        dos2unix entry.sh
    fi
    docker build -t $IMAGE_NAME:latest .
fi

# fix paths for windows
if [[ "$(uname)" == MINGW* ]]; then
    MSYS_NO_PATHCONV=1 exec \
        docker run -it \
        -v "$(realpath -s ./$IDS_DIR)":/home/ipal/ids \
        -v "$(realpath -s ./$TRANSCRIBER_DIR)":/home/ipal/transcriber \
        -v "$(realpath -s ./$EVALUATE_DIR)":/home/ipal/evaluate \
        -v "$(realpath -s ./$TUTORIAL_DIR)":/home/ipal/tutorial_files \
        $(if [ "$INCLUDE_DATASETS" = true ]; then echo "-v "$(realpath -s ./$DATASETS_DIR)":/home/ipal/datasets"; fi) \
        --name $CONTAINER_NAME --hostname "ipal" $IMAGE_NAME:latest
else
    # cannot us realpath on mac
    exec \
        docker run -it \
        -v ./$IDS_DIR:/home/ipal/ids \
        -v ./$TRANSCRIBER_DIR:/home/ipal/transcriber \
        -v ./$EVALUATE_DIR:/home/ipal/evaluate \
        -v ./$TUTORIAL_DIR:/home/ipal/tutorial_files \
        $(if [ "$INCLUDE_DATASETS" = true ]; then echo "-v ./$DATASETS_DIR:/home/ipal/datasets"; fi) \
        --name $CONTAINER_NAME --hostname "ipal" $IMAGE_NAME:latest
fi
