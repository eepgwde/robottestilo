shell 'getprop ro.build.version.sdk'
shell 'getprop ro.build.version.release'
shell 'settings put global hidden_api_policy_pre_p_apps 1;settings put global hidden_api_policy_p_apps 1;settings put global hidden_api_policy 1'
wait-for-device
shell 'dumpsys package io.appium.settings'
shell 'echo ping'
