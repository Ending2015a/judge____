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

# $case $round $perfect $good $miss $grade $time $error $err_message
function append_json
{
    # append json object

    USER_RESULT="$USER_RESULT    {"
    USER_RESULT="$USER_RESULT        \"case\": $1,"         # unsigned int field
    USER_RESULT="$USER_RESULT        \"round\": $2,"        # unsigned int field
    USER_RESULT="$USER_RESULT        \"perfect\": $3,"      # unsigned int field
    USER_RESULT="$USER_RESULT        \"good\": $4,"         # unsigned int field
    USER_RESULT="$USER_RESULT        \"miss\": $5,"         # unsigned int field
    USER_RESULT="$USER_RESULT        \"grade\": \"$6\","    # string field
    USER_RESULT="$USER_RESULT        \"time\": \"$7\","     # string field
    USER_RESULT="$USER_RESULT        \"error\": $8,"        # unsigned int field
    USER_RESULT="$USER_RESULT        \"error_msg\": \"$9\"" # string field
    USER_RESULT="$USER_RESULT    },"
}

# $user
function begin_json
{
    user=$1

    echo "{ \"user\": \"$user\", \"data\": ["
}

# $json
function end_json
{
    j=$1
    echo "$j" | sed -e "s/\,$//g"
    echo "]}"
}

# $template $fieldname
function get_field
{
    field=$(echo "$1" | grep -Po "(?<=${2}:{)[^\}]*(?=})")
    if [ $? -ne 0 ]; then
        echo "0"
    else
        echo "$field"
    fi
}

# $user $user_folder $testcase $round
function judge_case
{
    # pass args
    user=$1
    user_folder=$2
    testcase=$3
    round=$4

    # output file name (eg. case00_00.png)
    output="case$(printf "%02d" $testcase)_$(printf "%02d" $round).png"
    # caomparison result path = working folder + comp_output filename
    comp_path="$user_folder/comp_$output"
    # output path = working folder + output file name
    output_path="$user_folder/$output"
    # target path = user working folder + executable target 
    target_path="$user_folder/$TARGET_EXE"
    # answer_path = answer directory + case
    answer_path="${ANSWER_DIRECTORY%/}/case$(printf "%02d" $testcase).png"

    # check if output_path already existed -> delete
    if [ -e $output_path ]; then
        log "output path exist, removing: $output_path"
        rm $output_path
    fi

    # check if executable target existed
    if [ ! -e $target_path ]; then
        log -e "target path not exist: $target_path"
        append_json $user $testcase $round 252 0 "target not found"
        return -1
    fi

    # get slrum system config (-N -n -c ~~)
    config=$(echo "${PARAMS[$testcase]}" | grep -Po ".*(?=TARGET)")
    # concat command
    command=$(replace "${PARAMS[$testcase]}" "TARGET" "$target_path")
    command=$(replace "$command" "OUTPUT" "$output_path")
    log "config: $config"
    log "execute: $command"
    # srun, get output message
    out=$(salloc -p batch $config ./run.sh ${command} 2>&1)
    # get exit code
    res=$?
    # get execution time
    exe_time=$(get_field "$out" "TIME")
    #exe_time=$(echo "$out" | grep -Po "(?<=TIME:{)[0-9]*\.?[0-9]*()")

    log "complete in ${exe_time} sec"

    # check if exit code = 0, else ERROR
    if [ $res -ne 0 ]; then
        log -e "got exit code $res when execute user's program, Case $testcase, Round: $round"
        log -e "   error: $out"
        append_json $testcase $round 0 0 0 "X" $exe_time $res "program error"
        return -1
    fi
    
    log "execute: md_diff $output_path $answer_path $comp_path"
    out=$(./md_diff $output_path $answer_path $comp_path 2>&1)
    log "md_diff: $out"
    res=$?

    # get grade
    perfect=$(get_field "$out" "PERFECT")
    good=$(get_field "$out" "GOOD")
    miss=$(get_field "$out" "MISS")
    grade=$(get_field "$out" "GRADE")

    error_msg=""
    if [ $res -ne 0 ]; then
        log -e "got exit code $res when execute md_diff, Case: $i, Round: $4"
        log -e "  error msg: $out"
        grade="X"
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

    log "append_json: $testcase $round $perfect $good $miss $grade $exe_time $res $error_msg"
    append_json $testcase $round $perfect $good $miss $grade $exe_time $res $error_msg

}


# start from here
for DIR in $FOLDER_LIST ; do
    # get user working directory
    USER_FOLDER=${DIR%/}
    # get user name
    USER=$(echo $USER_FOLDER| awk -F"_" '{print $2}')

    # get user log file path
    USER_LOG_FILE=$(replace $LOG_FILE "USER" "$USER")
    # get user result file path
    USER_RESULT_FILE=$(replace $RESULT_FILE "USER" "$USER")

    # print log
    log "Judging user: $USER"
    # make file
    make --no-print-directory -C $DIR

    # json array begin
    USER_RESULT=$(begin_json $USER)

    # testing (for each round)
    for ((r=0;r<$TEST_TIMES;++r)); do
        # print log
        log "Judging user: $USER, round $r"
        # (for each case)
        for ((c=0;c<${#PARAMS[@]};++c)); do
            # judge
            judge_case $USER $USER_FOLDER $c $r
        done
    done

    # cat multiple lines to single line
    USER_RESULT=$(echo "${USER_RESULT[*]}")

    # json array end (redirect to user's result file)
    echo "$(end_json $USER_RESULT)" | python -m json.tool > $USER_RESULT_FILE
    
    #echo "$USER_RESULT" | sed -e "s/\,$/\]/g" | python -m json.tool > $USER_RESULT_FILE
    
    # make clean
    make --no-print-directory -C $DIR clean
done
