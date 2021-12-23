# weaves
# This script file uses m_ from
# https://sourceforge.net/p/ill/site/base/ci/master/tree/bin/m_
#
# It has a function f_tpush to delete temporary files on exit.

h_applog () {
    cat >&2 <<EOF

    Process output of appium

    $prog [-n] [-x] [-l outputfile] [-f inputfile] ${FUNCNAME##h_} [log|session]

    defaults:

    Sets inputfile to most recent appium-*.log file
    Sets output to adb-*.log and files it with the adb commands.

    log

    Processes appium log file given by inputfile to produce the output log file
    Contains only the adb commands

    session-create

    Extracts the last session create command from the appium-*.log as a JSON and writes it
    to a file called session-create.json

EOF

}

d_json_pp () {
  # pretty print JSON
  $nodo python3 -m json.tool
}

d_applog () {
  test $# -ge 1 || return 1
  local cmd="$1"
  shift

  : ${d_dir:=$PWD}
  : ${d_file:=$(m_ -d $PWD mr 'appium-*.log')}
  : ${d_log:=$(echo $d_file | sed 's/appium/adb/g')}

  case $cmd in
    session-create)
      awk 'BEGIN { rec0= 0 }
rec0 > 0 { $1=""; $2=""; $3=""; sess0=$0 ; rec0= 0; next }
$3 ~ /^\[HTTP\]/ && $4 ~ /-->/ && $5 ~ /POST/ && $6 ~ /\/wd\/hub\/session$/ {
 rec0=NR+1; next
}
END { sub(/^[ ]+/, "", sess0); print sess0 }
' $d_file | e_json_pp > ${cmd}.json
      ;;

    session-id)
      test $# -ge 1 || return 2
      test -f "$1" || return 4
      jq '.value.sessionId' < $1 | tr -d \" 
      ;;

    session-*)
      local tag=${cmd##session-}
      awk -v tag="[${tag}]" 'BEGIN { print tag } $3 == tag { print }' $d_file 
      ;;

    cmd)
      sed -e 's/shell \([^'\'']\)\(.*\)/shell '\''\1\2\'\''/g' 
      ;;
    log)
      egrep 'Running ' $d_file | sed 's/^.* Running //g' | \
        sed -e s/^\'//g -e s/\'$//g -e 's/^.*\/adb /adb /g' | $FUNCNAME cmd > $d_log
      ;;
	  view)
      echo $1 $d_dir $d_file
      ;;
  esac
}

h_app () {
  cat >&2 <<EOF

    Send commands to the app

    $prog [-n] [-x] [-l outputfile] [-f inputfile] ${FUNCNAME##h_} [session]

    defaults:

    Sets inputfile to most recent appium-*.log file
    Sets output to adb-*.log and files it with the adb commands.

    session-create

    Processes appium log file given by inputfile to produce the output log file
    Contains only the adb commands

    session-destroy

    Extracts the last session create command from the appium-*.log as a JSON and writes it
    to a file called session-create.json

EOF

}

d_app () {
  test $# -ge 1 || return 1
  local cmd="$1"
  shift

  : ${d_dir:=$PWD}

  local tfile=$(mktemp)
  f_tpush $tfile

  case $cmd in
    cmd0)
      ## Use a named file (usually temporary) as output
      test -n "$e_file" || return 2
      $nodo curl -s --output $e_file -H 'Content-type: application/json' $*
      ;;

    cmd1)
      $nodo curl -s -H 'Content-type: application/json' $* 
      ;;

    cmd2)
	: ${d_service:=http://127.0.0.1:4723/wd/hub}

	test -f ${d_dir}/session.json-id || return 2
	local sid
	local cmd
	read sid < <(cat ${d_dir}/session.json-id)
	echo $sid > $verbose

	read cmd < <(echo "$@" | sed -e 's,:session_id/,'$sid/',g')
	
      $nodo curl -s "${d_service}${cmd}"
      ;;

    session-isnull)
      read sid < <($FUNCNAME session-list | jq -r '.value[0]')
      test -n "$sid" || return 2
      if [ "$sid" = "null" ]
      then
        return 0
      fi
      return 1
      ;;

    page) # it's JSON from the server.
	$FUNCNAME cmd2 /session/:session_id/source | jq -r '.value'
	;;

    session-list-id)
      $FUNCNAME session-list | d_json_pp | jq -r '.value[0].id'
      ;;

    session-list)
      $FUNCNAME cmd1 -X GET http://localhost:4723/wd/hub/sessions
      # > $tfile
      # cat $tfile | jq -r '.value[0].id'
      ;;

    session-id)
      test $# -ge 1 || return 2
      test -f $1 || return 2
      d_applog session-id $1
      ;;

    session-create)
	# use applog session-id
	: ${d_file:=etc/appium/${cmd}-${OSTYPE}.json}
	: ${d_file:=etc/appium/${cmd}.json}

      test -f ${d_file} || return 2
      : ${d_log:=${d_dir}/session.json}

      # Fix the temporary file
      e_file=$tfile
      $FUNCNAME cmd0 -X POST http://localhost:4723/wd/hub/session -d @${d_file}
      sync
      cp -b $e_file session-create.out
      test -s $e_file || return 2
      cat $e_file | d_json_pp > $d_log
      $FUNCNAME session-id $d_log > ${d_log}-id
     ;;
  esac
}

