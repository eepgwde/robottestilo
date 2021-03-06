# Control #

weaves

# Android and Appium Command-Line Tools

These utilities work for Linux and Cygwin on Windows. It partly works on MacOS.  It does
not manage the iOS emulator from the command-line, but it can manage the Android one and
the Appium server. It does perform the XML processing.

## Installing 

If you need to control the Android emulator, then these scripts need to be installed in an
Android SDK directory. If you are only using the XML post-processing, you can install
somewhere are your convenience.

If you use Android Studio to do that, then find your SDK directory and checkout the code
from GitHub to here using this sequence:

    git init
    git remote add origin PATH/TO/REPO
    git fetch
    # Required when the versioned files existed in path before "git init" of this repo.
    git reset origin/master  
    git checkout -t origin/master

And you should get this file on your local disk.

I also try and simplify my Android configuration with some links. Most important is that
my .android directory is here and not in my home directory and I have a link to expose it
here.

    build-tools/32.0.0-rc1/ ./btools
    .android ./android
    etc/hlpr ./hlpr
    
There is also a local copy of my script wrapper m_ here etc/hlpr and that is linked to ./hlpr - it should also
be executable. I hope it works, it is used a lot.

A quick word about it: hlpr is a wrapper that loads all the shell functions in hlpr.sh. It also uses hlpr.def
for constants. The script hlpr has lots of switches.

When debugging, use it like this: hlpr -n -x

The hlpr.def is used to define the base URL for Appium: usually it is
http://localhost:4723/wd/hub

These are given in the hlpr.def file. They can be overridden with the command line

    -p 4726 -m jenkins -P /wd/hub1

This would then use  http://jenkins:4726/wd/hub1 as the base URL.

## What these Shell Scripts, XSLT and GNU Make Files Do

### Managing emulator start-up

There is a Makefile emu.mk that can start and stop

 - the Android Emulator
 - the Appium server using Node

### Starting and Stopping App Sessions ready for Cucumber and Gherkin

If you create a JSON file with your Android package's parameters

Then the script can send it to the Appium server and your Android App should start.

### Interrogating your App using Appium

You can also do a few simple things with the script. You can get

 - The session identifier

 - The current page on the app

It can get the session identifier, this is useful if you have connected using another
system.

Most usefully, you can get the XML of the current page on display.

### XSLT post-processing of XML files

If you store your XML pages to the pages/ directory, you can use the other GNU Make
utility, xsl0.mk, to produce XPath and Java properties files of the pages.

# Emulator Control and Appium Sessions

If you are using the SDK, you will need to set up your environment to use the Android
command-line utilities. I have an example configuration for Cygwin in
etc/android0-cygwin. It uses this utility to manage paths: etc/pathmerge.

## Starting and Stopping the Emulator

Starting up: try this no-execute incantation of GNU Make: make -B -n all-local. It shows
you what will be done. 

    make -B -n all-local
    echo OSTYPE - Cygwin
    echo $$
    test -n "L:\cache\Android\sdk"
    test -d "L:\cache\Android\sdk"
    adb start-server
    nohup appium -g appium-$$.log --log-timestamp --local-timezone --log-no-colors --tmp /var/tmp --suppress-adb-kill-server > /dev/null 2>&1 &
    touch adb-server.flag
    nohup emulator/emulator @emulator2   > emulator.log 2>&1 &

And to see what is done to stop the test system, try make -B -n clean-local

You can eventually try this sequence repeatedly until you see success

    make -B all-local
    # check logs, correct as needed and then
    make -B clean-local

You can check the Appium log with hlpr mk log.

When the Applium log looks good, it will probably work reliably, so you can side-step all
the trace statements and do this in one operation:

    hlpr mk cold

This also performs a start from cold - a full restart for the emulator.

## Starting Sessions

This is a simple Curl operation. You do need a well-configured JSON file. There are some
samples in the directory etc/appium. Using the -n switch to hlpr you can see what it will do.

    $ hlpr -n app session-create
    curl -s --output /var/tmp/tmp.l50oSDNRxV -H Content-type: application/json -X POST \
     http://localhost:4723/wd/hub/session -d @etc/appium/session-create-cygwin.json

