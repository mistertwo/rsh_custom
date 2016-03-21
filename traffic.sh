#!/bin/bash
#
# Name: Traffic
# Description: Provides a summary of traffic an install has received.
#			   By default with an installation, all of the access logs are summarized. If access logs are piped
#			   to this script, then those logs are summarized.
# Author: Mark Gutierrez
# Version: v.0.4.3
#
# July 30, 2015 - v.0.4.3
# + Redshell/Portal support
#
# April 10, 2015 - v.0.4.2
# + Fast mode - Get through large logs with -f command. Less prettier output.
# * Added missing back slashes for -v output
#
# April 8, 2015 - v.0.4.1
# + Verbose mode now outputs commands used.
# * Prevented du from running when logs are piped to the script.
#
# March 19, 2015 - v.0.4.0
# + Added warning for logs larger than 25 MB in size.
# * Fixed columns for IPs
#
# March 6, 2015 - v.0.3.0
# + Added additional HTTP Status code definitions
# + Added support for arguments (see -h)
# + Added nginx log parsing (-n)
# + Added support for parsing staging logs (-s)
# + Pretty colors
# + Specify how many lines of output from each summary to provide (-N)
#
# March 3, 2015 - v.0.2.0
# + Added more bot definitions + bot links
# + Added search feature (-g)
# * Fixed formatting
#
# March 2, 2015 - v.0.1.1
# * Fixed an issue where dates going into the next month were not being sorted properly.
#
#
# February 26, 2015 - v.0.1.0
# Initial release
#

# To do: Nginx style logs vs nginx apachestyle logs

version="0.4.3"


green='\e[0;32m'
yellow='\e[1;33m'
red='\e[0;31m'
blue='\e[0;34m'
endColor='\e[0m'

bold=`tput bold`
normal=`tput sgr0`

opt_install=$1
#grepString=$2

