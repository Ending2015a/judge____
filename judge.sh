#!/bin/bash
ANSWER_DIRECTORY="./answer/"
PARAMS=("-N 4 -n 4 -c 12 TARGET 12 1.835201 0.561417 -0.521397 0 0 0 1280 720 OUTPUT"\
        "-N 4 -n 4 -c 12 TARGET 12 -0.368765 0.927989 -0.630531 0 0 0 1280 720 OUTPUT"\
        "-N 4 -n 4 -c 12 TARGET 12 -1.278121 0.168838 -0.160314 0 0 0 1280 720 OUTPUT")

ROOT_FOLDER="./list"
TARGET_EXE="md_pal"
FOLDER_PREFIX="hw2"
TEST_TIMES=3

LOG_FOLDER="./log"
LOG_FILE="$LOG_FOLDER/judge_USER.log"
RESULT_FOLDER="./result"
RESULT_FILE="$RESULT_FOLDER/result_USER"

# you can choose use which format
OUTPUT_AS_JSON_FORMAT=1
#OUTPUT_AS_CSV_FORMAT=1

# debug
OUTPUT_APPEND_RESULT_LOG=1

# define color
ERROR_COLOR="\033[91m"
LOG_COLOR="\033[32m"
USER_COLOR="\033[33m"
ERRCODE_COLOR="\033[96m"
ERRMSG_COLOR="\033[37m"
PATH_COLOR="\033[95m"
HIGHLIGHT_COLOR="\033[93m"
TIME_COLOR="\033[95m"
NM="\033[0m"