h_adb () {
  cat >&2 <<EOF

    $prog ${FUNCNAME##h_} cmd|snippet|trim

    Generate adb commands

    - cmd

    $prog [-n] [-x] [-l outputfile] [-s adb-invocation] ${FUNCNAME##h_} cmd adb-args

    echoes an adb command to the console.

    - snippet and trim

    cat infile | $prog [-u e_null] [-n] [-x] [-l outputfile] ${FUNCNAME##h_} (snippet|trim)
    
    creates a script, outputfile or adb0.sh, of commands from infile
    filter each line by function e_null (default is e_trim)

    trim just returns the filtered strings

  - script

    $prog [-u e_null] [-n] [-x] [-l outputfile] ${FUNCNAME##h_} script inputfile

    This creates a script from inputfile see etc/appium/init0.sh

EOF
}

e_null () {
  cat
}

e_trim () {
  cut -c30- 
}

d_adb () {
  test $# -ge 1 || return 1
  local cmd="$1"
  shift

  e_weaves="e_trim"
  e_user=e_${d_user}
  : ${d_machine:=emulator-5554}

  # : ${d_service:=adb -P 5037 -s ${d_machine}}
  : ${d_service:=adb -P 5037}
  : ${d_log:=adb0.sh}

  case $cmd in
    trim)
      $e_user
      ;;

    run)
      $nodo bash $d_log
      ;;

    settings)
      $d_service shell am start -n com.android.settings/.Settings
      ;;

    script)
      cat $* | while read line0; do $FUNCNAME cmd $line0; done > $d_log
      ;;
    snippet)
      $e_user | while read line0; do $FUNCNAME cmd $line0; done > $d_log
      ;;
    cmd)
      echo $d_service $*
      ;;
  esac
}

d_mk () {
  test $# -ge 1 || return 1
  local cmd="$1"
  shift

  case $cmd in
    log)
      $nodo tail -f $(m_ -d . mr 'appium-*.log')
      ;;
    cold)
      make ${nodo:+"-n"} -f emu.mk clean-local
      make ${nodo:+"-n"} -f emu.mk X_SNAPSHOT=-no-snapshot-load all-local
      ;;
    warm)
      make ${nodo:+"-n"} -f emu.mk clean-local
      make ${nodo:+"-n"} -f emu.mk all-local
      ;;
    session)
      make ${nodo:+"-n"} session-live
      ;;
  esac  
}

h_aa () {
  cat >&2 <<EOF

    $prog [-f badging.lst] ${FUNCNAME##h_} badging|package|activity

  badging - get the badging information from the APK on the command-line
  stores it to the '-f' outfile, default badging.lst

  package - extract the package name from the badging file given by badging.lst

  activity - extract the launch activity from the badging file

  start - generate an adb package start line

EOF

}

d_aa () {
  test $# -ge 1 || return 1
  local cmd="$1"
  shift

  : ${d_dir:=.}
  : ${d_file:=${d_dir}/badging.lst}

  case $cmd in
    badging)
      test $# -ge 1 || return 4

      local tfile=$(mktemp)
      f_tpush $tfile
      aapt dump badging "$1" > $d_file
      ;;
    package)
      test -f ${d_file} || return 2
      awk -F" " '/package/ {print $2}' $d_file | awk -F"'" '/name=/ {print $2}'
      ;;
    activity)
      test -f ${d_file} || return 2
      awk -F" " '/launchable-activity/ {print $2}' $d_file | awk -F"'" '/name=/ {print $2}'
      ;;
    start)
      echo shell am start -n $($FUNCNAME package)/$($FUNCNAME activity)
      ;;
  esac
}