main() {
	echo
	#echo -e "${red}Tra${yellow}ffi${green}c.sh${endColor} v.$version"
	echo
	# If there ... IS.. stdin..
	if [ ! -t 0 ]; then
		if [ "$verbose" = true ]; then echo "We found data in stdin!" ; fi
		# Let's hope that it's access logs!
		# We should probably do a check here
		pipedData="$(cat -)"
		piped=true;

		echo "Attempting to parse stdin.. "

	else
		# If not.. then check for an install name
		piped=false

		if [ ! -f /var/log/apache2/$install.access.log ]; then
			echo "That install name does not exist OR there is no access log for it!" >> /dev/stderr
			exit 1
		fi


		# Checks for access/staging logs
		if [ "$log" = "apache" ]; then
			if [ "$staging" = true ]; then
				echo "Found staging apache access logs for install '$install'"
				accessLogs="/var/log/apache2/staging-$install.access.log*"
			else
				echo "Found production access logs for install '$install'"
				accessLogs="/var/log/apache2/$install.access.log*"
			fi
		elif [ "$log" = "nginx" ]; then

			if [ "$staging" = true ]; then
				echo -e "NOTE: Staging logs are not available for ${green}nginx${endColor}"
				staging=false
			fi
			echo -e "Notice: Found production ${green}nginx${endColor} access logs for install '$install'"


			accessLogs="/var/log/nginx/$install.apachestyle.log*"

		else
			log="apache"
			echo "Found production apache access logs for install '$install'"
			accessLogs="/var/log/apache2/$install.access.log*"
		fi

	fi



	if [ $piped = false ]; then

		# We gotta watch out for big logs, this script, in its current state, is HIGHLY inefficient.
		logSize=$(du -sc $accessLogs | tail -n1 | awk '{print $1}')
		logSizeInMB="$(expr $logSize / 1000) MB"

		if [ "$logSize" -gt "25000" ]; then
			echo -e "${red}WARNING:${endColor} The $log logs are $logSizeInMB. Logs larger than 25 MB may take a large amount of time AND "
			echo -e "use an excessive amount of CPU. We will pass -f which will be faster but the ouput "
			echo -e "will be less prettier. You can ctrl+c anytime during parsing to cancel operations."
			echo -e "Continue? (y/n) (y is default)"
			read ans
			ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
			#echo $ans
			if [ "$ans" == "n" ]; then
				echo "Exiting!"
				exit 0
			fi
			fast=true
			echo "Continuing!"
		fi

	fi


	echo Hang tight..
	echo
	echo

	echo
	if [ $fast = false ]; then
		total_requests=$(if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h " " $accessLogs | grep "$grepString" ; fi | wc -l)
		unique_ips=$(if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F':' '{print $1}' | awk '{print $1}' | sort | uniq | wc -l)

		start_timestamp=$(if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | head -n1)
		end_timestamp=$(if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | tail -n1)

		numReg='^[0-9]+$'
		totalBytes=0
	fi
	# This isn't working at the moment due to lost variables after subprocess ends.. so i'll need to figure that out.

	#if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "" $accessLogs ; fi | awk '{print $10}' | while read bytes ; do
		# If this is a number
	#	if [[ $bytes =~ $numReg ]]; then
	#		totalBytes=$(( $totalBytes + $bytes ))
	#	fi;
	#done

	#totalMB=$(($totalBytes / 10**6))
	if [ $piped = false ]; then
		echo -e "                  Install: $install"
		if [ "$log" = "apache" ]; then
			echo -e "                  Service: ${bold}Apache${normal}"
		elif [ "$log" = "nginx" ]; then
			echo -e "                  Service: ${green}Nginx${endColor}"
		else
			echo -e "                  Service: ${bold}Apache${normal}"
		fi
		if [ "$staging" = true ]; then
			echo -e "              Environment: Staging"
		else
			echo -e "              Environment: Production"
		fi
		if [ ! -z "$grepString" ]; then
			echo -e "            Search String: '$grepString'"
		fi
	fi
	echo
	echo -e " Total number of requests: $total_requests"
	echo -e "      Unique IP addresses: $unique_ips"
	#echo -e "    Total bandwidth sent: $totalMB MB [$totalBytes B]"
	echo -e "          Start Timestamp: $start_timestamp"
	echo -e "            End Timestamp: $end_timestamp"
	echo -e "           Total Log Size: $logSizeInMB"
	echo
	echo

	echo -e " Top requesting IP addresses _______________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk '{print \$1}' | sort | uniq --count | sort -nr | head -n $headCount"; echo ; fi
	# bare with me.....

	if [ "$fast" = false ]; then
		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk '{print $1}' | sort | uniq --count | sort -nr | head -n $headCount | while read line ; do
			count=$(echo $line | awk '{print $1}') ;
			ip=$(echo $line | awk '{print $2}') ;
			hostip=$(dig -x $ip +short) ;
			if [ -z "$hostip" ]; then hostip="Unknown host"; fi

			echo -e "        Count: $count\tIP: $ip\tHost: $hostip";
		done | column -ts $'\t'
	else

		if [ $piped = true ]; then echo "$pipedData" ; else  zgrep -h "$grepString" $accessLogs ; fi | awk '{print $1}' | sort | uniq --count | sort -nr | head -n $headCount

	fi

	echo
	echo
	echo -e " Request count per day _____________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d \"[\" -f2 | cut -d \"]\" -f1 | awk -F\: '{print \$1}' | uniq --count"; echo ; fi
	#
	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | awk -F\: '{print $1}' | uniq --count | while read line ; do

			count=$(echo $line | awk '{print $1}');
			date=$(echo $line | awk '{print $2}');

			echo -e "\tDay: $date \t Count: $count";

		done

	else

		if [ $piped = true ]; then echo "$pipedData" ; else  zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | awk -F\: '{print $1}' | uniq --count

	fi


	echo
	echo
	echo -e " Request count per hour ____________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d \"[\" -f2 | cut -d \"]\" -f1 | awk -F\: '{print \$1\":\"\$2}' | uniq --count"; echo ; fi
	#

	if [ "$fast" = false ]; then
		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | awk -F\: '{print $1":"$2}' | uniq --count | while read line ; do

			count=$(echo $line | awk '{print $1}');
			date=$(echo $line | awk '{print $2}');

			echo -e "\tHour: $date\t\tCount: $count";

		done

	else

		# Fast mode
		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n | cut -d "[" -f2 | cut -d "]" -f1 | awk -F\: '{print $1":"$2}' | uniq --count

	fi


	echo
	echo
	echo -e " Top request strings _______________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk -F\\\" '{print \$2}' | sort | uniq --count | sort -nr | head -n $headCount"; echo ; fi
	# oh god not again

	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $2}' | sort | uniq --count | sort -nr | head -n $headCount | while read line ; do
			count=$(echo "$line" | awk '{print $1}') ;
			request=$(echo "$line" | awk '{print $2" "$3" "$4}') ;
			echo -e "\tCount: $count \t Request: $request" ;
		done

	else

		# Fast mode
		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $2}' | sort | uniq --count | sort -nr | head -n $headCount

	fi

	echo
	echo
	echo -e " HTTP Status Codes _________________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk '{print \$9}' | sort | uniq --count | sort -nr"; echo ; fi
	# barf

	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk '{print $9}' | sort | uniq --count | sort -nr | while read line ; do
			count=$(echo "$line" | awk '{print $1}') ;
			statusCode=$(echo "$line" | awk '{print $2}') ;
			case $statusCode in
				"200") statusCode="$statusCode - OK" ;;
				"206") statusCode="$statusCode - Partial content" ;;
				"301") statusCode="$statusCode - Moved permanently" ;;
				"302") statusCode="$statusCode - Moved temporarily" ;;
				"304") statusCode="$statusCode - Not modified" ;;
				"307") statusCode="$statusCode - Temporary redirect" ;;
				"400") statusCode="$statusCode - Bad request" ;;
				"401") statusCode="$statusCode - Unauthorized" ;;
				"403") statusCode="$statusCode - Forbidden" ;;
				"404") statusCode="$statusCode - Not found" ;;
				"405") statusCode="$statusCode - Method not allowed" ;;
				"406") statusCode="$statusCode - Not acceptable" ;;
				"408") statusCode="$statusCode - Request time-out" ;;
				"416") statusCode="$statusCode - Requested range not satisfiable" ;;
				"429") statusCode="$statusCode - Too many requests" ;;
				"444") statusCode="$statusCode - No response" ;;
				"499") statusCode="$statusCode - Client closed request" ;;
				"500") statusCode="$statusCode - Internal server error" ;;
				"502") statusCode="$statusCode - Bad gateway" ;;
				"503") statusCode="$statusCode - Service unavailable" ;;
				"504") statusCode="$statusCode - Gateway timeout" ;;
				    *) ;;
			esac
			echo -e "\tCount: $count \t Code: $statusCode" ;
		done

	else

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk '{print $9}' | sort | uniq --count | sort -nr

	fi


	echo
	echo
	echo -e " Top referers _____________________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk -F\\\" '{print \$4}' | sort | uniq --count | sort -nr | head -n $headCount"; echo ; fi
	# make it stop

	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $4}' | sort | uniq --count | sort -nr | head -n $headCount | while read line ; do
			count=$(echo "$line" | awk '{print $1}')
			referer=$(echo "$line" | awk '{print $2}')
			echo -e "\tCount: $count \t Referer: $referer";
		done

	else

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $4}' | sort | uniq --count | sort -nr | head -n $headCount

	fi


	echo
	echo
	echo -e " Top user agents __________________________________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk -F\\\" '{print \$6}' | sort | uniq --count | sort -nr | head -n $headCount"; echo ; fi
	# this is so inefficient

	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $6}' | sort | uniq --count | sort -nr | head -n $headCount | while read line ; do
			count=$(echo "$line" | awk '{print $1}')
			user_agent=$(echo "$line" | cut -d' ' -f2-)
			echo -e "\tCount: $count \t User Agent: $user_agent";
		done

	else

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $6}' | sort | uniq --count | sort -nr | head -n $headCount

	fi

	echo
	echo
	echo -e " Top requests from bots/spiders/crawlers _________________________________________________"
	if [ "$verbose" = true ]; then echo "zgrep -h \"$grepString\" $accessLogs ; fi | awk -F\\\" '{print \$6}' | egrep -i \"(bot|spider|crawl|slurp)\" | sort | uniq --count | sort -nr | head -n $headCount"; echo ; fi
	#

	if [ "$fast" = false ]; then

		if [ $piped = true ]; then echo "$pipedData" ; else zgrep -h "$grepString" $accessLogs ; fi | awk -F\" '{print $6}' | egrep -i "(bot|spider|crawl|slurp)" | sort | uniq --count | sort -nr | head -n $headCount | while read line ; do
			count=$(echo "$line" | awk '{print $1}')
			user_agent=$(echo "$line" | cut -d' ' -f2-)

			case "$user_agent" in
				*"Googlebot"*)
					if  [[ $user_agent == *"Mobile"* ]]; then
						user_agent="Googlebot Mobile  http://www.google.com/bot.html"
					else
						user_agent="Googlebot  http://www.google.com/bot.html"
					fi
					;;
				  *"bingbot"*)
					if  [[ $user_agent == *"Mobile"* ]]; then
						user_agent="Bingbot Mobile  http://www.bing.com/bingbot.htm"
					else
						user_agent="Bingbot  http://www.bing.com/bingbot.htm"
					fi
					;;
				    *"Slurp"*) user_agent="Yahoo! Slurp  http://help.yahoo.com/help/us/ysearch/slurp" ;;
			  *"gsa-crawler"*) user_agent="Google Search Appliance  https://www.google.com/work/search/products/gsa.html" ;;
				   *"msnbot"*) user_agent="msnbot  http://search.msn.com/msnbot.htm" ;;
				   *"Yandex"*) user_agent="Yandexbot  http://yandex.com/bots" ;;
				    *"Baidu"*) user_agent="Baiduspider  http://www.baidu.com/search" ;;
					 *"Soso"*) user_agent="Soso Spider  http://help.soso.com/webspider.htm" ;;
				   *"Exabot"*) user_agent="Exabot  http://www.exabot.com/go/robot" ;;
				    *"Sogou"*) user_agent="Sogou Spider  http://www.sogou.com/docs/help/webmasters.htm#07" ;;
				 *"facebook"*) user_agent="Facebook External Hit  https://www.facebook.com/externalhit_uatext.php" ;;
	   *"Feedfetcher-Google"*) user_agent="Google Feedfetcher  http://www.google.com/feedfetcher.html" ;;
				            *) ;;
			esac

			echo -e "\tCount: $count \t Bot: $user_agent";
		done

	fi

	echo
	echo

}