# log log [-e] $msg
function log
{
    flag="[${LOG_COLOR}LOG${NM}]"
    if [ "$1" = "-e" ]; then
        flag="[${ERROR_COLOR}ERROR${NM}]"
        shift
    fi

    echo -e "$flag $1"
    DATE=`date '+%Y-%m-%d %H:%M:%S'`
    msg=$(echo -e "$flag / $DATE / $1" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
    echo "$msg" >> $USER_LOG_FILE
}

# text replacement function
# replace $A to $B
# args: $template $A $B
function replace
{
    echo "${1/$2/$3}"
}

# $user
function begin_result
{
    if [ $OUTPUT_AS_JSON_FORMAT -eq 1 ]; then
        echo "{ \"user\": \"$1\", \"data\": ["
    elif [ $OUTPUT_AS_CSV_FORMAT -eq 1 ]; then
        echo "$1"
    else
        echo -e "[${ERROR_COLOR}ERROR${NM}] Please select one output format!!"
        exit 1
    fi
}

# $case $round $perfect $good $miss $grade $time $error $err_message
function append_result
{

    if [ $OUTPUT_APPEND_RESULT_LOG -eq 1 ]; then
        log "append_result: $*"
    fi

    if [ $OUTPUT_AS_JSON_FORMAT -eq 1 ]; then
        # append json object
        USER_RESULT="$USER_RESULT    {"
        USER_RESULT="$USER_RESULT        \"case\": $1,"         # unsigned int field
        USER_RESULT="$USER_RESULT        \"round\": $2,"        # unsigned int field
        USER_RESULT="$USER_RESULT        \"perfect\": \"$3\","  # string field
        USER_RESULT="$USER_RESULT        \"good\": \"$4\","     # string field
        USER_RESULT="$USER_RESULT        \"miss\": \"$5\","     # string field
        USER_RESULT="$USER_RESULT        \"grade\": \"$6\","    # string field
        USER_RESULT="$USER_RESULT        \"time\": \"$7\","     # string field
        USER_RESULT="$USER_RESULT        \"error\": $8,"        # unsigned int field
        USER_RESULT="$USER_RESULT        \"error_msg\": \"$9\"" # string field
        USER_RESULT="$USER_RESULT    },"
    elif [ $OUTPUT_AS_CSV_FORMAT -eq 1 ]; then
        USER_RESULT="$USER_RESULT, $3, $4, $5, $6, $7, $8, $9"
    else
        echo -e "[${ERROR_COLOR}ERROR${NM}] Please select one output format!!"
        exit 1
    fi

}

# $result $remark
function end_result
{
    if [ $OUTPUT_AS_JSON_FORMAT -eq 1 ]; then
        echo "$1" | sed -e "s/\,$//g"
        echo "], \"remark\": \"$2\" }"
    elif [ $OUTPUT_AS_CSV_FORMAT -eq 1 ]; then
        echo "$1, $2"
    else
        echo -e "[${ERROR_COLOR}ERROR${NM}] Please select one output format!!"
        exit 1
    fi
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
        log "output path exists, removing: ${PATH_COLOR}$output_path${NM}"
        rm $output_path
    fi

    # check if executable target existed
    if [ ! -e $target_path ]; then
        log -e "target path not exists: ${PATH_COLOR}$target_path${NM}"
        append_result $testcase $round "inf" "inf" "inf" "X" "inf" 252 "target not found"
        return 1
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

    log "complete in ${TIME_COLOR}${exe_time}${NM} sec"

    # check if exit code = 0, else ERROR
    if [ $res -ne 0 ]; then
        log -e "get exit code ${ERRCODE_COLOR}$res${NM} when execute user's program"
        log -e "   error message: ${ERRMSG_COLOR}$out${NM}"
        append_result $testcase $round "inf" "inf" "inf" "X" "inf" "$res" "user program error"
        return 1
    fi
    
    # check if user's output image exist
    if [ ! -e "$output_path" ]; then
        log -e "cannot find output file: ${PATH_COLOR}$output_path${NM}"
        append_result $testcase $round "inf" "inf" "inf" "X" "inf" "255" "output not found"
        return 1
    fi

    log "execute: md_diff $output_path $answer_path $comp_path"
    out=$(./md_diff $output_path $answer_path $comp_path 2>&1)
    res=$?

    # get grade
    perfect=$(get_field "$out" "PERFECT")
    good=$(get_field "$out" "GOOD")
    miss=$(get_field "$out" "MISS")
    grade=$(get_field "$out" "GRADE")

    error_msg=""
    if [ $res -ne 0 ]; then
        log -e "got exit code ${ERRCODE_COLOR}$res${NM} when execute md_diff"
        log -e "  error message: ${ERRMSG_COLOR}$out${NM}"
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

    if [ $grade = "X" ] || [ $grade = "F" ] || [ $grade = "C" ]; then
        exe_time="inf"
    fi

    append_result $testcase $round $perfect $good $miss "$grade" "$exe_time" "$res" "$error_msg"

}

# judge one user $user_directory
function judge_user
{
    # get user working directory
    USER_FOLDER=${1%/}
    # get user name
    USER=$(echo $USER_FOLDER| awk -F"_" '{print $2}')

    # get user log file path
    USER_LOG_FILE=$(replace $LOG_FILE "USER" "$USER")
    # get user result file path
    USER_RESULT_FILE=$(replace $RESULT_FILE "USER" "$USER")

    USER_REMARK=""

    # print log
    log "Judging user: ${USER_COLOR}$USER${NM}"

    # check for makefile existance
    if [ ! -e "$USER_FOLDER/Makefile" ]; then
        log -e "No makefile found"
        USER_REMARK="No makefile found"
    fi

    # make file
    make --no-print-directory -C $USER_FOLDER

    # json begin
    USER_RESULT=$(begin_result $USER)

    # testing (for each round)
    for ((r=0;r<$TEST_TIMES;++r)); do
        # (for each case)
        for ((c=0;c<${#PARAMS[@]};++c)); do
            # print log
            log "Judging user: ${USER_COLOR}$USER${NM}, ${HIGHLIGHT_COLOR}round $r, case $c${NM}"
            # judge
            judge_case $USER $USER_FOLDER $c $r
        done
    done

    # cat multiple lines to single line
    USER_RESULT=$(end_result "${USER_RESULT[*]}" "${USER_REMARK}")

    # json end (redirect to user's result file)
    if [ $OUTPUT_AS_JSON_FORMAT -eq 1 ]; then
        echo "${USER_RESULT[*]}" | python -m json.tool > ${USER_RESULT_FILE}.json
    elif [ $OUTPUT_AS_CSV_FORMAT -eq 1 ]; then
        echo "${USER_RESULT[*]}" > ${USER_RESULT_FILE}.csv
    else
         echo -e "[${ERROR_COLOR}ERROR${NM}] Please select one output format!!"
        exit 1
    fi
    
    # make clean
    make --no-print-directory -C $USER_FOLDER clean
}

# judge all user
function judge_all
{
    # get user folder list
    FOLDER_LIST=`ls -d -- ${ROOT_FOLDER}/${FOLDER_PREFIX}_*/`
    
    for DIR in $FOLDER_LIST ; do
        judge_user $DIR
        echo ""
    done       
}

function usage
{
    echo "usage: [-c] [-a root] [-u user_directory]"
    echo "  -a        judge all user under specified root directory"
    echo "  -u        judge one user under specified directory"
    echo "  -c        clear logs, results"
}


JUDGE_ALL=1



while getopts "ca:u:" OPTION; do
    case $OPTION in
        a)  # judge all (default)
            JUDGE_ALL=1
            directory=$OPTARG
            if [ "$directory" = "" ]; then
                echo -e "Invalid root folder: ${PATH_COLOR}$directory${NM}"
                exit 1
            fi
            ROOT_FOLDER=$directory
            ;;
        u)  # judge user (folder path)
            JUDGE_ALL=0
            directory=$OPTARG
            if [ "$directory" = "" ]; then
                echo -e "Invalid user folder: ${PATH_COLOR}$directory${NM}"
            fi
            USER_FOLDER=$directory
            ;;
        c)  # clear
            set -x
            rm -rf $LOG_FOLDER
            rm -rf $RESULT_FOLDER
            set +x
            exit
            ;;
        *)  # print usage
            usage
            exit
            ;;
    esac
done

# check root folder existance
if [ ! -d "$ROOT_FOLDER" ]; then
    echo -e "Cannot find root: ${PATH_COLOR}$ROOT_FOLDER${NM}"
    exit 1
fi

# check log folder
if [ ! -d "$LOG_FOLDER" ]; then
    echo -e "Create log folder: ${PATH_COLOR}$LOG_FOLDER${NM}"
    mkdir $LOG_FOLDER
fi

# check result folder
if [ ! -d "$RESULT_FOLDER" ]; then
    echo -e "Create result folder: ${PATH_COLOR}$RESULT_FOLDER${NM}"
    mkdir $RESULT_FOLDER
fi

# judge
if [ $JUDGE_ALL -eq 1 ]; then
    if [ ! -d "$ROOT_FOLDER" ]; then
        echo -e "Root folder ${PATH_COLOR}\"$ROOT_FOLDER\"${NM} not exist"
        exit 1
    fi

    judge_all
else
    if [ ! -d "$USER_FOLDER" ]; then
        echo -e "User folder ${PATH_COLOR}\"$USER_FOLDER\"${NM} not exist"
        exit 1
    fi
    judge_user $USER_FOLDER
fi

