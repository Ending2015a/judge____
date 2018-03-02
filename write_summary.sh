#!/bin/bash

ROOT_FOLDER="./result"
FILE_PREFIX="result"

READ_JSON_FORMAT=1
#READ_CSV_FORMAT=1


function parse_json
{
    echo "json format"
    if [ ! -e "./json_summary" ]; then
        make json_summary
    fi

    FILE_LIST=($(ls -- ${ROOT_FOLDER}/${FILE_PREFIX}_*.json))

    ./json_summary "${FILE_LIST[@]}"
}

function parse_csv
{
    echo "csv format"
    FILE_LIST=($(ls -- ${ROOT_FOLDER}/${FILE_PREFIX}_*.csv))

    cat ${FILE_LIST[@]} > result.csv
}


if [ $READ_JSON_FORMAT -eq 1 ]; then
    parse_json
elif [ $READ_CSV_FORMAT -eq 1 ]; then
    parse_csv
else
    echo -e "[\033[91mERROR\033[0m] please select one format"
    exit 1
fi
