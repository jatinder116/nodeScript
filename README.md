# Setup node and a validator script

This repository contains a script for setting up a node and a validator on shido blockchain. 


## Installation

Prerequisites:

System Requirements:
    4 or more physical CPU cores.
    At least 200GB disk storage.
    At least 16GB of memory (RAM)
    At least 100mbps network bandwidth.


#### Clone this repo using:
```bash
git clone [TODO]

```
## Setup a node first:

open a terminal window and run the following command
[Verify permission of that file]
```bash
./shido_ubuntu_node.sh (it's for ubuntu os)
```

for mac run this script 
```bash
./shido_mac_Script.sh (it's for MAC os)
```

**NOTE:** The blockchain syncing is running in a background as a service you can print the logs and check the logs of the node with the following command.
```bash
journalctl -u shido -f (it's for ubuntu)
```
for mac logs run this
```bash
tail -f $HOME/logfile.log (it's for mac)
```

Then after this wait for the node syncing when node synscing is complete then copy this address and send to us
```bash

```
Then send that address to our channel we will send some funds to create a validator of this address.

## Setup a validator

1. open the same terminal and run following command
```bash
./validator_script.sh
```
after this successfully created a validator
```