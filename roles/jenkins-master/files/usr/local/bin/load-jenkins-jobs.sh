#!/bin/bash

set -ex

JJB_CONFIG=$1
JOBS_PATH=$2
JJB_ACTION=${3:-"update"}

if [ -d "${JOBS_PATH}" ]; then
    cd ${JOBS_PATH}
    if [[ "${JJB_ACTION}" == "update" ]]; then
        jenkins-jobs --conf ${JJB_CONFIG} update --delete-old .
    elif [[ "${JJB_ACTION}" == "test" ]]; then
        jenkins-jobs --conf ${JJB_CONFIG} test .
    else
        echo Action not supported
        exit 1
    fi
fi