helpDisplay() {
  cat << EOF

  Traffic.sh
  version: $version

  ABOUT:
  Summarizes access logs for an install. You can either supply an install name
  and it will summarize all logs available for that install or logs can be piped
  to it. Different flags will allow you to parse apache (Default) or nginx access
  logs, staging logs (production is default) and an optional string to grep/search
  for.

  USAGE:
  $ traffic -i INSTALL
  $ traffic -g "admin-ajax.php" -n -i INSTALL
  $ grep "28/Feb/2015" /var/log/apache2/INSTALL.access.log | traffic

  OPTIONS:
	-i <install>
		Searches the access logs for the supplied install name.
	-a
		Searches apache access logs. This is the DEFAULT flag if one
		is not specified. You cannot specify both -a and -n flags.
	-n
		Searches nginx access logs.
	-N <num>
		Specify how many lines you want returned for each summary. The default
		is 15.
	-g <string>
		Grep for the supplied string in the access logs. This option
		is case sensitive.
	-s
		Searches staging access logs instead of production access logs.
		NOTE: Staging logs are not available for nginx.
	-h
		Displays this help prompt.
	-f
		Fast mode; skips pretty output to get through larger logs. If the
		logs are larger than 25 MB, then you will be prompted to do fast
		mode instead for sanity reasons.
	-v
		Enables verbose mode.


EOF


}

