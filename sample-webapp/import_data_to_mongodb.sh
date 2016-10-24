#!/bin/bash -eux

# first, start mongod

mongoimport -d donorschoose -c projects --type csv --headerline --file ./sampledata.csv