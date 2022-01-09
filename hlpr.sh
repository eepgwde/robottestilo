# weaves
# This script uses a wrapper file called m_ from
# https://sourceforge.net/p/ill/site/base/ci/master/tree/bin/m_
# There is a local copy.
# It has a function f_tpush to delete temporary files on exit.

h_mr () {
    cat >&2 <<EOF
    Most recent file

    $prog [-d dir] ${FUNCNAME##h_} 
    $prog [-d dir] ${FUNCNAME##h_} 'appium-*.log'

    The default directory is . 

    The first form looks at all files in the directory and returns the name of the most recent.

    The second form uses a hard-quoted glob specification like 'appium-*.log'
    It then finds the most recent file to match that spec in the directory.
EOF

}

d_mr () {
    : ${d_dir:=.}

    : ${FIND:=find}

    if [ $# -ge 1 ]
    then
        $FIND -L "$d_dir" -maxdepth 1 -type f -name "$*" -printf "%T@ " -print | sort -rnk1 | head -1 | cut -d' ' -f2-
    else
        ls -t "$d_dir" | head -1 | sed 's,^,'""${d_dir}""'/,g'
    fi

}

h_list () {
  cat >&2 <<EOF

    Copy files into the project src directories

    $prog [-n] [-x] [-l outputfile] [-f inputfile] ${FUNCNAME##h_} sdirs3|sdirs4|sdir5

    sdirs3 lists all the eligible directories that are down of \$TOP $TOP
    then sdirs4 prints the package names
    then sdirs5 prints the pairs

    then sdirs6 will copy the package-info.java file changing the package name to the directory.

    sdirs7 will list those directories.

EOF
}


d_list () {
    test $# -ge 1 || return 1
    local cmd="$1"
    shift

    # : ${d_dir:=$PWD}
    # : ${d_file:=$(m_ -d $PWD mr 'appium-*.log')}
    # : ${d_log:=$(echo $d_file | sed 's/appium/adb/g')}

    case $cmd in
	props-inc)
	    awk 'BEGIN { FS="="; ctr=1; OFS="=" }
$1 ~ /resource-id$/ { $1=$1"."ctr; print; ctr=ctr+1 }
' $@
	    ;;
	first)
	    # first of its kind - output of sum(1)
	    awk 'BEGIN { mark=0 }
$1 != mark { print $1, $NF; mark=$1 }'
	    ;;

	apk*)
	    : ${d_dir:=apk/Mein_o2}
	    : ${d_log:=./apk.lst}
	    
	    find $d_dir -type f -name '*.xml' -exec grep -q -s 'android:id=' {} \; -print | \
		tee ${cmd}.lst
	    ;;
	nodes)
	    : ${d_dir:=./cache}
	    cat $d_dir/w*-node.properties | awk -F: 'NF > 0 { print $1 }' | sort -u
	    ;;
	page-tag)
	    : ${d_dir:=./pages}
	    test $# -ge 1 || return 2
	    grep -l "$1" $d_dir/*.xml1 | sed -n '1p' | while read i
	    do
		echo ${i%%.xml1}.xml
	    done
	    # cat $d_dir/w*-node.properties | awk -F: 'NF > 0 { print $1 }' | sort -u
	    ;;
    esac
}
	  
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

d_jq_kv () {
    $nodo jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' $@
}

# Removes colourisation from log files.
d_clean () {
    : ${SED:=sed}
    for d_file in $@
    do
	$SED -i -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" $@
    done
}

d_applog () {
    test $# -ge 1 || return 1
    local cmd="$1"
    shift

    : ${d_dir:=$PWD}
    : ${d_file:=$($prog -d $PWD mr 'appium-*.log')}
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

    case $cmd in
	cmd0)
	    ## Use a named file (usually temporary) as output
	    test -n "$e_file" || return 2
	    $nodo curl -s --output $e_file -H 'Content-type: application/json' $*
	    ;;

	cmd1)
	    $nodo curl -s $d_options -H 'Content-type: application/json' $@ ${d_file:+-f ${d_file}}
	    ;;

	cmd2)
	    : ${d_dir:=$PWD}

	    : ${d_service:=$X_HOST}
	    : ${d_service:=http://127.0.0.1:4723/wd/hub}

	    test -f ${d_dir}/session.json-id || return 2
	    local sid
	    local cmd
	    read sid < <(cat ${d_dir}/session.json-id)
	    echo $sid > $verbose

	    read cmd < <(echo "$@" | sed -e 's,:session_id,'$sid',g')
	    
	    
	    $nodo curl -s $d_options "${d_service}${cmd}" ${d_file+"-f "${d_file}}
	    ;;
	cmd3)
	    # d_file is now args -f filename
	    local e_file=$($prog -d etc/appium mr "${d_file}")
	    : ${d_file:=etc/appium/username.json}
	    : ${d_file:=$e_file}

	    $FUNCNAME cmd1 
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

	_pagefile)
	    # On cygwin, it doesn't work as described.
	    TMPDIR=${d_dir} mktemp --tmpdir=${d_dir} -t wXXXXXX
	    ;;

	_commentfile)
	    if [ -n "$d_log" ]
	    then
		touch "$d_log"
		echo $d_log
	    else
		# On cygwin, mktemp doesn't work 
		read mr < <($prog -d ${d_dir} mr 'c*')
		if [ -z "$mr" ]
		then
		    TMPDIR=${d_dir} mktemp --tmpdir=${d_dir} -t cXXXXXX
		else
		    echo $mr
		fi
	    fi
	    ;;

	pages-clean)
	    : ${d_dir:=$PWD/pages}
	    test -d $d_dir || return 2
	    
	    find $d_dir -type f -name 'w*' -exec grep -sq '"unknown error"' {} \; -delete
	    ;;

	page-pages)
	    : ${d_dir:=$PWD/pages}
	    test -d "$d_dir" || mkdir -p ${d_dir}
	    local tfile=$($FUNCNAME _pagefile)
	    local cfile=$($FUNCNAME _commentfile)
	    unset d_dir
	    $FUNCNAME page > $tfile
	    ## and write a comment
	    echo $(date --iso-8601=minutes) : $tfile : $(sum $tfile) : "$*" >> $cfile
	    ;;

	page) # it's JSON from the server.
	    $FUNCNAME cmd2 /session/:session_id/source | jq -r '.value'
	    ;;

	session-delete)
	    d_options=DELETE
	    $FUNCNAME cmd2 /session/:session_id
	    ;;

	session-list-id)
	    if [ $d_count -lt 0 ]
	    then
              d_count=0
            fi
	    $FUNCNAME session-list | d_json_pp | jq -r '.value['${d_count}'].id'
	    ;;

	session-list)
	    $FUNCNAME cmd1 -X GET ${X_HOST}/sessions
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
	    : ${d_dir:=$PWD}

	    : ${d_file:=etc/appium/${cmd}-${OSTYPE}.json}
	    : ${d_file:=etc/appium/${cmd}.json}

	    test -f ${d_file} || return 2
	    : ${d_log:=${d_dir}/session.json}

	    # Setup a temporary file, deleted on exit
	    e_file=$(mktemp)
	    f_tpush $tfile

	    $FUNCNAME cmd0 -X POST ${X_HOST}/session -d @${d_file}

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

h_mk () {
    cat >&2 <<EOF

    $prog ${FUNCNAME##h_} log|cold|warm|session

Some shortcuts for using the Emulator emu.mk

Log perfoms a tail on the latest appium logfile and only works if you have the full m_.sh 
implementations.

Only make -f emu.mk clean if you want to delete all the log files.

EOF

}

d_mk () {
    test $# -ge 1 || return 1
    local cmd="$1"
    shift

    local fmk=emu.mk
    test -f $fmk || return 2

    case $cmd in
	log)
	    $nodo tail -f $($prog -d . mr 'appium-*.log')
	    ;;
	cold)
	    make ${nodo:+"-n"} -f $fmk clean-local
	    make ${nodo:+"-n"} -f $fmk X_SNAPSHOT=-no-snapshot-load all-local
	    ;;
	warm)
	    make ${nodo:+"-n"} -f $fmk clean-local
	    make ${nodo:+"-n"} -f $fmk all-local
	    ;;
	session)
	    make ${nodo:+"-n"} session-live
	    ;;
    esac  
}

h_aa () {
    cat >&2 <<EOF
  Android Packaging Utility

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

d_conv () {
    test $# -ge 1 || return 1
    local cmd="$1"
    shift

    : ${d_dir:=.}

    case $cmd in
	shell)
	    # Convert a properties file to a series of shell set commands.
	    # There's a trim() method in there, comments are ignored, and in the
	    # properties key . is replaced with _. The value is quoted.
	    $nodo awk -F= 'BEGIN { FS="="; OFS="=" } 
function trim(f, p) { p=f; gsub(/^[ ]*/, "", p); gsub(/[ ]+$/, "", p); return p }
/^#/ { next }
NF >= 2 { $1=trim($1); gsub(/\./, "_", $1); $2=trim($2); $2="\""$2"\""; print }'
	    ;;
	
	appium)
	    test $# -ge 1 || return 1
	    d_file="$1"
	    test -f "${d_file}" || return 2

	    # Takes a testconfig.properties and converts it to a JSON to start an Appium session with
	    # see $prog app session-create
	    : ${d_log:=$(mktemp)}

	    local tfile=$(mktemp)
	    f_tpush $tfile

	    # convert to a shell script, source that and then use a in-place file
	    cat $d_file | $FUNCNAME shell > $tfile
	    source $tfile

	    cat > $d_log <<EOF
{
    "desiredCapabilities": {
        "app":  "$android_capability_app_o2",
        "deviceName": "$capability_deviceName",
        "appActivity": "$android_capability_appActivity",
        "appPackage": "canvasm.myo2",
        "newCommandTimeout": $capability_newCommandTimeout,
	"noReset": $capability_noReset,
	"fullReset": $android_capability_fullReset,
        "platformVersion": "$capability_platformVersion",
        "automationName": "$capability_automationName",
        "platformName": "$capability_platformName",
        "avd": "$android_capability_avd"
    },
    "capabilities": {
        "firstMatch": [
            {
                "appium:app": "$android_capability_app_o2",
                "appium:appActivity": "$android_capability_appActivity",
                "appium:appPackage": "canvasm.myo2",
                "appium:automationName":  "$capability_automationName",
                "appium:avd":  "$android_capability_avd"
                "appium:deviceName":  "$capability_deviceName",
                "appium:newCommandTimeout": $capability_newCommandTimeout,
		"noReset": $capability_noReset,
		"fullReset": $android_capability_fullReset,
                "platformName": "$capability_platformName",
                "appium:platformVersion": "$capability_platformVersion"
            }
        ]
    }
}

