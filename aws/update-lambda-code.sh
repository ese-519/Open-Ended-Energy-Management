#!/bin/bash -eux

FUNCTION_NAME="lambdaEnergyManagement"

zip lambda_code.zip lambda_function.py

aws lambda update-function-code \
  --function-name ${FUNCTION_NAME} \
  --zip-file "fileb://lambda_code.zip"

echo "Code for ${FUNCTION_NAME} successfully updated."
