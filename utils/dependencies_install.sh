#!/bin/bash
LOG_FILE="install.log"
LOG_PATH=$HOME_FOLDER/$LOG_FILE


source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printCyan "1. Updating packages..." && sleep 1
sudo apt update  >> "$LOG_PATH" 2>&1

printCyan "2. Installing dependencies..." && sleep 1
sudo apt install -y make gcc jq curl git lz4 build-essential chrony  >> "$LOG_PATH" 2>&1

printCyan "3. Installing go..." && sleep 1
if [ ! -f "/usr/local/go/bin/go" ]; then
  source <(curl -s "https://raw.githubusercontent.com/BadgerbiteInfo/scripts/main/utils/go_install.sh")
  source .bash_profile
fi

echo "$(go version)"
