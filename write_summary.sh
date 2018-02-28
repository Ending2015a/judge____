#!/bin/bash

ROOT_FOLDER="./result"
FILE_PREFIX="result"

if [ ! -e "./summary" ]; then
    make summary
fi

FILE_LIST=($(ls -- ${ROOT_FOLDER}/${FILE_PREFIX}_*.json))

./summary "${FILE_LIST[@]}"