EOF
	    ;;
	
	package)
	    true
	    ;;
    esac
}

## XSLT processing
# originally just xmlstarlet, and xsltproc, but moved up to Saxon on Cygwin
# so the XSLT processor is wrapped in a function using d_file and others.
# see the case " *s) # if it ends is "s" run it on all the files in pages/"

# see hlpr.def
# d_xsltp () {
#     $nodo "$XSLTP" -s:$(cygpath -w $d_file) -xsl:$(cygpath -w ${1}) -o:$(cygpath -w ${d_log})
# }

if [[ $(type -t d_xsltp) == function ]]
then
    true
else

: ${XSLTP:=xsltproc}
d_xsltp () {
 $nodo "$XSLTP" -o $(cygpath -w ${d_log})  ${1} $d_file
}

fi

## Some many XML operations.

d_xml () {
    test $# -ge 1 || return 1
    local cmd="$1"
    shift
    local xml=xmlstarlet

    : ${d_dir:=pages}
    : ${d_file:=$($prog -d "$d_dir" mr 'w*.xml')}

    ## These are used to compare to the signatures in .xml1
    typeset -a SIG
    SIG=()

    # Slightly different XPath syntax
    SIG+=('//*[*/@resource-id = "canvasm.myo2:id/radio"]')
    SIG+=('//*/android.widget.RadioButton')
    SIG+=('//*[*/@clickable = '\''true'\'']')
    SIG+=('//*[*/@text != '\'\'']')
    SIG+=('//*[*/@resource-id != '\'\'']')
    SIG+=('//*/android.widget.EditText')
    SIG+=('//*/android.widget.TextView')
    SIG+=('//*/androidx.drawerlayout.widget.DrawerLayout')

    case $cmd in
	pics) # process all the image files
	    for d_file in ${d_dir}/w*.xml2
	    do
		$FUNCNAME pic
	    done
	    ;;

	pic) # process one
	    local tfile=${d_file%%.*}.png
	    base64 -d $d_file > $tfile
	    ;;

	## This should match the appium-boilerplate NewPage.signature method given in .xml1
	signature)
	    local tfile=${d_file%%.xml}
	    test -f ${tfile}.xml1 || return 2

	    d_jq_kv ${tfile}.xml1

	    for x in "${SIG[@]}"
	    do
		$nodo $xml sel -T -t -v 'count('"$x"')' -n $d_file 
	    done | xargs echo signatur1= | sed -e 's/=./=/g' | sed -e 's/ /,/g'
	    ;;
	
	structure)
	    $nodo $xml sel -T -t -m '//*' -m 'ancestor-or-self::*' -v 'name()' -i 'not(position()=last())' -o . -b -b -n $d_file
	    ;;
	textview)
	    $nodo $xml sel -t -c "//*/android.widget.TextView" -n $d_file
	    ;;
	clickable-radiobutton)
	    $nodo $xml sel -t -c "//*[android.widget.RadioButton/@clickable = 'true']" -n $d_file
	    ;;
	clickable-edittext)
	    $nodo $xml sel -t -c "//*[android.widget.EditText/@clickable = 'true']" -n $d_file
	    ;;
	clickable-nonempty)
	    ## This never produces
	    $nodo $xml sel -t -c "//*[*/@clickable = 'true' and @text != '']" -n $d_file
	    ;;
	clickable)
	    $nodo $xml sel -t -c "//*[*/@clickable = 'true']" -n $d_file
	    ;;
	resource-id-1)
	    $nodo $xml sel -t -c "//*[*/@resource-id != '']" -n $d_file
	    ;;
	text-nonempty)
	    $nodo $xml ed -d "//*[*/@text != '']" $d_file
	    ;;
	text-empty)
	    $nodo $xml sel -t -c "//*[*/@text = '']" -n $d_file
	    ;;

	ios-*)
	    local cmd1=${cmd##ios-}
	    case $cmd1 in
		visible)
		    $nodo $xml sel -t -c "//*[*/@visible = 'true' and ( @name != '' or @lable != '')]" -n $d_file
		    ;;
	    esac

	    ;;

	
	cmdline)
	    # "//@index" => all hierarchy 0
	    # "//@resource-id" 
	    $nodo $xml sel -T -t -v $* $d_file
	    ;;

	## This generates a list of base files - the hashcode
	tags)
	    # usually you want to concatenate all the files in cache/ 
	    : ${d_service:="*"}
	    ls ${d_dir}/${d_service} | sed 's/\..*$//g' | sort -u 
	    ;;

	descs)
	    # are made of -click and -signature files and are written to _desc files.
	    : ${d_port:=.properties}
	    local tfile=${cmd%%s}

	    $prog -d cache xml tags | egrep -- -'(click|signature)$' | xargs -n2 | while read i j
	    do
		x0="$(echo ${j} | sed -e 's/-signature/_'${tfile}'/g')"${d_port}
		echo ${j}.properties ${i}.properties $x0 > $verbose
		cat ${j}.properties ${i}.properties > $x0
	    done
		
	    ;;
	
	
	## Batch processing uses a different function and only works on .xslt files
	# text3.xslt needs to use Saxon or other XSLT v2.0

	*s) # if it ends is "s" run it on all the files in pages/  and
	    # use d_xsltp() to do so
	    : ${d_service:=cache}
	    test -d "${d_service}" || mkdir -p "${d_service}"
	    : ${e_filetype:=.properties}

	    local e_file

	    case ${cmd} in
		signatures)
		    true
		;;
		*s)
		    e_file=${cmd%%s}.xslt
		    test -f "${e_file}" || return 2
		;;
	    esac

	    local tfile
	    for d_file in ${d_dir}/w*.xml
	    do
		tfile=${d_file##*/}; tfile=${tfile%%.xml}
		d_log=${d_service}/${tfile}-${cmd%%s}${e_filetype}
		echo $tfile $d_file $d_log > $verbose

		case ${cmd} in
		    signatures)
			$FUNCNAME signature > $d_log
		    ;;
		    *s)
			d_xsltp ${e_file}
		    ;;
		esac
	    done
	    ;;

	all)
	    test -n "$d_service" || return 4
	    test -f "$d_service" || return 2
	    
	    for d_file in $(cat $d_service | xargs)
	    do
		echo -- $d_file > $verbose
		$FUNCNAME $d_service $*
	    done
	    ;;

	## Using a file

	*)
	    test -f "${cmd}.xslt" || return 8
	    d_log=$(mktemp)
	    f_tpush $d_log
	    d_xsltp ${cmd}.xslt && cat $d_log
	    ;;
	
	    
    esac
    
}
