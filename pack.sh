#!/bin/bash

rm -rf modules
mv release modules
tar czf tv407.tgz firmware tv407.sh modules
