#!/usr/bin/env python
# list-s3-buckets.py - v1.0 - Tristan Self
# Simple and quick script to output the s3 Buckets within an AWS account.
# Assumes you have already got an AWS session open, by running "aws configure".

import boto3

s3 = boto3.resource('s3')

bucketcount = 0
print("Listing S3 Buckets")

for bucket in s3.buckets.all():
    bucketcount = bucketcount + 1
    print("\033[1;32m" + str(bucketcount) + ":" + bucket.name + "\033[0;37;40m")

print("Buckets: ", end='')
print(bucketcount)
