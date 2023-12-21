#!/bin/bash

# Check if the script is run as root
#if [ "$(id -u)" != "0" ]; then
#  echo "This script must be run as root or with sudo." 1>&2
#  exit 1
#fi
current_path=$(pwd)
bash  $current_path/install-go.sh 
bash install-go.sh
source ~/.bashrc
ulimit -n 16384

# Get OS and version
OS=$(awk -F '=' '/^NAME/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')
VERSION=$(awk -F '=' '/^VERSION_ID/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')

# Define the binary and installation paths
BINARY="shidod"
INSTALL_PATH="/usr/local/bin/"

# Check if the OS is Ubuntu and the version is either 20.04 or 22.04
if [ "$OS" == "Ubuntu" ] && [ "$VERSION" == "20.04" -o "$VERSION" == "22.04" ]; then
  # Copy and set executable permissions
  current_path=$(pwd)
  
  # Update package lists and install necessary packages
  sudo  apt-get update
  sudo apt-get install -y build-essential jq wget unzip
  
  # Check if the installation path exists
  if [ -d "$INSTALL_PATH" ]; then
  sudo  cp "$current_path/ubuntu${VERSION}build/$BINARY" "$INSTALL_PATH" && sudo chmod +x "${INSTALL_PATH}${BINARY}"
    echo "$BINARY installed or updated successfully!"
  else
    echo "Installation path $INSTALL_PATH does not exist. Please create it."
    exit 1
  fi
else
  echo "Please check the OS version support; at this time, only Ubuntu 20.04 and 22.04 are supported."
  exit 1
fi
wget https://testnet-blockchain-shido.s3.us-west-2.amazonaws.com/shido_snapshot_12122023.zip
#==========================================================================================================================================
KEYS="alice"
CHAINID="shido_9007-1"
MONIKER="shidonode"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"

# Set dedicated home directory for the shidod instance
HOMEDIR="$HOME/.tmp-shidod"

# Path variables
CONFIG=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
CLIENT=$HOMEDIR/config/client.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# validate dependencies are installed
command -v jq >/dev/null 2>&1 || {
	echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
	exit 1
}

# used to exit on first error
set -e

# User prompt if an existing local node configuration is found.
if [ -d "$HOMEDIR" ]; then
	printf "\nAn existing folder at '%s' was found. You can choose to delete this folder and start a new local node with new keys from genesis. When declined, the existing local node is started. \n" "$HOMEDIR"
	echo "Overwrite the existing configuration and start a new local node? [y/n]"
	read -r overwrite
else
	overwrite="Y"
fi

# Setup local node if overwrite is set to Yes, otherwise skip setup
if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
	# Remove the previous folder
	rm -rf "$HOMEDIR"

	# Set client config
	shidod config keyring-backend $KEYRING --home "$HOMEDIR"
	shidod config chain-id $CHAINID --home "$HOMEDIR"
	shidod keys add $KEYS --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
	shidod init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"

	#changes status in app,config files
    sed -i 's/timeout_commit = "3s"/timeout_commit = "1s"/g' "$CONFIG"
    sed -i 's/seeds = ""/seeds = ""/g' "$CONFIG"
    sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
    sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
    sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
    sed -i 's/enable = false/enable = true/g' "$APP_TOML"
    sed -i 's/swagger = false/swagger = true/g' "$APP_TOML"
	sed -i 's/localhost/0.0.0.0/g' "$APP_TOML"
    sed -i 's/localhost/0.0.0.0/g' "$CONFIG"
    sed -i 's/localhost/0.0.0.0/g' "$CLIENT"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_TOML"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CONFIG"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CLIENT"


	# Allocate genesis accounts (cosmos formatted addresses)
	shidod add-genesis-account $KEYS 100000000000000000000000000000shido --keyring-backend $KEYRING --home "$HOMEDIR"

	# Sign genesis transaction
	shidod gentx ${KEYS} 10000000000000000000000000shido --keyring-backend $KEYRING --chain-id $CHAINID --home "$HOMEDIR"
	
	# Collect genesis tx
	shidod collect-gentxs --home "$HOMEDIR"

	# these are some of the node ids help to sync the node with p2p connections
	sed -i 's/persistent_peers \s*=\s* ""/persistent_peers = "921f45bb53e5e7a4513430c4b671da292642b5ac@35.82.44.23:26656,5c13bb103064530e78ff995c05685b167937a533@100.21.69.117:26656,73687134488068c4d087c0c2aed67bebe708bfa5@44.236.180.179:26656,d8e0ae5b80a67e790d63ee3ce8803c6a04327b3f@44.227.80.206:26656,f3c5c13ca3854181ff49d7910d3371f669a3a300@13.48.225.44:26656,a9411441c88e28a72370d5999d66d1d9d238b001@51.20.229.181:26656,2bb78d1c5c62ba6a509f4bb36e186d8329ef51b2@51.20.246.183:26656"/g' "$CONFIG"

	# remove the genesis file from binary
	rm -rf $HOMEDIR/config/genesis.json

	# paste the genesis file
	cp $current_path/genesis.json $HOMEDIR/config

	# Run this to ensure everything worked and that the genesis file is setup correctly
	shidod validate-genesis --home "$HOMEDIR"

 	cd $HOMEDIR/data
	unzip	$current_path/shido_snapshot_12122023.zip

	ADDRESS=$(shidod keys list --home $HOMEDIR --keyring-backend $KEYRING | grep "address" | cut -c12-)
	WALLETADDRESS=$(shidod debug addr $ADDRESS --home $HOMEDIR --keyring-backend $KEYRING | grep "Address (EIP-55)" | cut -c12-)
	echo "========================================================================================================================"
	echo "Shido Eth Hex Address==== "$WALLETADDRESS
	echo "========================================================================================================================"

fi

#========================================================================================================================================================
# Start the node
# shidod start --home "$HOMEDIR"
sudo su -c  "echo '[Unit]
Description=shidod Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/shidod start --home $HOMEDIR
Restart=always

Environment=HOME=$HOMEDIR

[Install]
WantedBy=multi-user.target'> /etc/systemd/system/shido.service"


sudo systemctl daemon-reload
sudo systemctl enable shido.service
sudo systemctl start shido.service
