#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This script is used to configure Conjuring for a deployment.
# Depending on the parameters entered you will either enter an
# interactive mode or will have conjuring prepped for deployment
# using your specified options.

import os
import csv 
import string
import secrets
import argparse

# Where to find Conjuring's custom directory.
custom_dir = 'custom'

parser=argparse.ArgumentParser(
    description='''
    This script is used to configure Conjuring for a deployment.
    Depending on the parameters entered you will either enter an
    interactive mode or will have conjuring prepped for deployment
    using your specified options.
    ''',
    epilog="""Please see https://github.com/conjuring/conjuring for more help/to report issues.""")
parser.add_argument('--num', type=int, default=20, help='The number of users to create (defaults to 20).')
parser.add_argument('--usernm', type=str, default="conjuring", help="If you want to set up usernames that follow a template that would be familiar to students/participants then specify a string here and the user \'number\' will be appended to this (defaults to conjuring).")
parser.add_argument('--pwdlen', type=int, default=8, help='The length of passwords to create (defaults to 8 as we\'re not that concerned about security).')
parser.add_argument('--unsafe_pwd', type=str, default=None, help='If you want to use a password format like \'test1\'..\'testn\' then specify a string template here. Defaults to None on the basis that you _should_ generate random passwords where possible.')
parser.add_argument('--create_admin', type=bool, default=False, help='Do you want to create an admin user? Defaults to False for basic security reasons.')
parser.add_argument('--admin_user', type=str, default="admin", help='Name of admin user if not \'admin\' (optional)')
parser.add_argument('--admin_len', type=int, default=12, help='Length of admin user password (defaults to 12 for security reasons).')
parser.add_argument('--append', type=bool, default=False, help='If we have already created users but need to add some more then we don\'t want to blow away the existing users.')

args=parser.parse_args()

print(args.num)

exit()