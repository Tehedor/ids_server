#!/bin/bash
# Descargar ossec y instalar
sudo apt -y install libz-dev libssl-dev libpcre2-dev build-essential libsystemd-dev
curl -L -o ./ossec.3.8.0.tar.gz https://github.com/ossec/ossec-hids/archive/refs/tags/3.8.0.tar.gz
tar -xzvf ./ossec.3.8.0.tar.gz
## Configuraciones para la instalacion
cat <<EOF > ./ossec-hids-3.8.0/install.cfg.sh
USER_LANGUAGE="en"
USER_NO_STOP="y"
USER_INSTALL_TYPE="local"
USER_DIR="/var/ossec"
USER_ENABLE_EMAIL="n"
USER_ENABLE_SYSCHECK="y"
USER_ENABLE_ROOTCHECK="y"
USER_ENABLE_ACTIVE_RESPONSE="y"
USER_ENABLE_FIREWALL_RESPONSE="y"
USER_WHITE_LIST="127.0.0.1"
EOF
## Instalacion
sudo  ./ossec-hids-3.8.0/install.sh


## Configuracioens de ossec
sudo cp ./config/ossec.conf /var/ossec/etc/ossec.conf
sudo cp ./config/local_rules.xml /var/ossec/rules/local_rules.xml


## Arrancar ossec
sudo /var/ossec/bin/ossec-control start
