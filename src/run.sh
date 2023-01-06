#!/usr/bin/env bash
set -e

#
# Initialization script that wraps the installation, starting and stopping
# of Silverpeas
#

install_silverpeas() {
  echo "Install Silverpeas from actual code..."
  if ! ./silverpeas clean install; then
    echo "While while updating Silverpeas!"
    exit 1
  fi
}

start_silverpeas() {
  echo "Start Silverpeas..."
  exec "${JBOSS_HOME}"/bin/standalone.sh -b 0.0.0.0 -c standalone-full.xml --debug 5005
}

stop_silverpeas() {
  echo "Stop Silverpeas..."
  ./silverpeas stop
  local pids
  pids=$(jobs -p)
  if [ "Z$pids" != "Z" ]; then
    kill "$pids" &> /dev/null
  fi
}

trap 'stop_silverpeas' SIGTERM

install_silverpeas
start_silverpeas
