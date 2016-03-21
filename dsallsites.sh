function dsallsites() {

path=`pwd` && install=`cut -d/ -f5 <<<"${path}"`; SUM=''; DU_LIST=''; INSTALL=$install; for i in `sudo php /nas/wp/ec2/cluster.php parent-child $INSTALL 2>/dev/null`; do DU_LIST=$(echo -e "$DU_LIST \n$(du -h --max-depth=0 /nas/content/{staging,live}/${i} 2>/dev/null)\n"); SUM=$(echo -e "$SUM \n$(du --max-depth=0 /nas/content/{staging,live}/${i} 2>/dev/null | awk '{print $1;}')"); done; echo -e "$DU_LIST\n\n" | sort -h; awk '{s+=$1} END {print "Total: "s/1024/1024" GB"}' <<<"$SUM"

}
