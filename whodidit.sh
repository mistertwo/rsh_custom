whodidit() {
sudo zcat /var/log/messages.2 | egrep ' bash\[[0-9]+\]: [a-z]+_:'
sudo cat /var/log/messages.1 | egrep ' bash\[[0-9]+\]: [a-z]+_:'
sudo cat /var/log/messages | egrep ' bash\[[0-9]+\]: [a-z]+_:'
}
