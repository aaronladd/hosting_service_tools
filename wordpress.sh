#!/bin/bash

#Global variables for use between functions. 

#Database prefix pulled by the wpdb function for use in creating queries
PREFIX=
#Query that is built by each separate function that needs to be passed back to wpdb
QUERY=
#Output from any queries (that provide output exp. "select")
OUTPUT=

#Wordpress install fucntion wp_install
#this function installs wordpress by downloading the latest buid form wordpress.org
#function does check for an existing install by looking for a wp-config.php
#If found it'll prompt for the user to continue.
#After the files are loaded the wp_config function is then called.
#variables: local: choice
wp_install(){
	local choice=
	if [[ $1 == "--help" || $1 == "-h" ]]; then
			echo -e "\n This tool downloads and extracts the latest wordpress files," \ 
				"you'll still need to create the database and update the wp_config.php."
	else
		if [[ -f ./wp-config.php ]]; then
			echo "There may be an existing install of wordpress here," \
				"are you sure you want to continue? (y to continue)"
			read choice
			if [[ $choice !=  "y" ]]; then
				return
			fi
		fi      
		echo "Twiddling our thumbs."
		wget --quiet http://wordpress.org/latest.tar.gz
		tar xfz ./latest.tar.gz --strip-components=1 
		cp wp-config{-sample,}.php
		rm -rf latest.tar.gz
		echo "Petting kittens."
		wp_config
	fi
}

#Wordpress configuration function wp_config
#If no wp-config.php if found it exits with an error
#prompts you for Database Name, Username, and Password
#fixes the password so it's accepted by shell
#finds and replaces the necessary lines in the wp-config then prints the lines replaced
#variables: local: name, user, pass
wp_config(){
	local name=
	local user=
	local pass=
	if [[ $1 == "--help" || $1 == "-h" ]]; then
		echo -e "\nPrompts for Database name, username, and password," \
			"then updates the wp-config with those values."

	else
		if [[ ! -f ./wp-config.php ]]; then
			echo "There isn't a wp-config file here. Are you sure you're in the correct directory?"
			return
		fi

	echo -e "\nType the Database Name:"
	read name
	echo "Type the Database User:"
	read user
	echo "Type the Database Password:"
	read pass

	printf -v pass "%q" $pass
	pass=`echo $pass | sed 's/&/\&/g'`

	sed -i "s/.*DB_NAME.*/define('DB_NAME', '$name');/" wp-config.php
	sed -i "s/.*DB_USER.*/define('DB_USER', '$user');/" wp-config.php
	sed -i "s/.*DB_PASSWORD.*/define('DB_PASSWORD', '$pass');/" wp-config.php

	echo ""
	cat wp-config.php \
		| grep 'DB_NAME\|DB_USER\|DB_PASSWORD'
	echo ""

	fi
}

