#!/bin/sh

thread_num=$1
run_time=$2
jmx_file=$3
jmeter_sh=/jmeter.sh

function help_check()
{
  echo "======================please follow it==================="
  echo "./runOnly.sh [thread_num] [run_time] [jmx_file]"
  echo "thread_num is thread num you want!"
  echo "run_time is the running time you want!"
  echo "jmx_file is the jmeter test case file you want!"
}

if [ -z "$thread_num"  ];then
   help_check
   exit 1
fi

if [ -z "$run_time"  ];then
   help_check
   exit 1
fi

if [ ! -f "$jmx_file"  ];then
   help_check
   exit 1
fi

if [ ! -f "$jmeter_sh" ];then
  echo "can't find the jmeter,please check the jmeter is if installed!!!!"
  exit 1
fi

jmx_file_name=`basename ${jmx_file}`
new_jmx_file="${thread_num}_${run_time}_${jmx_file_name}"
duration=`expr ${run_time} \* 60`
if [ ${thread_num} -eq 1 ];then
    ramp_time=1
elif [ ${thread_num} -gt 240 ];then
    ramp_time=120
else
    ramp_time=`expr ${thread_num} / 2`
fi
#echo ${ramp_time}
echo "the testing will be running" $run_time "minutes"

#update jmx file
function updateTestcase(){
      # sed -e "s#num_threads\">[0-9]*<#num_threads\">${thread_num}<#;s/ramp_time\">[0-9]*</ramp_time\">${ramp_time}</;s/loops\">-*[0-9]*</loops\">-1</;s/scheduler\">[a-z]*</scheduler\">true</;s/duration\">[0-9]*</duration\">${duration}</" ${jmx_file} > ${new_jmx_file}
      sed -e "0,/threads/s/threads\">[0-9]*</threads\">${thread_num}</;0,/ramp_time/s/ramp_time\">[0-9]*</ramp_time\">${ramp_time}</;0,/loops/s/loops\">-*[0-9]*</loops\">-1</;0,/scheduler/s/scheduler\">[a-z]*</scheduler\">true</;0,/duration/s/duration\">[0-9]*</duration\">${duration}</" ${jmx_file} > ${new_jmx_file}
      if [ -f ${new_jmx_file} ];then
         echo "${new_jmx_file} is updated"
         new_jtl_file=`echo ${jmx_file_name} | sed -e s/\.jmx/_${thread_num}\.jtl/`
      fi
}

#run the test case
function runLPTestcase(){
        now=`date +%Y%m%d-%H%M%S`
        report_path=`pwd`/jmeter_report/`basename ${jmx_file_name} .jmx`_${now}
        [ -d "$report_path" ] && rmdir "$report_path"
        mkdir -p "$report_path"

        if [ -f $new_jtl_file ];then
            new_jtl_file=`echo ${jmx_file_name} | sed -e s/\.jmx/_${now}_${thread_num}\.jtl/`
        fi
        echo "$new_jtl_file is ready"
        nohup ${jmeter_sh} -n -t ${new_jmx_file} -l ${new_jtl_file} -e -o ${report_path} >> ${jmx_file_name}.log &
}
echo "=================updateTestcase================="
updateTestcase
echo "=================runLPTestcase================="
runLPTestcase
echo "================start testing=================="
