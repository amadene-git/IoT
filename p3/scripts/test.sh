#!/bin/bash

git clone http://gitlab.example.com/root/bonusiot.git
cd bonusiot
cat lol/deploy.yaml | grep "wil42/playground:v1"

var=$?

if [ $var -eq "0" ]
then
    sed -i 's/wil42\/playground\:v1/wil42\/playground\:v2/g' lol/deploy.yaml
    git add . ; git commit -m "v2" ; git push
    echo "change to v2"
else
    sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' lol/deploy.yaml
    git add .; git commit -m "v1"; git push
    echo "change to v1"
fi

cd ..
rm -rf iotplaygroundp3 

