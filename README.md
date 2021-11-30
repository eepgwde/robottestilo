# Control #

weaves

# Android Development #

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

