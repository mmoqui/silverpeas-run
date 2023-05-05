#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

function checkNotEmpty() {
  test "Z$1" != "Z" || die "Parameter is empty"
}

version=0
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      userid=`grep -o "USER_ID=[0-9]\+" Dockerfile | cut -d '=' -f 2`
      groupid=`grep -o "GROUP_ID=[0-9]\+" Dockerfile | cut -d '=' -f 2`
      wildfly=`grep -o "WILDFLY_VERSION=[a-zA-Z0-9.-]\+" Dockerfile | cut -d '=' -f 2`
      silverpeas=`grep -o "SILVERPEAS_VERSION=[a-zA-Z0-9.-]\+" Dockerfile | cut -d '=' -f 2`
      java=`grep -o "JAVA_VERSION=[0-9]\+" Dockerfile | cut -d '=' -f 2`
      echo "Usage: build.sh [-u USER_ID] [-g GROUP_ID] [-w WILDFLY_VERSION]"
      echo "                [-s SILVERPEAS_VERSION] [-j JAVA_VERSION] [-v IMAGE_VERSION]"
      echo 
      echo "Build a Docker image with a given version of Silverpeas and wildfly initialized"
      echo "with a set of data for functional testing purpose."
      echo
      echo "With:"
      echo "   -u USER_ID  set the user identifier as USER_ID."
      echo "               It should be your own user identifier in the host to share the"
      echo "               local Maven repository with the containers."
      echo "               By default ${userid}."
      echo "   -g GROUP_ID set the group identifier as GROUP_ID."
      echo "               It should be your own main group identifier in the host to share"
      echo "               the local Maven repository with the containers."
      echo "               By default ${groupid}."
      echo "   -w WILDFLY_VERSION"
      echo "               set the version of the Widfly distribution to use."
      echo "               By default ${wildfly}"
      echo "   -s SILVERPEAS_VERSION"
      echo "               set the version of the Silverpeas distribution to run."
      echo "               By default ${silverpeas}"
      echo "   -j JAVA_VERSION"
      echo "               set the version of the JDK to use for running Silverpeas."
      echo "               By default ${java}"
      echo "   -v IMAGE_VERSION"
      echo "               set the version of the Docker image to build."
      echo "               By default latest."
      exit 0
      ;;
    -u)
      user="--build-arg USER_ID=$2"
      shift # past argument
      shift # past value
      ;;
    -g)
      group="--build-arg GROUP_ID=$2"
      shift # past argument
      shift # past value
      ;;
    -w)
      checkNotEmpty "$2"
      wildfly_version="--build-arg WILDFLY_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    -s)
      checkNotEmpty "$2"
      silverpeas_version="--build-arg SILVERPEAS_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    -v)
      checkNotEmpty "$2"
      image_version="$2"
      version=1
      shift # past argument
      shift # past first value
      ;;
    -j)
      checkNotEmpty "$2"
      java_version="--build-arg JAVA_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

# build the Docker image for building some of the Silverpeas projects
if [[ ${version} -eq 1 ]]; then
  docker build ${user} ${group} ${wildfly_version} ${java_version} ${silverpeas_version} \
    -t silverpeas-run:${image_version} \
    .
else
  docker build ${user} ${group} ${wildfly_version} ${java_version} ${silverpeas_version} \
    -t silverpeas-run:latest \
    .
fi


