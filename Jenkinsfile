node {
    stage('Preparation') {
        catchError(buildResult: 'SUCCESS') {
            sh 'docker stop samplerunning'
            sh 'docker rm samplerunning'
        }
    }
    
    stage('Checkout') {
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

echo "=== Testing $URL ==="
echo "Expected to contain: $EXPECTED"

# Fetch body to a file, capture the HTTP status code separately
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
}
