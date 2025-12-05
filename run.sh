#!/usr/bin/env bash

set -ex

sudo apt-get update
sudo apt-get install msmtp msmtp-mta mailutils -y

echo 'session optional pam_exec.so seteuid /usr/local/bin/login-notify' | sudo tee -a /etc/pam.d/sshd

sudo bash -c 'cat <<EOF > /usr/local/bin/login-notify
#!/usr/bin/env bash

set -ex

USER=\$PAM_USER
HOST=\$(hostname)
IP=\$PAM_RHOST
DATE=\$(date "+%Y-%m-%d %H:%M:%S")

LOG_FILE="/var/log/ssh-logins.log"

echo "[\$DATE] User: \$USER | From IP: \$IP | Host: \$HOST" >> \$LOG_FILE

EMAIL=${GMAIL}
echo "SSH Login Alert - \$HOST
User: \$USER
IP Address: \$IP
Time: \$DATE" | sudo mail -s "SSH Login: \$USER@\$HOST" \$EMAIL
EOF'

sudo chmod +x /usr/local/bin/login-notify
sudo touch /var/log/ssh-logins.log
sudo chown root:root /var/log/ssh-logins.log
sudo chmod 666 /var/log/ssh-logins.log

sudo bash -c 'cat <<EOF> /etc/msmtprc
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           ${GMAIL_SEND}
user           ${GMAIL_SEND}
passwordeval   ${APP_PASSWORD}

account default : gmail
EOF'

sudo chmod 644 /etc/msmtprc
