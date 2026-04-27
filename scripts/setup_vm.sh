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
sudo -u artifact bash << 'EOF'
USER_HOME="/home/artifact"
set -e

code --install-extension viper-admin.viper

# install nagini
cd $USER_HOME
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
cd /tmp
wget https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip
unzip /tmp/dafny-4.11.0-x64-ubuntu-22.04.zip -d $USER_HOME
cd $USER_HOME

EOF

ln -sf /home/artifact/dafny/dafny /usr/local/bin/dafny

# done
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "-------------------------------------------------------------"
echo "The installation of the Aritfact is done!"