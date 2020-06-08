#!/bin/sh
tar czf talkfinder.tgz jekyll/_site
set -x
openssl enc -a -d -aes-256-cbc -in deploy_rsa.enc -out deploy_rsa -pass env:DECYPHER_KEY
chmod 400 deploy_rsa

ssh -i deploy_rsa -o "StrictHostKeyChecking no" root@jugspeakers.online "mkdir -p /opt/talkfinder/talkfinder-${TRAVIS_BUILD_NUMBER}"

scp -i deploy_rsa -o "StrictHostKeyChecking no" talkfinder.tgz root@jugspeakers.online:/opt/talkfinder/talkfinder-${TRAVIS_BUILD_NUMBER}/talkfinder.tgz

ssh -i deploy_rsa root@jugspeakers.online "tar xzf /opt/talkfinder/talkfinder-${TRAVIS_BUILD_NUMBER}/talkfinder.tgz --strip-components=2 -C /opt/talkfinder/talkfinder-${TRAVIS_BUILD_NUMBER}"

rm -f deploy_rsa
