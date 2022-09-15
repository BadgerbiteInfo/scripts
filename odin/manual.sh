# Manual Installation Script

#Cloning Repo and Building Binary
cd || return
rm -rf odin-core
git clone https://github.com/ODIN-PROTOCOL/odin-core.git
cd odin-core || return
git fetch --tags
git checkout v0.6.0
make all
<BINARY> version

# initialising Binary and Adjusting Fess and Peers
<BINARY> init $NODE_MONIKER --chain-id $CHAIN_ID
curl https://raw.githubusercontent.com/ODIN-PROTOCOL/networks/master/mainnets/odin-mainnet-freya/genesis.json > <DIRECTORY>/config/genesis.json
sha256sum <DIRECTORY>/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea
 
perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0.0125<DENOM>"/' <DIRECTORY>/config/app.toml

SEEDS="4529fc24a87ff5ab105970f425ced7a6c79f0b8f@odin-seed-01.mercury-nodes.net:29536,c8ee9f66163f0c1220c586eab1a2a57f6381357f@odin.seed.rhinostake.com:16658"
PEERS="9d16b1ce74a34b869d69ad5fe34eaca614a36ecd@35.241.238.207:26656,02e905f49e1b869f55ad010979931b542302a9e6@35.241.221.154:26656,4847c79f1601d24d3605278a0183d416a99aa093@34.140.252.7:26656,0165cd0d60549a37abb00b6acc8227a54609c648@34.79.179.216:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' <DIRECTORY>/config/config.toml
 
# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' <DIRECTORY>/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' <DIRECTORY>/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' <DIRECTORY>/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' <DIRECTORY>/config/app.toml
 
#Setting Up Service
sudo tee /etc/systemd/system/<BINARY>.service > /dev/null << EOF
[Unit]
Description=Odin Node
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
