#!/bin/bash

mysqlUrl="http://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm"

cd /vagrant/

echo -e "VAGRANT_INSTALLER: Determining Appian Version...\n"
#Determine Version to be installed based on installer file
appianVersion=$(ls setupLinux* | awk -F '-' '{print $2}' | awk -F '.' '{print $1"."$2}')
echo -e "VAGRANT_INSTALLER: Appian version "$appianVersion" found...\n" 

#Setup Configuration Files for Appian Version
configurationFilesDir=$appianVersion"ConfigurationFiles"
if [ -d $configurationFilesDir ];then
  echo -e "VAGRANT_INSTALLER: Using files in "$configurationFilesDir"\n"
else
  echo -e "VAGRANT_INSTALLER: No configuration files present for this version of Appian... Exiting..."
  echo -e $uncleanExitMessage
  exit 1
fi

#Install MySQL
#mysqlFile=$(curl -O http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm)
sudo rpm -ivh $mysqlUrl
sudo yum-config-manager --disable mysql80-community
sudo yum-config-manager --enable mysql57-community
sudo yum -y install mysql-community-server
sudo service mysqld start
#mysql_secure_installation
sudo chkconfig mysqld on
#Get temp MySQL Root password
password_match=$(sudo awk '/A temporary password is generated for/ {a=$0} END{ print a }' /var/log/mysqld.log | awk '{print $(NF)}')
#Required to reset password before enacting further changes in MySQL
mysql  -u root -p$password_match --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'PassW0rd#'; flush privileges; "
#Uninstall Validate Password plugin in MySQL
mysql  -u root -pPassW0rd# --connect-expired-password -e "uninstall plugin validate_password;"
#Run script to configure MySQL
#Sets root password via this script as well
mysql -u root -pPassW0rd# < /vagrant/$configurationFilesDir/create-databases.sql
echo -e "VAGRANT_INSTALLER: MySQL installed and configured...\n"

exit