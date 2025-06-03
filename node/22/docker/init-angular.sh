#!/bin/bash

echo "Get SUDO credentials"
sudo ls -alF > /dev/null

[ ! -f ~/bin/init-node.sh ] || ~/bin/init-node.sh

sudo npm install -g @angular/cli