The script has some logic to switch the file used by operating system. You can override
on the command-line with the -f switch before, for example:
 
    $ hlpr -n -f ./my-session-create.json app session-create
    curl -s --output /var/tmp/tmp.Jb3AZ8cPox -H Content-type: application/json -X POST \
     http://localhost:4723/wd/hub/session -d @./my-session-create.json

If the JSON is well-formed, you should see your App come to life. If not, check the
appium-*.log file with

    $ hlpr mk log

and you will discover that a path is wrong or you have noReset and fullReset both true.

When you do get the system running, you can also try the Makefile version

    make session-live

this checks there is an existing session and if not starts a new one. (This is useful for
automated testing, if you want to test with newCommandTimeout set to something non-zero.)

### Recommendations

Usually, I use this to capture XML files of the screens on display in the App. So I like
to use fullReset for a clean startup, but I have to login every time.

I usually set newCommandTimeout to 0 so that I can interact with the App and snapshot when
the page changes.

You can also run Appium Inspector with this. The Inspector has an "Attach to Session" feature.

## Snapshotting Screens

One of the things that should happen when you use hlpr app session-create is a file
containing the session identifier is created. The file is session.json-id. (The whole
response is in the file session.json - the capabilities are given in there.)

If that session.json-id file exists, then this

    $ hlpr app page

will capture the page displayed as Selenium XML. There is more sophisticated version of
this invocation that will write to the pages/ directory using temporary file names. To be
compatible with the XSLT processing, the files are prefixed with "w" and have no suffix.

    $ hlpr app page-pages

is the invocation to add another page capture to the pages/ directory. This also has a
comments feature. A comment file will be appended to. Comment files are in the pages
directory and should start with "c". You can put a comment on the command-line

    $ hlpr -l pages/c-locked1 app page-pages consent page

It calculates a checksum and puts that into the comments file with a timestamp, you can
put this into a shell script to snapshot every minute:

    $ nohup bash -c 'until false; do hlpr -l pages/c-locked1 app page-pages; sleep 60; done' &

## Converting testconfig.properties files

Some Appium implementations using their java-client put their test configuration into a
properties file. You can convert to a JSON file using this script. Using my sample
testconfig.properties in the etc/appium directory, that looks like this.

   $ hlpr -l my-session-create.json conv appium etc/appium/testconfig.properties

# XSLT Post-Processing

To use these operations, you will need xmlstarlet and xsltproc.

## Checking XPaths

You use 'hlpr xml' to post-process individual files with xmlstarlet. This is for checking
XPath.

By default 'hlpr xml' will use the most recent file in the pages/ directory. You should try and 
remember what screen appeared for this file or use the comments feature when capturing.

You can try out some XPaths on the captured files in pages/. Use the examples in the d_xml
function of hlpr.sh for guidelines. 

The XSLT processing can be made in batch form. For the files that end in .xslt you can
process a single file with

   hlpr xml attname

and the output is sent to standard output.

Or you can add an 's' to the filestem and the output will be written, file by file, to the
cache directory.

   hlpr xml attnames

### General Structural Enquiries - Android and iOS

#### Attributes and Nodes

This can be useful

   hlpr xml attname

The gets all the attributes names in order. It's a good idea to sort uniquely with

   hlpr xml attname | sort -u

and you should see the attributes used on all the elements. This method is useful for
checking if you have a non-compliant file.

You can also use

   hlpr xml node (and nodes)

This gives all the nodes and the counts of the occurrences of each node.

#### XPaths

You can get all the XPaths for every attribute from the file.

   hlpr xml xpath

The file will be large. 10000 lines is typical. You can filter it by looking for text
strings and particular @bounds attributes. This gets a record with non-empty text.

### Android XML Page Processing

Some of the these command use xmlstarlet.

#### Text Elements

For a file to find the non-empty text attributes use

   egrep 'text="[^"]+"' pages/w00001

For the XPath use this

   hlpr xml xpath | egrep '@text='\''.+'\'''

Similarly, you can see the last file's interesting elements:

   hlpr xml textview # TextView
   hlpr xml clickable-radiobutton # RadioButton
   hlpr xml clickable-edittext # EditText

