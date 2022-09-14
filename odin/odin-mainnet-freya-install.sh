#!/bin/bash
set -e
clear 
source <(curl -s https://raw.githubusercontent.com/BadgerbiteInfo/scripts/main/utils/common.sh)
printLogo

SCRIPT_VERSION="v1.0.0"


PURPLE='\033[0;35m'
BOLD="\033[1m"
BLUE='\033[1;34m'
# ITALIC="\033[3m"
NC="\033[0m"
LOG_FILE="install.log"

GITHUB="https://github.com/ODIN-PROTOCOL/odin-core.git"
GENESIS_URL="https://raw.githubusercontent.com/ODIN-PROTOCOL/networks/master/mainnets/odin-mainnet-freya/genesis.json"
CHAIN_NAME="Odin Protocol"
CHAIN_ID="odin-mainnet-freya"
BINARY="odind"
HOME_FOLDER="$HOME/.odin"
LOG_PATH=$HOME_FOLDER/$LOG_FILE
BINARY_VERSION="v0.6.0"
BINARY_LOCATION="$HOME/go/bin"
SNAP_RPC="http://34.79.179.216:26657,http://34.140.252.7:26657,http://35.241.221.154:26657,http://35.241.238.207:26657"
RPC_ADDR="http://34.79.179.216:26657"
SERVICE_FILE="/etc/systemd/system/$BINARY.service"

SEEDS="4529fc24a87ff5ab105970f425ced7a6c79f0b8f@odin-seed-01.mercury-nodes.net:29536,c8ee9f66163f0c1220c586eab1a2a57f6381357f@odin.seed.rhinostake.com:16658"
PEERS="9d16b1ce74a34b869d69ad5fe34eaca614a36ecd@35.241.238.207:26656,02e905f49e1b869f55ad010979931b542302a9e6@35.241.221.154:26656,4847c79f1601d24d3605278a0183d416a99aa093@34.140.252.7:26656,0165cd0d60549a37abb00b6acc8227a54609c648@34.79.179.216:26656"

printf "\n\n${BOLD}Welcome to BadgerBite setup script for ,%s" "${PURPLE}$CHAIN_NAME${NC}!\n\n"
printf "This script will guide you through setting up your very own node locally.\n"
printf "You're currently running %s" "$BOLD$SCRIPT_VERSION$NC of the setup script.\n\n"
printf "Before we begin, let's make sure you have all the required dependencies installed.\n"
DEPENDENCIES=( "git" "go" "jq" "lsof" "gcc" "make" )
missing_deps=false
for dep in "${DEPENDENCIES[@]}"; do
    printf "\t%-8s" "$dep..."
    if [[ $(type "$dep" 2> /dev/null) ]]; then
        printf '%s' "$BLUE\xE2\x9C\x94$NC\n" # checkmark
    else
        missing_deps=true
        printf '%s' "$PURPLE\xE2\x9C\x97$NC\n" # X
    fi
done
if [[ $missing_deps = true ]]; then
    printf "\nInstalling/Updating Dependencies!\n"
    source <(curl -s https://raw.githubusercontent.com/BadgerbiteInfo/scripts/main/utils/dependencies_install.sh)
fi
printf "\nAwesome, you're all set.\n"

printline

printf "\nNext, we need to give your node a nickname. "
node_name_prompt="What would you like to call it? "
while true; do
    read -p "$(printf $PURPLE"$node_name_prompt"$NC)" NODE_NAME
    if [[ ! "$NODE_NAME" =~ ^[A-Za-z0-9-]+$ ]]; then
        printf '\nNode names can only container letters, numbers, and hyphens.\n'
        node_name_prompt="Please enter a new name. "
    else
        break
    fi
done

printline
echo -e "Node moniker: ${BLUE}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${BLUE}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${BLUE}$CHAIN_DENOM${NC}"
printline
sleep 1

printf "\nGreat, now we'll download the latest version of ${PURPLE}{$CHAIN_NAME$}{NC}.\n"
printf "${PURPLE}{$CHAIN_NAME$}{NC} will keep track of blockchain state in ${BOLD}{$HOME_FOLDER$}{NC}\n\n"

if [ -d "$HOME_FOLDER" ] 
then
    printf "${BOLD}Looks like you already have ${PURPLE}{$CHAIN_NAME$}{NC} installed.${NC}\n"
    printf "Proceed carefully, because you won't be able to recover your data if you overwrite it.\n\n\n"
    printf "${BOLD}${BLUE}Make sure you have you've backed up your mnemonics or private keys!\nIf you lose your private key, you will not be able to claim your rewards!${NC}\n\n"
    printf "${BOLD}Run \ {$BINARY} keys export {NAME_OF_YOUR_KEY}\" to export your key, and save the info down.${NC}\n\n"
    sleep 3
    pstr="Please confirm that you have backed up your private keys. [y/n] "
    while true; do
        read -p "$(printf "$PURPLE""$pstr""$NC")" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) printf 'Please answer yes or no.\n';;
        esac
    done
    pstr="Do you want to overwrite your existing {$CHAIN_ID} installation and proceed? [y/n] "
    while true; do
        read -p "$(printf "$PURPLE""$pstr""$NC")" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) printf 'Please answer yes or no.\n';;
        esac
    done
