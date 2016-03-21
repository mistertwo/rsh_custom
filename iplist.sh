function iplist(){

dig wpengine.com txt +short | grep -oP '(?<=include:)[^\s]+(?=\s)' | while read FQDN; do
  dig $FQDN txt +short | grep -E 'sendgrid' | grep -oP '(?<=ip[46]:)[^\s]+(?=\s)'
  dig $FQDN txt +short | grep -E 'sendgrid.' | grep -oP '(?<=include:)[^\s]+(?=\s)' | while read SENDGRIDFQDN; do
    dig $SENDGRIDFQDN txt +short | grep -oP '(?<=ip[46]:)[^\s]+(?=\s)'
  dig $FQDN txt +short | grep -E 'mailgun' | grep -oP '(?<=include:)[^\s]+(?=\s)' | while read MAILGUNFQDN; do
    dig $MAILGUNFQDN txt +short | grep -oP '(?<=ip[46]:)[^\s]+(?=\s)'
    done
  done
done

}
