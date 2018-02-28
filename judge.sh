#!/bin/bash
ANSWER_DIRECTORY="./answer/"
PARAMS=("-N 4 -n 4 -c 12 TARGET 12 1.835201 0.561417 -0.521397 0 0 0 1280 720 OUTPUT"\
        "-N 4 -n 4 -c 12 TARGET 12 -0.368765 0.927989 -0.630531 0 0 0 1280 720 OUTPUT"\
        "-N 4 -n 4 -c 12 TARGET 12 -1.278121 0.168838 -0.160314 0 0 0 1280 720 OUTPUT")

ROOT_FOLDER="./list"
TARGET_EXE="md_pal"
FOLDER_PREFIX="hw2"
TEST_TIMES=1

LOG_FOLDER="./log"
LOG_FILE="$LOG_FOLDER/judge_USER.log"
RESULT_FOLDER="./result"
RESULT_FILE="$RESULT_FOLDER/result_USER.json"

# log log [-e] $msg
function log
{
    flag="LOG"
    if [ "$1" = "-e" ]; then
        flag="ERROR"
        shift
    fi

    echo -e $1
    msg=$(echo -e $1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
    DATE=`date '+%Y-%m-%d %H:%M:%S'`
    echo "[$flag] / $DATE / $msg" >> $USER_LOG_FILE
}


# check root folder existance
if [ ! -d "$ROOT_FOLDER" ]; then
    echo "Cannot find root: $ROOT_FOLDER"
    exit 1
fi

# check log folder
if [ ! -d "$LOG_FOLDER" ]; then
    echo "Create log folder: $LOG_FOLDER"
    mkdir $LOG_FOLDER
fi

# check result folder
if [ ! -d "$RESULT_FOLDER" ]; then
    echo "Create result folder: $RESULT_FOLDER"
    mkdir $RESULT_FOLDER
fi

# get user folder list
FOLDER_LIST=`ls -d -- ${ROOT_FOLDER}/${FOLDER_PREFIX}_*/`


# text replacement function
# replace $A to $B
# args: $template $A $B
function replace
{
    echo "${1/$2/$3}"
}

# $user $case $round $exit_code $spendtime $message
function append_json
{
    # append json object
    USER_RESULT=$USER_RESULT'{"user":'$1',"case":'$2',"round":'$3',"grade":'$4',"time":'$5',error_msg:'$6'},'
    
    #echo "    {"
    #echo "        \"user\": \"$1\","
    #echo "        \"case\": $2,"
    #echo "        \"round\": $3,"
    #echo "        \"grade\": $4,"
    #echo "        \"time\": $5,"
    #echo "        \"error_msg\": \"$6\""
    #echo "    }"
}

# $user $user_folder $testcase $round
function judge_case
{
    user=$1
    user_folder=$2
    testcase=$3
    round=$4

    output="case$(printf "%02d" $testcase)_$(printf "%02d" $round).png"
    comp_path="$user_folder/comp_$output"
    output_path="$user_folder/$output"
    target_path="$user_folder/$TARGET_EXE"
    answer_path="${ANSWER_DIRECTORY%/}/case$(printf "%02d" $testcase).png"

    if [ -e $output_path ]; then
        log "output path exist, removing: $output_path"
        rm $output_path
    fi

    if [ ! -e $target_path ]; then
        log -e "target path not exist: $target_path"
        append_json $user $testcase $round 252 0 "target not found"
        return -1
    fi

    # get slrum system config (-N -n -c ~~)
    config=$(echo "${PARAMS[$testcase]}" | grep -Po ".*(?=TARGET)")
    command=$(replace "${PARAMS[$testcase]}" "TARGET" "$target_path")
    command=$(replace "$command" "OUTPUT" "$output_path")
    log "config: $config"
    log "execute: $command"
    out=$(salloc -p batch $config ./run.sh ${command} 2>&1)
    res=$?
    exe_time=$(echo "$out" | grep -Po "(?<=TIME:)[0-9]*\.?[0-9]*")

    log "complete in ${exe_time} sec"

    if [ $res -ne 0 ]; then
        log -e "got exit code $res when execute user's program, Case $testcase, Round: $round"
        log -e "   error: $out"
        append_json $user $testcase $round $res $exe_time "program error"
        return -1
    fi
    
    log "execute: md_diff $output_path $answer_path $comp_path"
    out=$(./md_diff $output_path $answer_path $comp_path 2>&1)
    res=$?

    error_msg=""
    if [ $res -gt 5 ]; then
        log -e "got exit code $res when execute md_diff, Case: $i, Round: $4"
        log -e "  error msg: $out"
        case $res in
            255)
                error_msg="load image error: $output_path"
                ;;
            254)
                error_msg="load image error: $answer_path"
                ;;
            253)
                error_msg="image size not match"
                ;;
            *)
                error_msg="undefined error"
                ;;
        esac
    fi

    log "append_json: $user $testcase $round $res $exe_time $error_msg"
    append_json $user $testcase $round $res $exe_time $error_msg

}

for DIR in $FOLDER_LIST ; do
    USER_FOLDER=${DIR%/}
    USER=$(echo $USER_FOLDER| awk -F"_" '{print $2}')

    USER_LOG_FILE=$(replace $LOG_FILE "USER" "$USER")
    USER_RESULT_FILE=$(replace $RESULT_FILE "USER" "$USER")


    log "Judging user: $USER"
    make --no-print-directory -C $DIR

    # json array begin
    USER_RESULT="["

    for ((r=0;r<$TEST_TIMES;++r)); do
        log "Judging user: $USER, round $r"
        for ((c=0;c<${#PARAMS[@]};++c)); do
            judge_case $USER $USER_FOLDER $c $r
        done
    done

    # json array end
    USER_RESULT=$(echo "$USER_RESULT" | sed -e "s/\,$/\]/g") | python -m json.tool
    
    echo "$USER_RESULT" >> $USER_RESULT_FILE

    make --no-print-directory -C $DIR clean
done
