# Manual Installation Script

#Cloning Repo and Building Binary
cd || return
rm -rf <GITHUB REPO>
git clone <GITHUB><GITHUB REPO>.git
cd <GITHUB REPO> || return
git fetch --tags
git checkout <VERSION>
make all
<BINARY> version

# initialising Binary and Adjusting Fess and Peers
<BINARY> init $NODE_MONIKER --chain-id <CHAINID>
curl https://raw.githubusercontent.com/ODIN-PROTOCOL/networks/master/mainnets/odin-mainnet-freya/genesis.json > <DIRECTORY>/config/genesis.json

perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0.0125<DENOM>"/' <DIRECTORY>/config/app.toml

SEEDS="<SEEDS>"
PEERS="<PEERS>"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' <DIRECTORY>/config/config.toml
 
# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' <DIRECTORY>/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' <DIRECTORY>/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' <DIRECTORY>/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' <DIRECTORY>/config/app.toml
 
#Setting Up Service
sudo tee /etc/systemd/system/<BINARY>.service > /dev/null << EOF
[Unit]
Description=<CHAINID> Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which <BINARY>) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
 
# Setting Up Statesync
<BINARY> tendermint unsafe-reset-all --home <DIRECTORY>/ --keep-addr-book
 
SNAP_RPC="<SNAP_RPC>"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

# Displaying Height and hash
echo "TRUST HEIGHT: $BLOCK_HEIGHT"
echo "TRUST HASH: $TRUST_HASH"

# editing config.toml with correct values
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; <DIRECTORY>/config/config.toml
 
# Enabling and Restarting Service
sudo systemctl daemon-reload
sudo systemctl enable <BINARY>
sudo systemctl restart <BINARY>
