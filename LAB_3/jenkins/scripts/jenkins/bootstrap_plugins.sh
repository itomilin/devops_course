#!/usr/bin/env bash

CMD_TIMEOUT="5m"
if [[ "$USE_PROXY" == "true" ]]; then
  printf "\033[92m>>> Installing plugins with PROXY: $PROXY_OPTS\033[0m\n"
else
  printf "\033[92m>>> Installing plugins without PROXY\033[0m\n"
fi

if [[ -f "/usr/share/jenkins/ref/plugins.txt" ]]; then
  JAVA_OPTS="${PROXY_OPTS:-}" \
  timeout "$CMD_TIMEOUT" \
    jenkins-plugin-cli \
    --plugin-download-directory=/var/jenkins_home/plugins \
    --latest=false \
    --plugin-file /usr/share/jenkins/ref/plugins.txt

  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 ]]; then
    printf "\033[93m>>> Plugin installation timed out after $CMD_TIMEOUT! Check network, proxy settings, or DNS resolution.\033[0m\n\n"
    exit 1
  elif [[ $EXIT_CODE -eq 0 ]]; then
    printf "\033[92m>>> Plugin installation OK!\033[0m\n\n"
  else
    printf "\033[91m>>> Plugin installation failed with exit code: $EXIT_CODE\033[0m\n\n"
    exit 1
  fi
fi

exit 0

