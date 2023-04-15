#!/bin/bash

# ##################################################
# NOTE - in non-GitHub environment, to work with the env vars exported herein from other files, remember to dot-source this file at the prompt!
# . ./env-vars.sh
# ##################################################

setEnvVar() {
  # Set an env var's value at runtime with dynamic variable name
  # If in GitHub Actions runner, will export env var both to Actions and local shell
  # Usage:
  # setEnvVar "variableName" "variableValue"

  varName=$1
  varValue=$2

  if [[ ! -z $GITHUB_ACTIONS ]]
  then
    # We are in GitHub CI environment - export to GitHub Actions workflow context for availability in later tasks in this workflow
    cmd=$(echo -e "echo \x22""$varName""=""$varValue""\x22 \x3E\x3E \x24GITHUB_ENV")
    eval $cmd
  else
    # Export for local/immediate use
    cmd="export ""$varName""=\"""$varValue""\""
    eval $cmd
  fi
}
