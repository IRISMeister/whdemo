#!/bin/bash

export COMMIT_ID=$(git show -s --format=%H)
docker-compose -f ../whdemo-maker/docker-compose.yml push
docker-compose -f ../whdemo-wsdc/docker-compose.yml push
docker-compose -f ../whdemo-wsdemo/docker-compose.yml push
docker-compose -f ../whdemo-wshq/docker-compose.yml push
