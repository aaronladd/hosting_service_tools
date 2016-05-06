#!/bin/bash
#concrete 5 installer downloads a set file, unzips it, manipulates the fils and deletes the zip
con5_install(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nThis tool downloads and extracts Concrete 5 version 5.7.3.1." \ 
			"You'll need to have the customer walk through basic setup including entering the DB info."
	else
		echo -e "\nDownloading files."
		wget -q http://concrete5.org/download_file/-/view/74619/concrete5.7.3.1.zip 
		echo -e "Unzipping.\n"
		unzip -qq ./concrete5.7.3.1.zip 
		echo -e "Moving and Grooving\n"
		mv ./concrete5.7.3.1/* . 
		rm -rf concrete5.7.*
	fi
}
#Joomla 3.3.6 installer, downloads, extracts and deletes the archive
joom_install(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
       		echo -e "\nThis tool downloads and extracts Joomla 3.3.6 Stable." \ 
			"The customer or you will have to go through basic setup in cluding entering the DB info."
	else
		echo -e "\nDownloading files."
		wget -q http://joomlacode.org/gf/download/frsrelease/19822/161255/Joomla_3.3.6-Stable-Full_Package.tar.gz 
		echo -e "Unzipping."
		tar xzf ./Joomla_3.3.6-Stable-Full_Package.tar.gz
		echo -e "Moving and Grooving\n"
		rm -rf Joomla_3.3.6-Stable-Full_Package.tar.gz
	fi
}
#Drupal 7 installer, downloads, extracts, moves the files to the correct place, and deletes the archive
dru_install(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
   	     	echo -e "\n This tool downloads and extracts Drupal 7.34."
			"The customer or you will have to go through basic setup in cluding entering the DB info."
	else
		echo -e "\nDownloading files."
		wget -q http://ftp.drupal.org/files/projects/drupal-7.34.tar.gz 
		echo -e "Unzipping."
		tar xzf ./drupal-7.34.tar.gz
		echo -e "Moving and Grooving\n"
		mv ./drupal-7.34/* . 
		rm -rf drupal-7.34*
	fi
}
#Roundcube 1.1 installer, downloads, extracts, manipulates files, and deletes the archive
cube_install(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\n This tool downloads and extracts Roundcube 1.1.0.
			The customer or you will have to go through basic setup in cluding entering the DB info."
	else
		echo -e "\nDownloading files."
	        wget -q http://iweb.dl.sourceforge.net/project/roundcubemail/roundcubemail/1.1.0/roundcubemail-1.1.0-complete.tar.gz 
		echo -e "Unzipping."
		tar xzf ./roundcubemail-1.1.0-complete.tar.gz 
		echo -e "Moving and Grooving\n"
		mv ./roundcubemail-1.1.0/* . 
		rm -rf roundcubemail-1.1.*
		cube_config
	fi
}
#configures roundcube by prompting the user for the IP, database name, user and password
#then brings them together in a constructed variable that roundcube uses to connect to the database
cube_config(){
	local name=
	local user=
	local pass=
	local ip=
	local construct=

	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nPrompts for Database name, username, and password, and IP address of the server then updates the config with those values."

	else

	echo "Type the Database Name:"
	read name
	echo "Type the Database User:"
	read user
	echo "Type the Database Password:"
	read pass
	echo "What is the server's (or dedicated IP)"
	read ip

	construct="mysql://$user:$pass@$ip/$name"

	awk '{sub(/[$]config[^ ].db_dsnw.[^ ][ ][=][ ].[^ ]*./,"$config[\47db_dsnw\47] = \47'$construct'\47);")}1' ./config/config.inc.php.sample > ./config/config.inc.php.tmp
	awk '{sub(/[$]config[^ ].smtp_server.[^ ][ ][=][ ].[^ ]*./,"$config[\47smtp_server\47] = \47%n\47);")}1' ./config/config.inc.php.tmp > ./config/config.inc.php
	awk '{sub(/[$]config[^ ].smtp_user.[^ ][ ][=][ ].[^ ]*./,"$config[\47smtp_user\47] = \47%u\47);")}1' ./config/config.inc.php > ./config/config.inc.php.tmp
	awk '{sub(/[$]config[^ ].smtp_pass.[^ ][ ][=][ ].[^ ]*./,"$config[\47smtp_pass\47] = \47%p\47);")}1' ./config/config.inc.php.tmp > ./config/config.inc.ph
fi
}

unset HISTFILE
