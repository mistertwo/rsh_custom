# =====DISCLAIMER=====
# This script was designed to automate as much of the Factfinding process as possible
# You'll most likely still need to visit Zabbix and gather a little extra info based on 
# the situation. 
#
# The formatting has been set up to follow the Zendesk macro, so you should be able to 
# take this info and put it straight into the ticket.
#
# Please feel free to email me with any bugs or suggestions: drew.holt@wpengine.com

function factfind () {
        # check to see if we're on a cluster
        hostname=$(hostname)
        if [[ $hostname == *"web"* || $hostname == *"hapod"* ]]; then
                iscluster=true
        else
                iscluster=false
        fi

        # Based on whether or not we're on a cluster, there are a few things to set:
        # get an easy version of the hostname, get the total webheads, set the filepath for the databases,
        # and grep the correct disk usage info
        if [ "$iscluster" == true ]; then
                hostnameeasy=$(hostname | sed 's/\-[0-9]$//' | sed 's/web\-\|hapod\-//')
                disktotal=$(df -Th | grep nas | awk '{ print $3 }')
                diskinuse=$(df -Th | grep nas | awk '{ print $6 }')
                totalwebs=$(grep "\-${hostnameeasy}\-" /etc/hosts | grep -v 'dbmaster\|lbmaster\|utility' | grep 'pub' | wc -l)
                # 80k pods use /var/lib/mysql, unlike the other HAPODS
                if [ "$hostnameeasy" -gt 79999 ] && [ "$hostnameeasy" -lt 90000 ]; then
                        dbsizepath="/var/lib/mysql/"
                else
                        dbsizepath="/ssd/lib_mysql/"
                fi

        else
                hostnameeasy=$(hostname | sed 's/[^0-9]*//g' | sed -r 's/(.{5}).*/\1/')
                dbsizepath="/var/lib/mysql/"
                # Have to pass the -T flag to get the correct type of disk mount, since different servers have the
                # disk mounted to /nas/, /dev/xvda, /dev/sda, etc and sometimes with multiple instances of that. This
                # format allows it to work everywhere
                disktotal=$(df -Th | grep ext4 | grep -v ssd | awk '{ print $3 }')
                diskinuse=$(df -Th | grep ext4 | grep -v ssd | awk '{ print $6 }')
        fi

        # ====CPU info Variables
        cpu=$(nproc)
        totalmemgigs=$(free | grep Mem | awk '{print $2/1024000}' | sed -r 's/(.{3}).*/\1/')
        # Bash doesn't like doing math with floating points, so here's a simple integer version:
        totalmemgigsround=$(free | grep Mem | awk '{print $2/1024000}' | sed -r 's/\..*$//')
        totalmem=$(free | grep Mem | awk '{print $2}')
        freemem=$(free | grep Mem | awk '{print $7}')
        mempercent=$((100*$freemem/$totalmem))

        # ====Cacheability Variable
        # $nostatic greps out the filetypes specified in the nginx conf (filetypes that are handled by nginx),
        # so that we can get a count of real requests, then compare to apache requests 
        nostatic=$(egrep -v '.+\.(jpe?g|gif|png|css|js|ico|zip|7z|tgz|gz|rar|bz2|do[ct][mx]?|xl[ast][bmx]?|exe|pdf|p[op][ast][mx]?|sld[xm]?|thmx?|txt|tar|midi?|wav|bmp|rtf|avi|mp\d|mpg|iso|mov|djvu|dmg|flac|r70|mdf|chm|sisx|sis|flv|thm|bin|swf|cert|otf|ttf|eot|svgx?|woff2?|jar|class|log|web[ma]|ogv)' /var/log/nginx/*.apachestyle.log.1 | wc -l)

        # ==== DISK space variables



        # Based on the total memory, make an educated guess about what plan level this is
        if [ "$totalmemgigsround" -lt "6" ]; then
                planlevel="Business Plus"
        elif [ "$totalmemgigsround" -gt "6" ] && [ "$totalmemgigsround" -lt "10" ]; then
                planlevel="P1"
        elif [ "$totalmemgigsround" -gt "10" ] && [ "$totalmemgigsround" -lt "20" ]; then
                planlevel="P2"
        else
                planlevel="P3"
        fi

        # ====Apache hits today variables
        tophits=$(sudo cat /var/log/apache2/*.access.log | awk '{print $6,$7}' | sort | uniq -c | sort -rnk1 | head -8)
        yesterdaytophits=$(sudo cat /var/log/apache2/*.access.log.1 | awk '{print $6,$7}' | sort | uniq -c | sort -rnk1 | head -8)
        largestlogs=$(ls -laSh /var/log/apache2/ | grep -v "log.1" | grep -v total | awk '{print $5,$9}' | head -5)

        # ====Database size variables
        totaldatabasesize=$(sudo du -sch $dbsizepath | grep total | awk '{ print $1}')
        highesttrafficsite=$(egrep -v '.+\.(jpe?g|gif|png|css|js|ico|zip|7z|tgz|gz|rar|bz2|do[ct][mx]?|xl[ast][bmx]?|exe|pdf|p[op][ast][mx]?|sld[xm]?|thmx?|txt|tar|midi?|wav|bmp|rtf|avi|mp\d|mpg|iso|mov|djvu|dmg|flac|r70|mdf|chm|sisx|sis|flv|thm|bin|swf|cert|otf|ttf|eot|svgx?|woff2?|jar|class|log|web[ma]|ogv)' /var/log/nginx/*.apachestyle.log.1 | awk '{ print $1 }' | cut -d ':' -f 1 | sed 's/\/var\/log\/nginx\///' | cut -d '.' -f 1 | sort | uniq -c | sort -rnk1 | head -1 | awk '{ print $2 }')
        hightrafficsitedb=$(sudo du -sch "${dbsizepath}"wp_"${highesttrafficsite}" | grep total | awk '{ print $1}')

# =============================
# OUTPUT BEGINS HERE
# =============================

        # Shows basic server specs: number of cores & memory info. If cluster, confirm # of webheads.
        # If pod, confirm P1,2,3. Based on the RAM, that should determine what level they are 
        # probably on
        echo -e "\e[0;33m======================\e[0m"        
        echo -e "\e[0;33mSERVER SPECS\e[0m"
        echo -e "\e[0;33m======================\e[0m"        
        echo "This server has $cpu cores. "
        echo "Total memory is ${totalmemgigs}G. Current memory usage shows $mempercent% memory free. "
        echo "Total disk size is ${disktotal}. Server is ${diskinuse} full."
        if [ "$iscluster" == true ]; then 
                echo "This environment has $totalwebs webheads. "
        else
                echo "Based on RAM, this is probably a $planlevel plan. "

        fi
        printf "\n"


        # High Admin Ajax or other calls. This shows the top apache hits on the whole server
        # today and yesterday and a lits the largest apache logs to get an idea of which sites are
        # using the most resources
        echo -e "\e[0;33m======================\e[0m"
        echo -e "\e[0;33mPOTENTIAL ISSUES\e[0m"
        echo -e "\e[0;33m======================\e[0m"
        echo -e "\e[1;31mApache Hits Today\e[0m"
        echo "$tophits"
        echo -e "\e[1;31mApache Hits Yesterday\e[0m"
        echo "$yesterdaytophits"
        echo -e "\e[1;31mLargest Apache Log Sizes (Resource Use)\e[0m"
        echo "$largestlogs"
        printf "\n"

        # Gives us the server's cacheability as a percentage, using the access logs
        # from yesterday, since they contain a full day's worth of requests
        echo -e "\e[1;31mCacheability\e[0m"
        # First check to see if there's 0 traffic
        if [ "$nostatic" == 0 ]; then
                echo "Hmm, looks like there's no traffic here. No cacheability info available."
        else
        uncached=$(cat /var/log/apache2/*.access.log.1 | wc -l)
        percent=$((100*$uncached/$nostatic))
        billy=$((100-$percent))
        echo "Total real requests to nginx yesterday (without static files): $nostatic"
        echo "Total uncached requests to Apache yesterday: $uncached"
        echo "$percent% of all requests are uncached. Cacheability is $billy% on this server"
        fi
        printf "\n"

        # Errors (50x, or other)= Shows how many there were in the past week (in all available
        # logs) and where they came from 
        echo -e "\e[1;31mError History\e[0m"
        echo "Checking history of 50x errors in all available apachestyle logs..."
        # Variable placed here because it takes a while to load
        errorhistory=$(zgrep -E "\" 50[2,4] " /var/log/nginx/*.apachestyle.log.* | sed -e "s_/var/log/nginx/__" -e "s_.apachestyle.log_ _" | awk '{ print $10,$1 }' | sort | uniq -c | sort -rn | head -5)
        if [ -z "$errorhistory" ]; then
                echo "No errors to report!"
        else
                echo "$errorhistory"
        fi
        printf "\n"

        # Checks size of all databases based on pod/cluster. Automatically grabs the site with the
        # most traffic and checks the db size of that install
        echo -e "\e[1;31mTotal Database Size\e[0m"
        echo "Total size of all databases on this server in $dbsizepath is $totaldatabasesize"
        if [ -z "$highesttrafficsite" ]; then
                :
        else echo -e "The site receiving the most traffic is \e[0;33m${highesttrafficsite}\e[0m and its db size is $hightrafficsitedb"
        fi

}

