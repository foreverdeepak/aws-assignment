#!/bin/bash

echo "I'll be doing bootstrap"

function check_internet() {
  retry_frequency=$1
  for i in $(seq 1 $retry_frequency); do
    if ping -c 1 -w 1 google.com >> /dev/null 2>&1; then
      echo "Internet is up, can proceed further now"
      return
    else
      echo "Internet connection timeout, continuing with check..."
    fi
  done
}

function setup_apache() {
  yum -y install httpd
  service httpd start
  echo "Hello AWS World – running on Windows – on port 80" > /usr/share/httpd/noindex/index.html
}

check_internet
setup_apache
