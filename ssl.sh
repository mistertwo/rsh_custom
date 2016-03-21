function ssl(){ # clb or pod	 			<pod_number>

  if [ "$1" = "clb" ] ; then
    host=`hostname` && pod=`cut -d- -f2 <<<"${host}"`; CLB_IP=$(dig lbmaster-$pod.wpengine.com +short A) ; echo -e "\nDomain:"; read -e domain; echo -e "CLB IP:\t$CLB_IP"; openssl s_client -servername $domain -connect $CLB_IP:443 | openssl x509 -text | grep 'Not Before\|Not After\|CN=\|DNS:';
  elif [ "$1" = "pod" ] ; then
    host=`hostname` && pod=`cut -d- -f2 <<<"${host}"`; POD_IP=$(dig pod-$pod.wpengine.com +short A); echo -e "\nDomain:"; read -e domain; echo -e "POD IP:\t$POD_IP"; openssl s_client -servername $domain -connect $POD_IP:443 | openssl x509 -text | grep 'Not Before\|Not After\|CN=\|DNS:';
  elif [ "$1" = "decode" ] ; then
    echo -e "\nCert File:"; read -e cert; openssl x509 -in $cert -text -noout
  elif [ "$1" = "hash" ] ; then
    echo -e "\nCert File:"; read -e cert; echo -e "\nKey File:"; read -e key; openssl x509 -noout -modulus -in $cert | openssl md5; openssl rsa -noout -modulus -in $key | openssl md5;
  elif [ "$1" = "getcrt" ] ; then
    echo -e "\nCert File:"; read -e cert; SSLURL=$(openssl x509 -in $cert -text -noout | grep "CA Issuers");
      if ["$SSLURL" = ""]
        then
        echo -e "\nEnd of Chain.\n"
      else
        CERTURL=`cut -d ":" -f 2- <<<"${SSLURL}"`;  CERTFILE=$(echo "$CERTURL" | rev | cut -d'/' -f 1 | rev); wget "$CERTURL"; openssl x509 -inform der -in $CERTFILE -out $CERTFILE; echo "$CERTFILE";
      fi
  else
    echo -e "\nSpecify one of the following:\n
     clb     - to check the SSL installed on the CLB
     pod     - to check the SSL installed on the POD
     decode  - to decode the SSL Certificate
     hash    - to check and see if the Cert and Key files match
     getcrt  - to get the next cert in the chain\n";
  fi
}