sudo systemctl stop odind && sudo systemctl disable odind && sudo rm /etc/systemd/system/odind.service && sudo systemctl daemon-reload && rm -rf "$HOME"/.odin && rm -rf "$HOME"/odin-core && rm $(which odind) >> "$LOG_PATH" 2>&1 
printline
fi


printf "4. Building binaries..." && sleep 1
printline
cd || return
rm -rf odin-core
git clone $GITHUB >> "$LOG_PATH" 2>&1
cd odin-core || return
git fetch --tags
git checkout $BINARY_VERSION >> "$LOG_PATH" 2>&1
make all >> "$LOG_PATH" 2>&1
$BINARY version

$BINARY init "$NODE_MONIKER" --chain-id $CHAIN_ID >> "$LOG_PATH" 2>&1
 
curl $GENESIS_URL > "$HOME_FOLDER"/config/genesis.json
sha256sum "$HOME_FOLDER"/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea
 
perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0.0125loki"/' "$HOME_FOLDER"/config/app.toml
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' "$HOME"/.odin/config/config.toml


while true; do
    read -p "$(printf "$PURPLE""Do you want to apply recommended prining settings(custom,100,10,0)? [y/n] ""$NC")" yn
    case $yn in
        [Yy]* ) pruning_setup; break;;
        [Nn]* ) break;;
        * ) printf 'Please answer yes or no.\n';;
    esac
done

pruning_setup() {
# in case of pruning
printf "Applying Pruning Settings..." && sleep 1
sed -i 's|pruning = "default"|pruning = "custom"|g' "$HOME_FOLDER"/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' "$HOME_FOLDER"/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' "$HOME_FOLDER"/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' "$HOME_FOLDER"/config/app.toml
}


# setting up state sync
printf "Setting up Statesync Synchronization..." && sleep 1
odind tendermint unsafe-reset-all --home "$HOME_FOLDER" --keep-addr-book
INTERVAL=2000
LATEST_HEIGHT=$(curl -s $RPC_ADDR/block | jq -r .result.block.header.height);
BLOCK_HEIGHT=$(($LATEST_HEIGHT-$INTERVAL))
TRUST_HASH=$(curl -s "$RPC_ADDR/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
# Displaying Height and hash
echo "TRUST HEIGHT: $BLOCK_HEIGHT"
echo "TRUST HASH: $TRUST_HASH"
# editing config.toml with correct values
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; $HOME_FOLDER/config/config.toml


printf "5. Starting service and synchronization..." && sleep 

while true; do
    read -p '$(printf "$PURPLE""Do you want to setup Cosmovisor?Cosmovisor is a tool to monitor and setup chain updates automatically [y/n] ""$NC")' yn
    case $yn in
        [Yy]* ) cosmovisor_setup; break;;
        [Nn]* ) binary_setup; break;;
        * ) printf 'Please answer yes or no.\n';;
    esac
done

