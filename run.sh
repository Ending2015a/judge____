#!/bin/bash
ANSERT_DIRECTORY="/home/ipc/zexlus1126/test/testcase"
TOTAL_CASE=3
PARAMS=("1.835201 0.561417 -0.521397 0 0 0 1280 720"\
        "-0.368765 0.927989 -0.630531 0 0 0 1280 720"\
        "-1.278121 0.168838 -0.160314 0 0 0 1280 720")
DIRECTORY="./"
TARGET="./"
Node=4
Proc=4
Core=12

Case_start=0
Case_end=$TOTAL_CASE


# $exe $dir $i $Node $Proc $Core
function exe()
{
    OUTPUT="$2/output.png"
    set -x
    time srun -p batch -N $4 -n $5 -c $6 $1 $6 ${PARAMS[$3]} $OUTPUT
    set +x
}

function usage()
{ 
    echo "Usage: $0 [-e exe path] [-t testcase] [-d directory] [-N Node] [-n proccess] [-c core]"
    exit 1 
}

while getopts ":e:t:u:N:n:c:" flag; do
case $flag in
    e)
        TARGET=${OPTARG}
        if [ ! -f "$TARGET" ]; then
            echo -e "Target: $TARGET not exists"
            exit 2
        fi
        ;;
    t)
        ((Case = OPTARG))
        if [ ! $Case -lt $TOTAL_CASE ]; then
            echo -e "Case must less than $TOTAL_CASE, get: $Case"
            exit 1
        fi
        ((Case_start = Case))
        ((Case_end = Case + 1))
        ;;
    d)
        Dir=${OPTARG}
        if [ ! -d "$Dir" ]; then
            echo "Dir: $Dir Not exists"
            exit 1
        fi
        ;;
    N)
        Node=${OPTARG}
        ;;
    n)
        Proc=${OPTARG}
        ;;
    c)
        Core=${OPTARG}
        ;;
    *)
        usage
        ;;
esac
done

shift $((OPTIND-1))

echo "Case: $Case_start~$Case_end"
echo "Dir: $Dir"
echo "Node: $Node"
echo "Proc: $Proc"
echo "Core: $Core"

for ((i=Case_start;i<Case_end;++i)); do
    exe $Dir $i $Node $Proc $Core
done
