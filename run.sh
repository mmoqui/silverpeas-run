#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

image_version=latest
name="silverpeas-${image_version}"
port=8000
debug=5005
mount=""
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      echo "Usage: run.sh -d DATABASE [-n NETWORK] [-p PORT] [-j DEBUGING_PORT]"
      echo "              [-i IMAGE_VERSION] [-c NAME] [-m HOST_DIR]"
      echo
      echo "Spawns and runs a Docker container from the Docker image silverpeas-run"
      echo "IMAGE_VERSION. Once started, you are directly connected into the container so"
      echo "you can performe some customization before running Silverpeas."
      echo
      echo "In order to update Silverpeas in the Docker container with the code in"
      echo "development, the .m2/repository directory of the host is mounted on the"
      echo "container. The data of Silverpeas is also mounted on the host as a Docker volume"
      echo "named silverpeas-data-NAME so it can be reused later by a new silverpeas-run"
      echo "container."
      echo
      echo "with:"
      echo "   -n NETWORK         The name of the Docker network on which the container has"
      echo "                      to run."
      echo "                      Default is the default network of Docker (bridge)."
      echo "   -p PORT            The port at which Silverpeas will listen in the host."
      echo "                      Default is 8000."
      echo "   -d DATABASE        The name of the Docker container with the running database"
      echo "                      to use."
      echo "   -j DEBUGING_PORT   The JVM debugging port to map in the host."
      echo "                      Default is 5005."
      echo "   -i IMAGE_VERSION   The version of the Docker image to instantiate."
      echo "                      Default is latest."
      echo "   -c NAME            A name to give to the container."
      echo "                      Default is silverpeas-IMAGE_VERSION."
      echo "   -m HOST_DIR        Mount the /home/silveruser/webapp (where is deployed"
      echo "                      Silverpeas) on the directory HOST_DIR of the host."
      exit 0
      ;;
    -n)
      network="--net=$2"
      shift # past argument
      shift # past value
      ;;
    -p)
      port=$2
      shift # past argument
      shift # past value
      ;;
    -d)
      database=$2
      shift # past argument
      shift # past value
      ;;
    -j)
      debug=$2
      shift # pass argument
      shift # pass value
      ;;
    -i)
      image_version="$2"
      shift # past argument
      shift # past value
      ;;
    -c)
      name="$2"
      shift # past argument
      shift # past value
      ;;
    -m)
      mount="-v $2:/home/silveruser/webapp"
      shift # past argument
      shift # past value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

test "Z$database" = "Z" && die "The name of the docker container or service for the database must be set"

docker run -it -u silveruser ${network} -p ${port}:8000 -p ${debug}:5005 ${mount} \
  -v "$HOME"/.m2/repository:/home/silveruser/.m2/repository \
  -v silverpeas-data-${name}:/home/silveruser/silverpeas/data \
  --link ${database}:database \
  --name ${name} \
  silverpeas-run:${image_version} /bin/bash