#.xmlrpc attack redirect
#Adds a rewrite rule to redirect all traffic to the file .xmlrpc to the ip 0.0.0.
#this function calls the ht_manipulation function from the tools.sh toolset
#then echoes the rewrite in and kills all php proccess under the user
#typically when seeing an xmlrpc attack this is one of the easiest way to thwart it
#though I still recommend having the offending IPs dropped by IP tables
xmlrpc_fix(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
		echo -e "\nAppends a rewrite rule to the .htaccess in the current directory" \
			"to redirect all xmlrpc hits to 0.0.0.0"
	else
		. <(curl -sS http://tools.apathabove.com/tools.sh)
		ht_manipulation 0
		ht_manipulation 1
	        echo -e "RewriteEngine On
			\nRewriteRule ^xmlrpc\.php$ "http\:\/\/0\.0\.0\.0\/" [R=301,L]\n" \
			> .htaccess
		ht_manipulation 2
		ht_manipulation 3
		pkill -f php
	fi
}

#Adds a php stanza to the wp-config.php that forces https
#returns with an error if there is no wp-config.php
#finds the initial <?php bracket and replaces it with a new one with some nice spacing
#and the redirect stanza this will be most useful on OHWP
wp_config_https(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nfixes most https loops on wordpress sites (mainly used for OHWP) WP-Config value supplied by James Roper."
	else
		if [[ ! -f ./wp-config.php ]]; then
        		echo "There isn't a wp-config file here. Are you sure you're in the correct directory?"
	        	return
		fi
	        sed -i "s/<?php/<?php \n\n\/\*\n\tForwards HTTP\/HTTPS status to WordPress on Optimized Hosting for WordPress\n\*\/\nif(\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https'){\n\t\$_SERVER['HTTPS'] = 'on';\n};\n/" wp-config.php

	fi
}

#Forwards end_user's true IP to OHWP (mostly used for stat collecting)
#returns with an error if there's no wp-config
#finds the initial <?php bracket and replaces it with a new one with some nice spacing
#and the forwarding stanza this will be only useful on OHWP
ohwp_forward_ips(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
                echo -e "\nForwards Visitors' true IP address to wordpress on OHWP. WP-Config value supplied by James Roper."
        else
                if [[ ! -f ./wp-config.php ]]; then
                        echo "There isn't a wp-config file here. Are you sure you're in the correct directory?"
                        return
                fi
                sed -i "s/<?php/<?php \n\n\/\*\n\tForwards Visitors' True IP address to WordPress on Optimized Hosting for WordPress\n\*\/\nif(\$_SERVER['HTTP_X_REAL_IP']){\n\t\$_SERVER['HTTP_X_REAL_IP'] = \$_SERVER['HTTP_X_REAL_IP'];\n}\n\n\n/" wp-config.php

        fi
}

#Wordpress Database function (the bread and butter of my wptools)
#Returns with error if there's no wp-config.php
#Pulls the database information from the wp-config.php file and assignes each value to the appropriate variables
#If $PREFIX hasn't already been set it will pull the prefix as well
#A simple "whoami" command is run within mysql and if the server doesn't respond the function exits with an error
#mysql errors are surpressed.
#if there is anything in the $QUERY variable passing any output to $OUTPUT the function will run that and then continue 
#Available argumetns include -f showing database name, user, pass, and tables
#-d or mysqldump of the db
#-i or import of a specfic file supplied by you
#-p my favorite, which loads a mysql prompt for manual sql
#-l clears the wordpress (not a security plugins) login lockout function
#local variables created: args, host, name, pass, user, db_info, db_conn_status, file_name
#global variables used: PREFIX, OUTPUT, QUERY
wpdb(){
	local args=$1
	local file_name=$2
	local host= 
	local name= 
	local pass= 
	local user= 
	local db_info=
	local db_conn_status=

	if [[ $args == "--help" || $args == "-h" ]]; then
        	echo -e "\nChecks db connection using current wp-content information. Will only display information if it fails." \
			"\n\t-p or --prompt to enter a mysql prompt to run your own mysql queries." \
			"\n\t-d or --dump will dump the database" \
			"\n\t-i <file> or --import <file> will import the database that you specify." \
			"\n\t-f or --info will display info about the database connection" \
			"\n\t-l or --failed will clear login lockouts in wordpress (24 hour lockout in wp-admin)"
		return
	elif [[ -f ./wp-config.php ]]; then
		db_info=`cat wp-config.php \
                | egrep "DB_(NAME|USER|PASSWORD|HOST)" \
                | sort -d \
                | sed "s/.*[\"']\(.*\)[\"'].*;.*/\1/"`

                read -r host name pass user <<< $(echo $db_info)

		if [[ -z $PREFIX ]]; then
			PREFIX=`cat wp-config.php | grep "table.*.;" | sed "s/.*[\"']\(.*\)[\"'].*;.*/\1/"`
		fi

                db_conn_status=`mysql --user="$user" --password="$pass" --database="$name" --execute="select user();" \
			| grep $host \
			2>/dev/null`

                if [[ -z $db_conn_status ]]; then
                	echo -e "Database connection failed.\nCheck wp-config values."
			return
		fi
        else
		echo -e "Database connection failed.\nCheck for active wp-config.php."
		return
	fi

	if [[ $args == "--prompt" || $args == "-p" ]]; then
                mysql --user="$user" --password="$pass" --database="$name"
	elif [[ $args == "--info" || $args == "-f" ]]; then
		echo -e "\nwp-config info:" \
			"\n\tDatabase Name: $name" \
			"\n\tDatabase User: $user" \
			"\n\tDatabase Password: $pass \n"
		QUERY="SHOW tables;"
		wpdb
		echo $OUTPUT | sed 's/ /\n\t/g'
		echo
	elif [[ $args == "--failed" || $args == "-l" ]]; then
		echo -e "Clearing login lockouts."
        	QUERY="update $(echo $PREFIX"options") set option_value=\"\" where option_name=\"limit_login_lockouts\";"
	elif [[ $args == "--dump" || $args == "-d" ]]; then
	        mysqldump --user="$user" --password="$pass" $name > $name.sql
	elif [[ $args == "--import" || $args == "-i" ]]; then
	        if [[ -a $file_name ]]; then
        		mysql --user="$user" --password="$pass" --database="$name" < $file_name
		else
                   	echo -e "Sorry, that file doesn't exist."
		fi
	elif [[ ! -z $QUERY ]]; then
                OUTPUT=`mysql --user="$user" --password="$pass" --database="$name" --execute="$QUERY"`
	fi
}

#Wordpress Plugin command mainly for removing and applying text to the active_plugins database field.
#makes sure $PREFIX is set then moves to disable or enable plugins. I do this by pulling the current plugin list
#and sending it to the file .active_plugs, while this may not be good practice, it is nice to have in a file for
#editing before enabling. Then I set the active plugins field to nothing. When restoring the plugins from .active_plugs
#First the file is checked for existance and then made shell friendly with printf and the .active_plugs file is removed
#the default for this function is displaying the active_plugins field in the database. 
#local variables used: arguments, options, and active_plugins globals used: QUERY, PREFIX, and OUTPUT
wpplug(){
	local argument=$1
	local active_plugins=

	if [[ -z $PREFIX ]]; then
                wpdb
        fi

	local options=$(echo $PREFIX"options")

	if [[ $argument == "--help" || $argument == "-h" ]]; then
        	echo -e "\nShows Active Plugins." \
			"\n\t-d or --disable to disable plugins" \
			"\n\t-r or --restore to restore plugins"
		return
	elif [[ $argument == "--disable" || $argument == "-d" ]]; then
		if [[ -a ./.active_plugs ]]; then
			echo -e "\nYou've already disabled the plugins here, rename or delete the .active_plugs file.\n"
			return
		fi
		QUERY="select option_value from $options where option_name=\"active_plugins\";"
		wpdb
		echo $OUTPUT \
			| sed 's/option_value //g' \
			> .active_plugs
		OUTPUT=
		if grep -Fq "a:" .active_plugs ; then
			QUERY="update $options set option_value=\"\" where option_name=\"active_plugins\";"
			echo -e "Plugins Disabeled\nBackup file .active_plugs created!"
		
		else
			echo "There are no plugins to disable or there is a syntax error in the field."
		fi
	elif [[ $argument == "--restore" || $argument == "-r" ]]; then
		if [ -a .active_plugs ]; then
			active_plugins=`cat .active_plugs`
			printf -v active_plugins "%q" $active_plugins
			QUERY="update $options set option_value=\"$active_plugins\" where option_name=\"active_plugins\";"
			rm -rf .active_plugs
			echo -e "Plugins restored\nFile .active_plugs removed"
		else
			echo "There is not a saved plugins file."
		fi
	else
		QUERY="select option_value from $options where option_name=\"active_plugins\";" 
	fi
	wpdb
	if [[ ! -z $OUTPUT ]]; then
		echo $OUTPUT \
                         | sed 's/option_value //g'
	fi
}

#Wordpress theme modification function
#sets the prefix and then sets a variable for the correct table
#"fresh" checks for an existing 2012 theme and deletes it then downloads a new one and sets it active
#-t sets the template to the passed theme
#-s sets the stylesheet to the passed theme
#anything else passed to wptheme will be considered a theme name and set to both
#if nothing is passed it will just return the active themes 
wptheme(){
	local args="$1"
	local theme="$2"
	if [[ -z $PREFIX ]]; then
                wpdb
        fi
	local table=`echo $PREFIX"options"`
	if [[ $args  == "--help" || $args == "-h" ]]; then
		echo -e "\nDisplays currently selected themes and available themes" \
			"\n\t<theme> to change both the stylesheet and template" \
			"\n\t-t <theme> to change just the template." \
			"\n\t-s <theme> to change just the stylesheet." \
			"\n\tfresh to download and set a fresh version of the default twentytwelve theme as the active theme."
		return
	elif [[ $args == "fresh" ]]; then
		if [[ -d ./wp-content/themes/twentytwelve ]]; then
			echo -e "\nExisting theme found. Taking it swimming."
			rm -rf ./wp-content/themes/twentytwelve
		fi
		echo -e "\nPolishing Codpiece."
		wget --quiet --directory-prefix=./wp-content/themes https://downloads.wordpress.org/theme/twentytwelve.1.7.zip
		echo "Releasing Dolphins to the wild."
		unzip -q ./wp-content/themes/twentytwelve.1.7.zip -d ./wp-content/themes/
		echo "Grading Standardized tests."
		QUERY="update $table set option_value=\"twentytwelve\" where option_name=\"stylesheet\" or option_name=\"template\";"
		echo "Deatomizing files."
		rm -rf ./wp-content/themes/twentytwelve.1.7.zip
		echo -e "\nFresh twentytwelve theme downloaded and set active."
	elif [[ $args == "--template" || $args == "-t" ]]; then
                QUERY="update $table set option_value=\"$theme\" where option_name=\"template\";"
                echo -e "\nTemplate updated to theme $theme \n"
        elif [[ $args == "--stylesheet" || $args == "-s" ]]; then
                QUERY="update $table set option_value=\"$theme\" where option_name=\"stylesheet\";"
                echo -e "\nStylesheet updated to theme $theme \n"
	elif [[ -n $args ]]; then
                QUERY="update $table set option_value=\"$args\" where option_name=\"stylesheet\" or option_name=\"template\";"
                echo -e "\nTheme updated to $args. \n"
	else
		QUERY="select option_name,option_value from $table where option_name=\"stylesheet\" or option_name=\"template\";"
	fi
	wpdb
	if [[ ! -z $OUTPUT ]]; then
		echo -e "\n"$OUTPUT \
                        | sed 's/option.*.value//' \
                        | sed 's/stylesheet/Stylesheet/' \
                        | sed 's/template/\nSemplate/' \
                        | awk '{printf "%-13s %s\n", $1, $2}'
                echo -e "\nAvailable Themes:"
                ls -1d ./wp-content/themes/*/ \
                        | sed 's/.*themes//g' \
                        | sed 's/\///g' \
                        | sed 's/^/\t/g'
                echo

	fi
}

#Wordpress URL modification function
#-o updates just the home url while -s updates the site url
#passing anything but -o or -s will automatically set both urls to the passed value
#passing nothing displays the active urls
#local variables: args, url, and options_table Globals: PREFIX, QUERY, OUTPUT
wpurl(){
	local args=$1
	local url=$2
	
	if [[ -z $PREFIX ]]; then
                wpdb
    	fi

	local options_table=`echo $PREFIX"options"`

	if [[ $args == "--help" || $args == "-h" ]]; then
        	echo -e "Displays the wordpress home and site url." \
			"\n\t<url> changes both home and site urls" \
			"\n\t-o or --home changes the home url" \
			"\n\t-s or --site changes the site url"
        	return
	elif [[ $args == "--home" || $args == "-o" ]]; then
		if [[ $url != "" ]]; then
			QUERY="update $options_table set option_value=\"$url\" where option_name=\"home\";"
			echo "Home url updated to $url."
		else
			echo "You didn't supply a domain."
		fi
	elif [[ $args == "--site" || $args == "-s" ]]; then
		if [[ $url != "" ]]; then
			QUERY="update $options_table set option_value=\"$url\" where option_name=\"siteurl\";"	
			echo "Site url updated to $url."
		else
	            echo "You didn't supply a domain."
        	fi
	else
		if [[ $args != "" ]]; then
			QUERY="update $options_table set option_value=\"$args\" where option_name=\"siteurl\" or option_name=\"home\";"
			echo "Home and Site URL updated to $args."
		else
			QUERY="select option_name,option_value from $options_table where option_name=\"siteurl\" or option_name=\"home\";"
		fi
	fi
	wpdb
	if [[ ! -z $OUTPUT ]]; then
		echo $OUTPUT \
			| sed 's/option.*.value//' \
			| sed 's/home/\tHome_Url/' \
			| sed 's/siteurl/\n\tSite_Url/' \
			| awk '{printf "%-10s %s\n", $1, $2}'

	fi
}

#Wordpress user modification function
#passing nothing shows the current user and their ID
#the ID is needed for all further commands
#-u changes the username and is passed the ID
#-p changes the password and is passed the ID
#-n creates a new account with the next availabel ID
#-d deletes a specified account
#-r promotes an account to admin
#with no arguments it shows the first 10 users
#variables: local: args, account, modifier, users, and usermeta Global: QUERY, PREFIX, OUTPUT
wpuser(){
	local args=$1
	local account=$2
	local modifier=$3

	if [[ -z $PREFIX ]]; then
                wpdb
    	fi

	local users=$(echo $PREFIX"users")
        local usermeta=$(echo $PREFIX"usermeta")
	
	if [[ $args == "--help" || $args == "-h" ]]; then
        	echo -e "\nDisplays current users." \
			"\n\t-u or --user : example:(wpuser -u # new_name) changes the username." \
			"\n\t-p or --password : example:(wpuser -p # new_pass) Changes the password." \
			"\n\t-n or --new : example(wpuser -n username password) Creates a completely new user as admin, you will have to supply the username and password." \
			"\n\t-d or --delete : example:(wpuser -d #) deletes the username." \
			"\n\t-r or --promote : example:(wpuser -r #) Promotes user to admin."
		return
	elif [[ $args == "--user" || $args == "-u" ]]; then
		if [[ -n $account ]]; then 
			if [[ -n $modifier ]]; then
				QUERY="update $users set user_login=\"$modifier\" where ID=\"$account\";"
				echo -e "\n\tUsername changed to $modifier \n"
			else
				echo -e "\n\tPlease provide a new username.\n"
			fi
		else
			echo -e "\n\tPlease choose an existing account to modify.\n"
		fi
	elif [[ $args == "--password" || $args == "-p" ]]; then
		if [[ -n $account ]]; then
                	if [[ -n $modifier ]]; then
                        	QUERY="update $users set user_pass=md5(\"$modifier\") where ID=\"$account\";"
                        	echo -e "\n\tPassword changed to $modifier \n"
                	else
                        	echo -e "\n\tPlease provide a new password.\n"
                	fi
        	else
                	echo -e "\n\tPlease choose an existing account to modify.\n"
        	fi
	elif [[ $args == "--new" || $args == "-n" ]]; then
		if [[ -n $account ]]; then
        		if [[ -n $modifier ]]; then
				QUERY="select max(ID) from $users;"
				wpdb
				max=$(echo $OUTPUT | cut -d' ' -f2)	
				max=$((max+1))
				OUTPUT=
				QUERY="INSERT INTO $users (ID,user_login,user_pass) VALUES ('$max', '$account', MD5('$modifier')); INSERT INTO $usermeta (umeta_id, user_id, meta_key, meta_value) VALUES (NULL, '$max', '"$PREFIX"capabilities', 'a:1:{s:13:\"administrator\";s:1:\"1\";}'); INSERT INTO $usermeta (umeta_id, user_id, meta_key, meta_value) VALUES (NULL, '$max', '"$PREFIX"user_level', '10');"
        	    		echo -e "\n\tAccount $account created successfully.\n"
            		else
	                	echo -e "\n\tPlease provide a password.\n"
            		fi
        	else
            		echo -e "\n\tPlease provide a username.\n"
        	fi
	elif [[ $args == "--delete" || $args == "-d" ]]; then
		if [[ -n $account ]]; then
			QUERY="Delete from $users where ID=\"$account\"; Delete from $usermeta where user_id=\"$account\";"
			echo -e "\n\tUser removed successfully.\n"
		else
			echo -e "\n\tPlease specify the ID associated with the username.\n"
		fi
	elif [[ $args == "--promote" || $args == "-r" ]]; then
		if [[ -n $account ]]; then
			QUERY="Delete from $usermeta where user_id=\"$account\"; INSERT INTO $usermeta (umeta_id, user_id, meta_key, meta_value) VALUES (NULL, '$account', '"$PREFIX"capabilities', 'a:1:{s:13:\"administrator\";s:1:\"1\";}'); INSERT INTO $usermeta (umeta_id, user_id, meta_key, meta_value) VALUES (NULL, '$account', '"$PREFIX"user_level', '10');"
			echo -e "\n\tUser promoted successfully.\n"
		else
			echo -e "\n\tPlease specify the ID associated with the username.\n"
        fi
	else	
		echo -e "\nActive Users:"
		QUERY="select ID,user_login from $users limit 10;"
	fi
	wpdb
	if [[ ! -z $OUTPUT ]]; then
		echo -e "\n""$OUTPUT""\n"
	fi 
	
}

#Wordpress core file replacement function
#creates a new directory for core wp files with the current date/time
#moves a set list of files excluding wp-config.php and wp-content to the new core directory
#renames the wp-content to wp-content.core_replace
#-c checks the current version and tries to replace that version of core files
#no arguments replaces the core files with the latest deletes the new wp-content and the downloaded .tar.gz
#the original wp-content is moved into place and the website should have new core files
#Variables: local: curCoreFname and curFileVer
wpcore() {
	local args=$1
	local curCoreFname=
	local curFileVer=
	
	if [[ $args == "--help" || $args == "-h" ]]; then
        	echo -e "Backs up wp files, installs wp fresh, and brings back the wp-content and wp-config.php." \
			"\n\t-c or --current will download a version of wp that matches the currently installed version."
		return
	elif [[ ! -f wp-config.php && ! -d wp-content ]]; then
		echo -e "\twp-content and wp-config.php are missing, are you sure you're in the correct dir? If so, to be safe, you'll need to create that file/directory to bypass this check."
		return
	fi

	echo "Forging Bucket"
        curCoreFname=`echo "core_wp_"$(date +%y_%m_%d_%H_%M_%S)`
        mkdir $curCoreFname
        
        echo "Upsetting Mother Nature"
	mv wp-content{,.core_replace}
	mv -t $curCoreFname .htaccess index.php license.txt readme.html xmlrpc.php $(find . -maxdepth 1 -name "wp-*" | grep -v "wp-content\|wp-config.php") 2>/dev/null

	if [[ $1 == "--current" || $1 == "-c" ]]; then
		echo "Assimilating natives."
		curFileVer=`cat wp-includes/version.php | grep "wp_version " | cut -d"'" -f2`

		echo "Stealing Dentures."
		wget --quiet http://wordpress.org/$curFileVer.tar.gz
        	tar xfz ./$curFileVer.tar.gz --strip-components=1
		echo "Cleaning Dentures."
        	rm -rf $curFileVer.tar.gz wp-content
	else
		echo "Stealing Candy..."
        	wget --quiet http://wordpress.org/latest.tar.gz
        	tar xfz ./latest.tar.gz --strip-components=1
		echo "Selling Midgets."
		rm -rf latest.tar.gz wp-content
	fi

	mv wp-content{.core_replace,}

}

#Wordpress .htaccess rules
#if there isn't an .htaccess one is created with the default wordpress redirects
#otherwise the existing one is renamed and a new one is created with the default wordpress redirects
wpht(){
	local args=$1
	if [[ $args == "--help" || $args == "-h" ]]; then
		echo -e "Replaces the .htaccess in the current directory (if there is one) with one that contains the default wordpress rules."		
	elif [[ ! -a ./.htaccess ]]; then
		echo -e "# BEGIN WordPress" \
			"\n<IfModule mod_rewrite.c>" \
			"\nRewriteEngine On" \
			"\nRewriteBase /" \
			"\nRewriteRule ^index\\.php$ - [L]" \
			"\nRewriteCond %{REQUEST_FILENAME} !-f" \
			"\nRewriteCond %{REQUEST_FILENAME} !-d" \
			"\nRewriteRule . /index.php [L]" \
			"\n</IfModule>" \
			"\n# END WordPress\n" \
			> .htaccess
	else
		mv .htaccess{,.applesauce}
		wpht
	fi
}

unset HISTFILE
