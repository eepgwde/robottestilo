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
  $nodo python3 -m json.tool $@
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

  case $cmd in
    session-id)
      d_applog session-id $d_log > ${d_file}-id
      ;;

    session-create)
      # use applog session-id
      : ${d_file:=${d_dir}/${cmd}.json}
      test -f ${d_file} || return 2
      : ${d_log:=$(echo $d_file | sed 's/-create//g')}
      local tfile=$(mktemp)
      f_tpush $tfile

      $nodo curl -s --output $tfile -H 'Content-type: application/json' -X POST http://localhost:4723/wd/hub/session -d @${d_file} | d_json_pp $tfile > $d_log
      $FUNCNAME session-id
     ;;
  esac
}
