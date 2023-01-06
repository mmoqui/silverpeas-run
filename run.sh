#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

image_version=latest
name="silverpeas-${image_version}"
port=8000
debug=5005
cmd=""
opts="-d"
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h)
      echo "Usage: run.sh -d DATABASE [-n NETWORK] [-p PORT] [-j DEBUGING_PORT]"
      echo "              [-i IMAGE_VERSION] [-m NAME] [-c CMD]"
      echo
      echo "Spawns and runs a Docker container in the background from the Docker image"
      echo "silverpeas-run IMAGE_VERSION. In order to update Silverpeas in the Docker"
      echo "container with the code in development, the .m2/repository directory in the host"
      echo "is mounted in the container. The data of Silverpeas is also mounted on the host"
      echo "as a Docker volume named silverpeas-data-NAME so it can be reused later by a new"
      echo "silverpeas-run container."
      echo "Once running, you can connect to the container by running the following command:"
      echo "$ docker exec -u silveruser -it NAME /bin/bash"
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
      echo "   -m NAME            A name to give to the container."
      echo "                      Default is silverpeas-IMAGE_VERSION."
      echo "   -c CMD             Command to pass to the container instead of the default"
      echo "                      one. If passed, the stdin and the stdout are linked with"
      echo "                      the host."
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
    -m)
      name="$2"
      shift # past argument
      shift # past value
      ;;
    -c)
      cmd="$2"
      opts="-it -u silveruser"
      shift # past argument
      shift # past value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

test "Z$database" = "Z" && die "The name of the docker container or service for the database must be set"

docker run ${opts} ${network} -p ${port}:8000 -p ${debug}:5005 \
  -v "$HOME"/.m2/repository:/home/silveruser/.m2/repository \
  -v silverpeas-data-${name}:/home/silveruser/silverpeas/data \
  --link ${database}:database \
  --name ${name} \
  silverpeas-run:${image_version} ${cmd}
