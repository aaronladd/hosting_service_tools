#!/bin/bash

#.htaccess manipulation for various applications. 4 step process to adding text to the beginning of an .htaccess file.
#if the file doesn't exist it creates it, if the file exists and is not empty it renames it
#If both the renamed file and the new file exist the renamed file is appended to the end of the new file and removed
#local variables: arguments
ht_manipulation(){

	local arguments=$1

	case $arguments in
		0)
			if [[ ! -a .htaccess ]]; then
		                touch .htaccess
        		fi
		  ;;
		1)
			if [[ ! -z $(cat .htaccess) ]]; then
                		mv .htaccess{,.applesauce}
		        fi
		  ;;
		2)

			if [[ -a .htaccess.applesauce && -a .htaccess ]]; then
		                cat .htaccess.applesauce \
		                >> .htaccess
		        fi
		  ;;
		3)
			if [[ ! -a .htaccess.applesauce ]]; then
		                return
			else
				rm -rf .htaccess.applesauce
		        fi
		  ;;
		*) return
		  ;;
	esac
}

#server status page that pints out a great deal of information
#for more details about the contents of the script please contact the creator
server_stats(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
		echo -e "\nThis tool runs the serv_stat script. Props to the original author Jacob Cloutier. \n\t\tOutputs, server load, web connections, Top 5 connections, and top file requests."
	else
		. <(curl -sS https://scripts.justbluemonster.com/CTools/ServStat)
	fi
}

#adds an allow/deny to the .htaccess
#requests a list of ips separated by comma
#uses the .ht_manipulation function to add the stanza to the .htaccess
#variables local: arguments, choice, ips
deny_by_ip(){
	local arguments=$1
	local choice=
	local ips=
	if [[ $arguments == "--help" || $arguments == "-h" ]]; then
        	echo -e "\n Allows user to enter a list of IPs to deny in the current directory's .htaccess."
	else
		ht_manipulation 0
		echo -e "Enter your IP address(es) if you have more than one separate them with a comma."
		read choice
		ht_manipulation 1
		ips=`echo $choice \
			| sed 's/[ \|,][ , ]*/ n/g' \
			| sed 's/ /\\\/g'`
        	echo -e "Order Deny,Allow\nDeny from " $ips \
			> .htaccess
		ht_manipulation 2
		ht_manipulation 3
	fi
}

#function adds an https redirect to the .htaccess
#requests that you supply the domain.tld
#variables local: domain
https_redirect(){
	local domain=
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nAdds a https:// redirect to the beginning of the .htaccess"
	else
		ht_manipulation 0
		
		echo -e "Please enter the domain in this form domain.tld:"
		read domain
		ht_manipulation 1
		echo -e "RewriteEngine On\n" \
			"RewriteCond %{SERVER_PORT} 80\n" \
			"RewriteRule ^(.*)$ https://$domain/\$1 [R=301,L]\n" \
			| sed 's/^ //g' \
			> .htaccess
		ht_manipulation 2
		ht_manipulation 3
	fi
}

#function adds the suPHP_ConfigPath <path> \ to the .htaccess
#variables local: path
diff_php_ini(){
	local path=
	if [[ $1 == "--help" || $1 == "-h" ]]; then
	        echo -e "\n Appends a line to the .htaccess that will allow a php.ini in a non-default location which will be supplied by you."
	else
		ht_manipulation 0
		echo "Please provide the full path to the directory the new php.ini will reside."
		read path
		ht_manipulation 1
	        echo -e "suPHP_ConfigPath " $path "\n" \
			> .htaccess
		ht_manipulation 2
		ht_manipulation 3
	fi
}

#finds and displays all error_logs under the current directory
elog_display(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\n Displays the last 5 lines from every error_log in the current directory and every subdirectory."
	else
		tail -n 5 $(find . -name error_log) \
		| less
	fi
}

#displays the access logs
#Initially lists the available logs in ~/access-logs
#prompts you to choose one
#if you add -m 25 it will show the first 25 lines of IPs instead of the default 10
#variables: local: arguments, lines, head, available, and domain
access_logs(){
	local arguments=$1
	local lines=$2
	local head="head"
	local available=
	local domain=

	if [[ $arguments == "--help" || $arguments == "-h" ]]; then
		echo -e "Shows the connections to the domain of choice and what files they're accessing defaulting to 10 lines.
			\n\t-m # or --more # will allow you to specify the number of lines you'd like to view."
		return
	fi

       	echo -e "\n\tCommand supplied by Robin S. Heavily edited by Aaron Ladd.\n"
	sleep 2
	echo -e "Available domain logs.\n"
	available=`ls -1 ~/access-logs`
	echo $available \
		| sed 's/ /\n/g'
	echo -e "\nProvide the domain you'd like to check."
	read domain

	if [[ $arguments == "--more" || $arguments == "-m" ]]; then
		head="head -$lines"
	fi

	cat ~/access-logs/$domain \
                                | awk '{print $1, $6, $7}' \
                                | sort \
                                | uniq -c \
                                | sort -nrk1 \
				| $head
}

#displays the path and contents of each .htaccess found under the public_html
htac_display(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nDisplays the path and contents of each .htaccess file."
	else
		local i=
        	for i in $(find ~/public_html -name .htaccess) \
			; do echo "==> $i <==" \
			; cat $i \
			; echo -e "\n" \
			; done \
			| less
	fi
}

#trims all error_log files to show the last 100 lines in public_html and below.
trim_elogs(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nRemoves all but the last 100 lines of the error logs."
	else
		local i=
        	for i in $(find ~/public_html -name error_log ) \
		; do ERROR_LOG="$(tail -n 100 $i)" \
		echo "$ERROR_LOG" > $i \ 
		done
	fi
}

#Displays what directories have active connections to databases and what the name of the databases are.
active_dbs_display(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nDisplays list of active databses being used by websites"
	else
        	find ~/public_html -type f -name "*.php" -print0 -o -name "*.xml" -print0 \
			| xargs -0 grep -H "$(whoami)_" ;
	fi
}

#Downloads a default php.ini that will need to be renamed.
php_ini_default(){
	if [[ $1 == "--help" || $1 == "-h" ]]; then
        	echo -e "\nDownloads a default php.ini to the current directory."
	else
        	wget --quiet http://tools.apathabove.com/php.ini.default
	fi
}

unset HISTFILE
