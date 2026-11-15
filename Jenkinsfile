node {
    stage('Preparation') {
        catchError(buildResult: 'SUCCESS') {
            sh 'docker stop samplerunning'
            sh 'docker rm samplerunning'
        }
    }
    
    stage('Checkout') {
        // Replicates the "Clean before checkout" UI checkbox
        deleteDir()
        
        // Automatically checks out the repository where this Jenkinsfile is located
        checkout scm
    }
    
    stage('Build') {
        sh 'bash ./sample-app.sh'
    }
    
    stage('Test') {
        sh '''#!/bin/sh
URL="http://172.16.0.10:5050/"
EXPECTED="You are calling me from 172.17.0.1"

echo "Waiting 5 seconds for the container to boot..."
sleep 5

echo "=== Testing $URL ==="
echo "Expected to contain: $EXPECTED"

HTTP_CODE=$(curl -sS --max-time 10 -o response.txt -w '%{http_code}' "$URL") || {
  echo "ERROR: curl could not connect to $URL"
  exit 1
}

echo "HTTP status: $HTTP_CODE"
echo "=== Actual response ==="
cat response.txt
echo
echo "======================="

if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: expected HTTP 200, got $HTTP_CODE"
  exit 1
fi

if grep -q "$EXPECTED" response.txt; then
  echo "PASS: response contains '$EXPECTED'"
else
  echo "FAIL: response does not contain '$EXPECTED'"
  exit 1
fi
'''
    }

    // Production is the Docker daemon on dmz010, reached over SSH. PRODUCTION_HOST
    // and PRODUCTION_DEPLOY_CREDENTIALS are global environment variables set by
    // Jenkins Configuration as Code (Ansible role buildserver).
    stage('Deploy to production') {
        withCredentials([sshUserPrivateKey(credentialsId: env.PRODUCTION_DEPLOY_CREDENTIALS,
                                           keyFileVariable: 'DEPLOY_KEY',
                                           usernameVariable: 'DEPLOY_USER')]) {
            sh '''#!/bin/bash
set -euo pipefail

# The docker client uses the ssh binary, which takes its key from an agent
eval "$(ssh-agent -s)" > /dev/null
trap 'ssh-agent -k > /dev/null' EXIT
ssh-add -q "$DEPLOY_KEY"

export DOCKER_HOST="ssh://${DEPLOY_USER}@${PRODUCTION_HOST}"

# Same build context as staging (created by sample-app.sh in the Build stage)
docker build -t sampleapp tempdir

docker rm -f samplerunning 2> /dev/null || true

# Published on localhost only: nginx on the host is the only way in, with TLS
docker run -d --name samplerunning --restart unless-stopped \
  -p 127.0.0.1:5050:5050 sampleapp
docker ps --filter name=samplerunning
'''
        }
    }

    stage('Test production') {
        sh '''#!/bin/bash
set -uo pipefail

# The Jenkins container cannot resolve the lab names itself, so the name is
# pinned to the address. -k: the certificate is self-signed.
URL="https://www.infra.lan/"
EXPECTED="You are calling me from"

echo "Waiting 5 seconds for the container to boot..."
sleep 5

echo "=== Testing $URL via $PRODUCTION_HOST ==="
HTTP_CODE=$(curl -sS -k --max-time 10 --resolve "www.infra.lan:443:${PRODUCTION_HOST}" \
  -o response.txt -w '%{http_code}' "$URL") || {
  echo "ERROR: curl could not connect to $URL"
  exit 1
}

echo "HTTP status: $HTTP_CODE"
cat response.txt
echo

if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: expected HTTP 200, got $HTTP_CODE"
  exit 1
fi

if grep -q "$EXPECTED" response.txt; then
  echo "PASS: production answers through the reverse proxy"
else
  echo "FAIL: response does not contain '$EXPECTED'"
  exit 1
fi
'''
    }
}
