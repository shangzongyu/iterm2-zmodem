#!/usr/bin/env bash

#
# iterm2-zmodem
#
# copyright (c) 2013 by Harald Lapp <harald@octris.org>
#
# AppleScript portion from:
# http://stackoverflow.com/questions/4309087/cancel-button-on-osascript-in-a-bash-script
# licensed under cc-wiki with attribution required
#

#
# This script can be found at:
# https://github.com/aurora/iterm2-zmodem
#

#
# This is a re-implementation of the shell scripts "iterm2-recv-zmodem.sh" and
# "iterm2-send-zmodem.sh" found at https://github.com/mmastrac/iterm2-zmodem
#

# usage
if [[ $1 != "sz" && $1 != "rz" ]]; then
  echo "usage: $0 sz|rz"
  exit
fi

# send Z-Modem cancel sequence
function cancel {
  echo -e \\x18\\x18\\x18\\x18\\x18
}

# send notification using growlnotify
function notify {
  local msg=$1

  if command -v growlnotify >/dev/null 2>&1; then
      growlnotify -a /Applications/iTerm.app -n "iTerm" -m "$msg" -t "File transfer"
  else
      echo "# $msg" | tr '\n' ' '
  fi
}

#setup
[[ $LRZSZ_PATH != "" ]] && LRZSZ_PATH=":$LRZSZ_PATH" || LRZSZ_PATH=""

PATH=$(command -p getconf PATH):/usr/local/bin$LRZSZ_PATH
ZCMD=$(
  if command -v $1 >/dev/null 2>&1; then
      echo "$1"
  elif command -v l$1 >/dev/null 2>&1; then
      echo "l$1"
  fi
)

# main
if [[ $ZCMD = "" ]]; then
  cancel
  echo

  notify "Unable to find Z-Modem tools"
  exit
elif [[ $1 = "rz" ]]; then
  # receive a file
  DST=$(
      osascript \
          -e "tell application \"iTerm\" to activate" \
          -e "tell application \"iTerm\" to set thefile to choose folder with prompt \"Choose a folder to place received files in\"" \
          -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"
  )

  if [[ $DST = "" ]]; then
      cancel
      echo
  fi

cd "$DST"

  notify "Z-Modem started receiving file"

  $ZCMD -e -y
  echo

  notify "Z-Modem finished receiving file"
else
  # send a file
  SRC=$(
      osascript \
          -e "tell application \"iTerm\" to activate" \
          -e "tell application \"iTerm\" to set thefile to choose file with prompt \"Choose a file to send\"" \
          -e "do shell script (\"echo \"&(quoted form of POSIX path of thefile as Unicode text)&\"\")"
  )

  if [[ $SRC = "" ]]; then
      cancel
      echo
  fi

  notify "Z-Modem started sending
$SRC"

  $ZCMD -e "$SRC"
  echo

  notify "Z-Modem finished sending
$SRC"
echo
fi
