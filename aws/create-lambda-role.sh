#!/bin/bash -eux

aws iam create-role \
  --role-name "EnergyManagementLambdaRole" \
  --assume-role-policy-document file://LambdaRole.json

