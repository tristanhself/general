#!/usr/bin/python3
import os

username = os.getenv('API_USER')
password = os.getenv('API_PASSWORD')

if "API_USER" in os.environ and "API_PASSWORD" in os.environ:
    print("Variables OK")
    print("Username:",username)
    print("Password:",password)
else:
    print("Variables Missing!")
    print("Create API_USER and API_PASSWORD environment variables, then re-run script")
