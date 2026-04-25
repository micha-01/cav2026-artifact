#!/bin/bash

# install dependencies and helpful tools
echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

sudo apt --yes update
sudo apt --yes install code
sudo apt --yes install git
sudo apt --yes install openjdk-11-jdk
sudo apt --yes install python3.12
sudo apt --yes install python3-pip
sudo apt --yes install python3.12-venv

code --install-extension viper-admin.viper

# install nagini
git clone https://github.com/micha-01/Nagini.git
cd Nagini
git checkout object_equality
pip3 install .
cd ..

# download other files in the artifact (logs, tutorial)
git init
git remote add origin https://github.com/micha-01/cav2026-artifact.git
git fetch origin
git checkout -b main --track origin/main