And general enquiries:

   hlpr xml text-nonempty # anything with text
   hlpr xml clickable # any clickable fields

You can get all interesting elements in a Properties file format using this:

   hlpr xml text

Many Android apps don't make use of buttons directly and there may be clickable fields
that have no text. The clickable elements are usually in LinearLayoutCompat and ViewGroup.

You can try text2, but this finds elements that contain elements that contain text.

   hlpr xml text2

All the clickable components can be extracted with

  hlpr xml click

These properties files can be used within appium-boilerplate to describe buttons on pages.


### Batch Processing

You can apply the text.xslt and xpath.xslt using GNU Make and the file xsl0.mk

   make -f xsl0.mk all-local

This makes a new directory called cache/ and puts the processed files into it.

Then you can process the cache/\*-text.xml to see how many are alike by using the checksum
of the file

   make -f xsl0.mk all-local2

That produces a single file text.sums. This contains the files that were first to have a
common checksum. 

You can copy then process those files to produce Java Properties files.

 make -f xsl0.mk S_FILE=text.sums all-local3

You should then see files cache/\*-text.properties. Ideally, each of these should be unique
to a page. The text.xslt and the final wXXXXX-text.properties is not so useful. It will
contain the unique text shown to each user.

The text2.xslt properties is just the clickable elements that have some text. These should
be unique, but are difficult to find.


# Android Development on Windows and Linux #

\[Editor: this section is mostly notes on setting up on Windows after using the Linux
systems under nested virtualization.\]

Windows can run the emulator more quickly than Linux in nested virtualization.

To run an emulator on Windows, start it as usual, using AVD Tools in Android Studio.

You can try to access the Emulator from Linux using some network redirection.

https://www.reddit.com/r/Crostini/comments/hqyjir/android_emulator_remote_host/

Use adb on the Windows side to reconfigure, redirect from 1234 to 5555

 adb forward tcp:1234 tcp:5555

and restart on 5555

 adb tcpip 5555
 
In the emulator, there will be a prompt to allow USB debugging.

Then connect

 adb connect 192.168.127.1:1234
 
and watch for allow USB debugging.

Then 

 adb devices 
 
will show 

 192.168.127.1:1234

As a Windows Adminstrator redirect the network port to the emulator

 netsh interface portproxy add v4tov4 listenaddress=192.168.127.1 listenport=1234 connectaddress=127.0.0.1 connectport=5555

Go to Linux

 adb kill-server
 adb start-server
 adb connect 192.168.127.1:1234
 adb devices

And adb is connected from Linux.

# Android Development on Linux #

To use the emulator on Linux you need to be a member of the kvm group.

## Appium

### NPM install 

You can use SNAP to provide an npm and to install to /usr/local

 snap install node --classic --channel=16

 npm config set prefix /usr/local

Change to the staff group (newgrp staff) and use 

 npm install -g appium
 
You check the installation with 

 npm install -g appium-doctor
 
You will need /snap/bin on your path.

### Using Appium Applications

Download the system images and install them locally.
Links are used here.

## Android SDK and AVD: using Android Studio ##

### Use the SDK Manager in Tools


# Android Development on Linux#

To use the emulator on Linux you need to be a member of the kvm group.

## Appium

### NPM install 

You can use SNAP to provide an npm and to install to /usr/local

 snap install node --classic --channel=16

 npm config set prefix /usr/local

Change to the staff group (newgrp staff) and use 

 npm install -g appium
 
You check the installation with 

 npm install -g appium-doctor
 
You will need /snap/bin on your path.

### Using Appium Applications

Download the system images and install them locally.
Links are used here.

## Android SDK and AVD: using Android Studio ##

### Use the SDK Manager in Tools

For this example, the SDK should be installed to this location: /home/build/0/android

And add these other components:

 Android SDK Build-Tools
 Android SDK Command-Line Tools (latest)
 Android Emulator
 Android SDK Platform-Tools
 
 Google Play service
 
Re-organise the directories to use other directories before installing the AVD
files.

### Use the AVD Manager in Tools

