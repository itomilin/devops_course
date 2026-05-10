#!/usr/bin/env bash

curl -s \
     -u "$JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD" \
     -g "http://localhost:8080/pluginManager/api/json?tree=plugins[shortName,version]" | json_pp

