#!/usr/bin/env bash

set -e
set -o pipefail

function ask-y-n() {
  echo ${1}

  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function spinner() {
  while read line; do
    echo -n "." >&2
  done

  echo >&2
}

function error() {
  echo -e ${@} >&2
  exit 1
}

function run-command() {
  echo -n "Running '${@}' "

  # grab a temp file
  temp=$(mktemp)

  # capture the output and show the 'spinner'
  if ! ${@} 2>&1 | tee ${temp} | spinner; then
    error "Command failed, here's the output:\n$(cat ${temp})"
  fi
}

function get-version {
  proc_string=$( cat /proc/version )
  declare -A versions=(
    [Ubuntu]=ubuntu
  )
  
  for k in "${!versions[@]}"; do
    if echo "${proc_string}" | grep "${k}" >/dev/null; then
      echo ${versions["${k}"]}
      return 0
    fi
  done

  error "Failed to determin your sytem type. Head back to http://apiaxle.com for support."
}

function is-correct-node {
  # is there a node?
  if ! which node >/dev/null; then
    return 1
  fi

  # explicitly check for the right node
  node_version=$(node --version)
  for valid in "v0.8." "v0.10."; do
    if echo "${node_version}" | grep "${valid}" >/dev/null; then
      return 0
    fi
  done

  return 1
}

function ubuntu {
  run-command sudo apt-get install \
        python-software-properties \
        build-essential \
        libxml2-dev

  if ! is-correct-node; then
    if ask-y-n "Would you like me to upgrade node from ppa:chris-lea/node.js?"; then
      run-command sudo add-apt-repository -y ppa:chris-lea/node.js
      run-command sudo apt-get -y update
      run-command sudo apt-get -y install nodejs
    else
      error "Wrong node version."
    fi
  fi

  run-command sudo apt-get -y install redis-server
}

function install-axle {
  run-command npm install -g \
    apiaxle-repl \
    apiaxle-proxy \
    apiaxle-api
}

# run the function with the name of the detected OS
$(get-version)
