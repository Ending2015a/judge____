#!/bin/bash
start=`date +%s.%N`
srun -p batch $*
res=$?
end=`date +%s.%N`
TIME=`echo "$end - $start" | bc | awk -F"." '{print $1"."substr($2,1,6)}'`
echo "TIME:{$TIME}"
exit $res
