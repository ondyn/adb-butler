#!/usr/bin/env bash

DL=/tmp/devices_list

rm -f $DL
touch -f $DL
sleep 10

cd / || exit

function clean_agoda_staff {
  local DEVICE=$1

  echo -n | timeout -t 30 adb -s $DEVICE shell rm -rf /sdcard/fork /sdcard/marathon /sdcard/screenshotEspressoTesting

  # echo -n | timeout -t 30 adb -s $DEVICE uninstall com.agoda.mobile.consumer.debug.test
  # echo -n | timeout -t 30 adb -s $DEVICE uninstall com.agoda.mobile.consumer.debug
  # echo -n | timeout -t 30 adb -s $DEVICE uninstall com.agoda.mobile.consumer
  # echo -n | timeout -t 30 adb -s $DEVICE uninstall com.agoda.mobile.swipe.debug.test
  # echo -n | timeout -t 30 adb -s $DEVICE uninstall com.agoda.mobile.swipe.debug
}

function setup_emulator {
  local DEVICE=$1
  local MARATHON_SERIAL
  MARATHON_SERIAL=$(timeout -t 30 adb -s $DEVICE shell getprop marathon.serialno  | tr -d '\r')

  if [ -z "$MARATHON_SERIAL" ]; then
    local SERIAL
    SERIAL=`hostname`
    timeout -t 30 adb -s $DEVICE shell su root setprop marathon.serialno $SERIAL
    timeout -t 30 adb -s $DEVICE shell su root pm disable org.chromium.webview_shell
    timeout -t 30 adb -s $DEVICE shell su root settings put secure spell_checker_enabled 0
    if [ ! -z "$EMULATOR_TIMEZONE" ]; then
      timeout -t 30 adb -s $DEVICE shell su root setprop persist.sys.timezone "$EMULATOR_TIMEZONE"
    fi
  fi
}

while sleep 1; do
  echo -n | adb devices | egrep 'device$' | awk '{ print $1 }' | sort > $DL.new
  diff -u $DL $DL.new | grep '^[+][^+]' | sed -E 's/^\+//' | while read d; do

    echo Connected $d

    clean_agoda_staff $d
  done

  if [ ! -z "$STF_PROVIDER_PUBLIC_IP" ]; then
    for d in `cat $DL.new`; do
      # Emulator
      setup_emulator $d
    done
  fi

  mv $DL.new $DL
done
