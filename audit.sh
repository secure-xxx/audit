#!/bin/bash
key="###SECRET###"
echo "
                                                        xxx   xxx
 xxxx   xxxxx   xxxxx   xxx  xx  xxxxxx  xxxxx           xxx xxx
 xx      xx      xx  xx  xx  xx   xx  xx  xx              xxxxx
  xxxx   xxxx    xx      xx  xx   xxxxx   xxxx   xxxxx     xxx
     xx  xx      xx  xx  xx  xx   xx  xx  xx              xxxxx
  xxxx   xxxxx    xxxx    xxxx    xx  xx  xxxxx          xxx xxx
                                                        xxx   xxx"
echo "CREATING TEMPORARY FOLDER..."
mkdir /tmp/LOGS
mkdir /tmp/ZIP
echo "COLLECTING INFO..."
uname -a > /tmp/LOGS/DISTRIB.txt
lshw -short > /tmp/LOGS/HARDWARE.txt
lscpu > /tmp/LOGS/CPU.txt
lsblk > /tmp/LOGS/BLOCK.txt
fdisk -l > /tmp/LOGS/DISK.txt
echo "COLLECTING UPDATES..."
grep "install " /var/log/dpkg.log > /tmp/LOGS/INSTALL.txt
grep "update " /var/log/dpkg.log > /tmp/LOGS/UPDATE.txt
echo "COLLECTING PACKAGES..."
apt list --installed > /tmp/LOGS/PACKAGES.txt 2>&1 >/dev/null
echo "CHECKING OPEN PORTS & CONNECTIONS"
ss -l > /tmp/LOGS/PORTS.txt
echo "CHECKING SECURITY LOGS"
less /var/log/auth.log > /tmp/LOGS/AUTH.txt
last /tmp/LOGS/LAST.txt
history > /tmp/LOGS/HISTORY.txt
echo "CREATING ARCHIVE..."
fqdn="$(hostname)"
zip -rq /tmp/ZIP/$fqdn.zip /tmp/LOGS/ 
echo "UPLOADING FILES..."
curl -F key=$key -F myfqdn=$(hostname) -F content=$(openssl base64 < /tmp/ZIP/$(hostname).zip | tr -d "\n") https://data.secure-x.ru
echo "CLEANUP..."
rm -rf /tmp/LOGS
rm -rf /tmp/ZIP