For this installation, you need to redirect the .android/avd directory.

There is a quirk with the AVD on Windows Hyper-V - no support for hardware acceleration.
This can be done with the emulator on the command-line. If you need to run the emulator from
Android Studio, you should use Advanced Options and set the Graphics to Software.

### Environment Script

   ANDROID_PREFS_ROOT=/home/build/0/android 
   ANDROID_HOME=/home/build/0/android
   ANDROID_AVD_HOME=/home/build/0/android/.android/avd
   ANDROID_EMULATOR_HOME=/home/build/0/android/.android
   ANDROID_SDK_ROOT=/home/build/0/android

and on the path add these.

PATH=$PATH:$ANDROID_PREFS_ROOT/platform-tools:\
$ANDROID_SDK_ROOT/tools:\
$ANDROID_PREFS_ROOT/emulator

### Re-organisation

The environment variables for Android do not seem to re-direct.
So I used some soft-links, these are stored in links.afio if needed.

system-images -> somewhere with over 8GB of disk space

android -> .android
.android/avd -> somewhere with over 9GB of disk space

# Processes #

Most of the processes are in the emu.mk file.

The set-up is for this Android App basic-appium-project

 https://github.com/Jose-Luis-Nunez/basic-appium-project.git

## Emulator

You need to be in running as a member of the kvm group.

From the ANDROID_SDK_ROOT directory, this will start the adb server, appium and 
the emulator

 $ make all-local
 
The log files go to appium.log and emulator.log

To kill the servers used
 
 $ make clean-local

## IDEs

You can start the IDEs. These are in the /snap/bin/ directory: android-studio and 
intellij-idea-community. 

 $ make idea
 $ make studio

You only need android-studio for the SDK and AVDs.

# # Android and Appium Testing: Utilities #

## System ##

### Scripting utility ###

This runs on Linux. It uses a shell wrapper for the script hlpr and this uses
hlpr.def and hlpr.sh. 

The source file for hlpr is here

https://sourceforge.net/p/ill/site/base/ci/master/tree/bin/m_

### Processing Appium Logs ###

### Workflows ###

#### Start system ####

Start an emulator, adb server and appium.

 make all-local
 
You should physically an emulator start.

#### Initialize system ####

Start a session and get some basic state information

 make app-init0.flag

You should see the emulator load the app. It uses files in etc/appium

The file session.json will contain the session information
The file app-session.flag will contain the session id
The file app-init0.flag will etc/appium/init0.sh

The session will eventually time out, check this with

 hlpr app session-list
 
Or 

 hlpr app session-isnull

#### Using Inspector ####

 make session-live

the last one deletes the flag files so that a session can be restarted.

#### Using Inspector ####

## Journal

### Error 1

This arises when the emulator has been left unattended for too long, usually
overnight.

You need to restart the emulator with -no-snapshot-load with see hlpr.sh d_mk cold

2021-12-03 09:55:38:133 [W3C] Encountered internal error running command: UnknownError: An unknown server-
side error occurred while processing the command. Original error: Could not proxy command to the remote se
rver. Original error: socket hang up
2021-12-03 09:55:38:133 [W3C]     at UIA2Proxy.command (/usr/local/lib/node_modules/appium/node_modules/ap
pium-base-driver/lib/jsonwp-proxy/proxy.js:274:13)
2021-12-03 09:55:38:133 [W3C]     at runMicrotasks (<anonymous>)
2021-12-03 09:55:38:133 [W3C]     at processTicksAndRejections (node:internal/process/task_queues:96:5)
2021-12-03 09:55:38:133 [W3C]     at AndroidUiautomator2Driver.commands.getDevicePixelRatio (/usr/local/li
b/node_modules/appium/node_modules/appium-uiautomator2-driver/lib/commands/viewport.js:14:10)
2021-12-03 09:55:38:133 [W3C]     at AndroidUiautomator2Driver.fillDeviceDetails (/usr/local/lib/node_modu
les/appium/node_modules/appium-uiautomator2-driver/lib/driver.js:244:28)
2021-12-03 09:55:38:133 [W3C]     at AndroidUiautomator2Driver.createSession (/usr/local/lib/node_modules/
appium/node_modules/appium-uiautomator2-driver/lib/driver.js:230:7)
2021-12-03 09:55:38:133 [W3C]     at AppiumDriver.createSession (/usr/local/lib/node_modules/appium/lib/ap
pium.js:387:35)