cosmovisor_setup() {
	if [[ -f $COSMOVISOR_BINARY ]]; then
		COSMOVISOR_BINARY=$BINARY_LOCATION/cosmovisor
    	printf "\nIt looks like you already have it installed! in {$COSMOVISOR_BINARY}\n"

    	cosmovisor_version=$($COSMOVISOR_BINARY version | grep Version | awk '{print $3}')
    	if [[ "$cosmovisor_version" != "v1.1.0" ]]; then
        	printf "\nHowever, you'll need to run version v1.1.0 for Stride.\n"
        	pstr="\nDo you want to overwrite your current version? [y/n] "
        	while true; do
            	read -p "$(printf $PURPLE"$pstr"$NC)" yn
            	case $yn in
                	[Yy]* ) overwrite=true; break ;;
                	[Nn]* ) overwrite=false; break ;;
                	* ) printf "Please answer yes or no.\n";;
            	esac
        	done

        	if [ $overwrite = true ]; then 
            	printf "\nInstalling now!\n"
            	rm $COSMOVISOR_BINARY
            	install_cosmovisor 
        	else 
            	COSMOVISOR_BINARY="${COSMOVISOR_BINARY}-v1.1.0"
            	printf "\nNo problem We will download to ${COSMOVISOR_BINARY} instead.\n"
            	install_cosmovisor -v1.1.0
        	fi
    	fi
	else 
    	printf "\nInstalling now!\n"
    	install_cosmovisor
	fi
}

binary_setup() {
	sudo touch $SERVICE_FILE
	sudo tee $SERVICE_FILE > /dev/null << EOF
	[Unit]
	Description="{$BINARY} Node"
	After=network-online.target
	[Service]
	User=$USER
	ExecStart=$(which odind) start
	Restart=on-failure
	RestartSec=10
	LimitNOFILE=10000
	[Install]
	WantedBy=multi-user.target
	EOF

}
install_cosmovisor() {
   	suffix=$1 # optional
    printf "This one might take a few minutes...\n"

    cd $HOME_FOLDER
    git clone https://github.com/cosmos/cosmos-sdk >> $LOG_PATH 2>&1
    cd cosmos-sdk 
    git checkout cosmovisor/v1.1.0 >> $LOG_PATH 2>&1
    make cosmovisor >> $LOG_PATH 2>&1
    mv $HOME_FOLDER/cosmovisor/cosmovisor "$BINARY_LOCATION/cosmovisor${suffix}"

    cd ..
    rm -rf cosmos-sdk
	
# Setup cosmovisor
	cosmovisor_home=$HOME_FOLDER/cosmovisor
	mkdir -p $cosmovisor_home/genesis/bin
	mkdir -p $cosmovisor_home/upgrades
	cp "$BINARY_LOCATION/$BINARY" "$cosmovisor_home/genesis/bin/"

	sudo touch $SERVICE_FILE
	sudo tee $SERVICE_FILE > /dev/null <<EOF
	[Unit]
	Description="{$BINARY} Node"
	After=network.target

	[Service]
	User=$USER
	Type=simple
	Environment=DAEMON_NAME=$BINARY
	Environment=DAEMON_HOME=$HOME_FOLDER
	Environment=DAEMON_RESTART_AFTER_UPGRADE=true
	ExecStart=$COSMOVISOR_BINARY run start
	Restart=on-failure
	LimitNOFILE=65535

	[Install]
	WantedBy=multi-user.target
	EOF
}
printf $BLINE
while true; do
    read -p '$(printf $PURPLE"Do you want to launch your blockchain? [y/n] "$NC)' yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) printf 'Please answer yes or no.\n';;
    esac
done
# kill ports if they're already running
PORT_NUMBER=6060
lsof -i tcp:${PORT_NUMBER} | awk 'NR!=1 {print $2}' | xargs -r kill
PORT_NUMBER=26657
lsof -i tcp:${PORT_NUMBER} | awk 'NR!=1 {print $2}' | xargs -r kill 
# we likely don't need to kill this - look into why this is causing issues
PORT_NUMBER=26557
lsof -i tcp:${PORT_NUMBER} | awk 'NR!=1 {print $2}' | xargs -r kill
sudo systemctl daemon-reload && \
sudo systemctl enable strided.service && \
sudo systemctl restart strided.service && \
sudo journalctl -u strided.service -f -o cat
