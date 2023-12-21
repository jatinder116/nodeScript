#!/bin/bash
HOMEDIR="$HOME/.tmp-shidod"
KEYRING="test"

ADDRESS=$(shidod keys list --home $HOMEDIR --keyring-backend $KEYRING | grep "address" | cut -c12-)
echo $ADDRESS

#========== for creating validator ==========================================================================
shidod tx staking create-validator --amount=100000000000000000000shido   --pubkey=$(shidod tendermint show-validator --home $HOMEDIR)   --moniker="validator"   --chain-id=shido_9007-1   --commission-rate="0.10"   --commission-max-rate="0.20"   --commission-max-change-rate="0.01"   --min-self-delegation="10"   --gas="auto"   --gas-prices="0.025shido"   --from=$ADDRESS  --gas="auto" --gas-adjustment="1.15" --home $HOMEDIR --keyring-backend $KEYRING