# Apple XCode Tools

# Appium RESTful API

## Page Source

 hlpr app page 

## Keyboard Input

Appium Inspector cannot send keyboard input using its implementation.

The Appium for the interaction with the Java client shows the use of only W3C commands.

https://appium.io/docs/en/commands/interactions/actions/

The Actions in the Interactions section.

These sections from Appium log show the Java client doing this work.

It finds the edit text element box. canvasm.myo2:id/login_input_login_name

2021-12-24 21:52:06:294 [W3C (cf9a7d33)] Calling AppiumDriver.findElement() with args: ["id","canvasm.myo2:id/login_input_login_name","cf9a7d33-02eb-4935-b797-e0ddffb4aa55"]
2021-12-24 21:52:06:294 [BaseDriver] Valid locator strategies for this request: xpath, id, class name, accessibility id, css selector, -android uiautomator
2021-12-24 21:52:06:294 [BaseDriver] Waiting up to 15000 ms for condition
2021-12-24 21:52:06:295 [WD Proxy] Matched '/element' to command name 'findElement'
2021-12-24 21:52:06:295 [WD Proxy] Proxying [POST /element] to [POST http://127.0.0.1:8200/wd/hub/session/e0db4229-e013-4e42-99ba-2d7bbf151f7f/element] with body: {"strategy":"id","selector":"canvasm.myo2:id/login_input_login_name","context":"","multiple":false}
2021-12-24 21:52:06:329 [WD Proxy] Got response with status 200: {"sessionId":"e0db4229-e013-4e42-99ba-2d7bbf151f7f","value":{"ELEMENT":"00000000-0000-000a-ffff-ffff0000003c","element-6066-11e4-a52e-4f735466cecf":"00000000-0000-000a-ffff-ffff0000003c"}}
2021-12-24 21:52:06:329 [W3C (cf9a7d33)] Responding to client with driver.findElement() result: {"element-6066-11e4-a52e-4f735466cecf":"00000000-0000-000a-ffff-ffff0000003c","ELEMENT":"00000000-0000-000a-ffff-ffff0000003c"}
2021-12-24 21:52:06:329 [HTTP] <-- POST /wd/hub/session/cf9a7d33-02eb-4935-b797-e0ddffb4aa55/element 200 36 ms - 137
2021-12-24 21:52:06:329 [HTTP] 
2021-12-24 21:52:06:331 [HTTP] --> GET /wd/hub/session/cf9a7d33-02eb-4935-b797-e0ddffb4aa55/element/00000000-0000-000a-ffff-ffff0000003c/displayed
2021-12-24 21:52:06:332 [HTTP] {}

The last GET might make the element active. It then posts a click.

    2021-12-24 21:52:06:933 [WD Proxy] Proxying [POST /element/00000000-0000-000a-ffff-ffff0000003c/click] to [POST http://127.0.0.1:8200/wd/hub/session/e0db4229-e013-4e42-99ba-2d7bbf151f7f/element/00000000-0000-000a-ffff-ffff0000003c/click] with body: {"element":"00000000-0000-000a-ffff-ffff0000003c"}

And eventually a POST is made using

2021-12-24 21:52:06:933 [WD Proxy] Proxying [POST /element/00000000-0000-000a-ffff-ffff0000003c/click] to [POST http://127.0.0.1:8200/wd/hub/session/e0db4229-e013-4e42-99ba-2d7bbf151f7f/element/00000000-0000-000a-ffff-ffff0000003c/click] with body: {"element":"00000000-0000-000a-ffff-ffff0000003c"}
2021-12-24 21:52:06:978 [WD Proxy] Got response with status 200: {"sessionId":"e0db4229-e013-4e42-99ba-2d7bbf151f7f","value":null}
2021-12-24 21:52:06:978 [W3C (cf9a7d33)] Responding to client with driver.click() result: null
2021-12-24 21:52:06:979 [HTTP] <-- POST /wd/hub/session/cf9a7d33-02eb-4935-b797-e0ddffb4aa55/element/00000000-0000-000a-ffff-ffff0000003c/click 200 46 ms - 14
2021-12-24 21:52:06:979 [HTTP] 
2021-12-24 21:52:06:993 [HTTP] --> POST /wd/hub/session/cf9a7d33-02eb-4935-b797-e0ddffb4aa55/actions
2021-12-24 21:52:06:993 [HTTP] {"actions":[{"type":"key","actions":[{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"},{"type":"keyDown","value":"u"},{"type":"keyUp","value":"u"},{"type":"keyDown","value":"d"},{"type":"keyUp","value":"d"},{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"}],"id":"default keyboard"}]}
2021-12-24 21:52:06:994 [W3C (cf9a7d33)] Calling AppiumDriver.performActions() with args: [[{"type":"key","actions":[{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"},{"type":"keyDown","value":"u"},{"type":"keyUp","value":"u"},{"type":"keyDown","value":"d"},{"type":"keyUp","value":"d"},{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"}],"id":"default keyboard"}],"cf9a7d33-02eb-4935-b797-e0ddffb4aa55"]

The JSON POST is this.

POST /wd/hub/session/cf9a7d33-02eb-4935-b797-e0ddffb4aa55/actions

with 

{"actions":[{"type":"key","actions":[{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"},{"type":"keyDown","value":"u"},{"type":"keyUp","value":"u"},{"type":"keyDown","value":"d"},{"type":"keyUp","value":"d"},{"type":"keyDown","value":"o"},{"type":"keyUp","value":"o"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"0"},{"type":"keyUp","value":"0"},{"type":"keyDown","value":"2"},{"type":"keyUp","value":"2"}],"id":"default keyboard"}]}

which is this:

{
    "actions": [
        {
            "type": "key",
            "actions": [
                {
                    "type": "keyDown",
                    "value": "o"
                },
                {
                    "type": "keyUp",
                    "value": "o"
                },
                {
                    "type": "keyDown",
                    "value": "2"
                },
                {
                    "type": "keyUp",
                    "value": "2"
                },
                {
                    "type": "keyDown",
                    "value": "u"
                },
                {
                    "type": "keyUp",
                    "value": "u"
                },
                {
                    "type": "keyDown",
                    "value": "d"
                },
                {
                    "type": "keyUp",
                    "value": "d"
                },
                {
                    "type": "keyDown",
                    "value": "o"
                },
                {
                    "type": "keyUp",
                    "value": "o"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "0"
                },
                {
                    "type": "keyUp",
                    "value": "0"
                },
                {
                    "type": "keyDown",
                    "value": "2"
                },
                {
                    "type": "keyUp",
                    "value": "2"
                }
            ],
            "id": "default keyboard"
        }
    ]
}

which is very verbose. Then a hide keyboard - no sign of an enter.

Then find and select the password field click that. And do the same. Eventually, a
carriage return or something and is completed.

 https://appium.io/docs/en/commands/interactions/actions/#actions

Only the WebDriverIO javascript driver has both Actions and Attach To Session.

On Cygwin using Windows installation of Nodejs.

https://digital.ai/catalyst-blog/how-to-get-started-using-webdriverio-with-experitest

and do their npx wdio config. Then try this:

https://github.com/webdriverio/appium-boilerplate.git

If you have Intellij Ultimate you can use JavaScript plugins and get the WebDriverIO
plugin.

You can add

    await browser.debug()

to any test to go into REPL mode.

I can't find any documentation on the debugger commands. It is the regular Node.js
debugger 

.exit
.help

and one can run any command, but not access the stack frame.

console.log('message')

  browser: this,
  driver: this,
  $: this.$.bind(this),
  $$: this.$$.bind(this)

.editor
.help


[  Local Variables: ]
[  mode:text ]
[  mode:outline-minor ]
[  mode:auto-fill ]
[  fill-column: 75 ]
[  coding: utf-8 ]
[  comment-column:50 ]
[  comment-start: "[  "  ]
[  comment-end:"]" ]
[  End: ]

