#!/bin/bash

# install dependencies and helpful tools
sudo apt --yes update
echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

sudo apt --yes update
sudo apt --yes install code
sudo apt --yes install git
sudo apt --yes install openjdk-11-jdk
sudo apt --yes install python3.12
sudo apt --yes install python3-pip
sudo apt --yes install python3.12-venv
sudo apt --yes install dotnet-sdk-8.0

# switch to artifact user
su artifact

code --install-extension viper-admin.viper

# install nagini
cd
python3 -m venv venv
source venv/bin/activate
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

# install dafny
mkdir -p $HOME/dafny
cd /tmp
wget https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip
unzip /tmp/dafny-4.11.0-x64-ubuntu-22.04.zip -d $HOME/dafny
echo 'export PATH="$HOME/dafny/dafny:$PATH"' >> $HOME/.bashrc
source $HOME/.bashrc
cd

# done
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "The installation of the Aritfact is done!"