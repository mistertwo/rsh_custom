function clb(){ # CLB There	 			<pod_number>
  # pod provided, or not
  if [ $1 ] ; then
    CID=$1; CLB_IP=$(dig lbmaster-$CID.wpengine.com +short A); echo -e "CLB IP:\t$CLB_IP"; POD_IP=$(dig pod-$CID.wpengine.com +short A); echo -e "POD IP:\t$POD_IP"; if [[ "$CLB_IP" == "$POD_IP" ]]; then echo "Congrats. $CID is un-clb-ified."; else echo "pod-$CID is clb'd"; fi
  else
    echo -e "\nI need an pod number yo!\n"
  fi
}
