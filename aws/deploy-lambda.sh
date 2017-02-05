#!/bin/bash -eux

if (( $# != 1 )); then
  echo "usage: ./deploy-lambda.sh <lambda role arn>"
  exit
fi
LAMBDA_ROLE_ARN=$1

zip lambda_code.zip lambda_function.py

aws lambda create-function \
  --function-name "lambdaEnergyManagement" \
  --runtime "python2.7" \
  --role ${LAMBDA_ROLE_ARN} \
  --handler "lambda_function.lambda_handler" \
  --zip-file "fileb://lambda_code.zip" \
  --description "Lambda function to handle requests from Alexa" \
  --timeout 3 \
  --memory-size 128

echo "Next go to AWS Lambda console and add Trigger Alexa Skills Kit"