traffic() {
fast=false
staging=false
headCount="15"

while getopts ":vhnN:ag:si:l:f" opt; do
	case $opt in
		v) # -v / --verbose
			verbose=true
			echo "-v was triggered, enabling Verbose mode!" ;;
		n) # -n / --nginx
			if [ "$log" = "apache" ]; then
				echo -e "Please specify either apache or ${green}nginx${endColor}, but noth both" >> /dev/stderr
				exit 1
			else
				if [ "$verbose" = true ]; then echo -e "-n was triggered, searching ${green}nginx${endColor}" ; fi
				log="nginx"
			fi

			#main #main()

			;;
		a) # -a / --apache (Apache is the default)
			if [ "$log" = "nginx" ]; then
				echo "Please specify either apache or nginx, but noth both" >> /dev/stderr
				exit 1
			else
				if [ "$verbose" = true ]; then echo "-a was triggered, searching apache" ; fi
				log="apache"
			fi

			#main #main()

			;;
		h) # -h / --help
			helpDisplay #helpDisplay()
			;;
		N) # -N / --numbers
			if [ "$verbose" = true ]; then echo "-N was triggered, grabbing top $OPTARG logs" ; fi

			re='^[0-9]+$'
			if ! [[ "$OPTARG" =~ $re ]] ; then
			   echo "$OPTARG is NOT a number" >> /dev/stderr
			   exit 1
		   else
				headCount=$OPTARG
			fi

			;;
		g) # -g / --grep
			if [ "$verbose" = true ]; then echo "-g was triggered, searching logs for: $OPTARG" ; fi
			grepString="$OPTARG"

			#main

			;;
		s) # -s / --staging
			if [ "$verbose" = true ]; then echo "-s was triggered, searching staging logs"; fi
			#grepString="$OPTARG"

			staging=true

			#main #main()

			;;
		i) # -i / --install
			if [ "$verbose" = true ]; then echo "-i was triggered, searching for install: $OPTARG" ; fi

			install="$OPTARG"
			unset opt_install

			main #main()

			;;
		l) # -l / --log
			if [ "$verbose" = true ]; then echo "-l was triggered: $OPTARG" ; fi ;;
		f) # -f / --file
			if [ "$verbose" = true ]; then echo "-f was triggered. Super FAST mode" ; fi
			fast=true
			;;
		\?)
			echo "Invalid option: -$OPTARG" >> /dev/stderr
			exit 1 ;;
		:) # :)
			echo "Option -$OPTARG requires an argument." >> /dev/stderr
      	  	exit 1 ;;
	esac
done


    if [ ! -t 0 ]; then
	# If there stdin, let's go to main!
	main; #main()
    #elif [ ! -z "$opt_install" ]; then
	# If an install was supplied directly, e.g.
	# $ traffic.sh INSTALL
	# Check if it exists, then go to main
        #install="$opt_install"

	#main; #main()
    fi
}
