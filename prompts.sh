#!/bin/bash
#main function calls the wordpress page to similate wptools but allows one to type guided for a more complete tlist of tools. 
main(){
	echo -e "\n\tWelcome to the overview, when you're ready, type \"guided\" for a guided process or type \"pages\" for the complete man page.
		\n\nMotivosity always accepted by any of the contributers. Main Writer: Aaron Ladd, Contributions: Robin Santillian, Jacob Cloutier, James Roper, and Landon Brainard.\n"
	. <(curl -sS http://tools.apathabove.com/wordpress.sh)
}
#basic options to keep code separated and make less curl calls if they're not needed. 
guided(){
	local choice=
	echo -e \
		"\nHello! Welcome to my script suite~ I hope you find these scripts usefull. Please type the number preceding the group of commands you'd like to explore.\n" \
		"\n\t(0) Everything Wordpress" \
		"\n\t(1) Installers (Concrete 5, Drupal, Joomla, Roundcube)" \
		"\n\t(2) Tools"

	read choice
	case $choice in
	0) wordpress
	   ;;
	1) installs
	   ;;
	2) tools
	   ;;
	*) echo -e "That's not an available command.\n\n"
	   ;;
	esac
}
#calls the installs script and the appropriate function from within. 
installs(){
	local choice=
	echo -e \
		"\nHi there, You can install quite a few things with this script. Type the preceding number and hit enter for what you want to install." \
		"\n\t(0) Concrete 5" \
		"\n\t(1) Joomla 3.3.6" \
		"\n\t(2) Drupal 7.34" \
		"\n\t(3) Roundcube 1.1.0" \
		"\n\t(b) Go Back" 
	
	read choice
	. <(curl -sS http://tools.apathabove.com/installers.sh)	
	case $choice in
	0) con5_install
	   ;;
	1) joom_install
	   ;;
	2) dru_install
	   ;;
	3) cube_install
	   ;;
	b) guided
	   ;;
	*) echo "Looks like what you entered wasn't a valid option. Please try again."
	   ;;
	esac
}
#Calls the tools script from the server and the function chosen by the user. 
tools(){
	local choice=
	echo -e \
		"\nWelcome to the tools section. type the number preceding the option you'd like.\n" \
		"\n\t(0) Server Stats" \
		"\n\t(1) Display databases currently linked to websites" \
		"\n\t(2) Deny by IP" \
		"\n\t(3) https redirect" \
		"\n\t(4) Custom php.ini path" \
		"\n\t(5) Error Log Display" \
		"\n\t(6) .htaccess Display" \
		"\n\t(7) Trim Error Logs" \
		"\n\t(8) Access Logs" \
		"\n\t(9) Download a default php.ini" \
		"\n\t(b) Go Back"

	read choice
	. <(curl -sS http://tools.apathabove.com/tools.sh)
	case $choice in
	0) server_stats
	   ;;
	1) active_dbs_display
	   ;;
	2) deny_by_ip
	   ;;	
	3) https_redirect
	   ;;
	4) diff_php_ini
	   ;;
	5) elog_display
	   ;;
	6) htac_display
	   ;;
	7) trim_elogs
	   ;;
	8) access_logs
	   ;;
	9) php_ini_default
	   ;;
	b) guided
	   ;;
	*) echo "Looks like what you entered wasn't a valid option. Please try again."
	   ;;
	esac
}
#References the wordpress function selected in the initially called 
wordpress(){
	local choice=
	echo -e \
		"Hi there, You can install quite a few things with this script. Type the preceding number and hit enter for what you want to install." \
		"\n\t(0) Install Wordpress" \
		"\n\t(1) Rewrite DB info in wp_config" \
		"\n\t(2) Add a xmlrpc redirect to .htaccess" \
		"\n\t(3) Add the force https lines to wp_config.php" \
		"\n\t(4) Forward IPs through nginx" \
		"\n\t(5) Wordpress DB Tool" \
		"\n\t(6) Wordpress Plugin Tool" \
		"\n\t(7) Wordpress Theme Tool" \
		"\n\t(8) Wordpress URL Tool" \
		"\n\t(9) Wordpress Core File Tool" \
		"\n\t(10) Wordpress .htaccess tool" \
		"\n\t(b) Go Back" \
	
	read choice
	case $choice in
	0) wp_install
	   ;;	
	1) wp_config
   	   ;;
	2) xmlrpc_fix
	   ;;
	3) wp_config_https
	   ;;
	4) ohwp_forward_ips
	   ;;
	5) wpdb
	   ;;
	6) wpplug
	   ;;
	7) wptheme
	   ;;	
	8) wpurl
	   ;;
	9) wpcore
	   ;;
	10) wpht
	   ;;
	b) guided
	   ;;
	*) echo "Looks like what you entered wasn't a valid option. Please try again."
	   ;;
	esac
}

pages(){
	curl http://tools.apathabove.com/pages | less
}

echo -e "\n\tInjected multiple files into session.\n\n"
#runs the main function
main
#unsets the HISTORY file for the session
unset HISTFILE
