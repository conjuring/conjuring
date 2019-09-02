#!/usr/bin/env python

import os
import csv 
import string
import secrets
import random 
import argparse

custom_dir = 'custom'
users_file = 'users.csv'
header = ['Username','Password']
password_chars = list(string.ascii_letters) + list(string.digits) + ['_',':',';','(',')']

import argparse

parser=argparse.ArgumentParser(
    description='''
    This script is designed to make it easy (easier) to create the CSV file
    of usernames and passwords expected by the Conjuring Dockerfile. We need
    to do this because JupyterHub expects all users to have entries in PAM
    (or it's equivalent), so as part of the setup we need to create a 'real'
    user in the container for JupyterHub to use.
    ''',
    epilog="""Please see https://github.com/conjuring/conjuring for more help/to report issues.""")
parser.add_argument('--num', type=int, default=20, help='The number of users to create (defaults to 20).')
parser.add_argument('--usernm', type=str, default="conjuring", help="If you want to set up usernames that follow a template that would be familiar to students/participants then specify a string here and the user \'number\' will be appended to this (defaults to conjuring).")
parser.add_argument('--pwdlen', type=int, default=8, help='The length of passwords to create (defaults to 8 as we\'re not that concerned about security).')
parser.add_argument('--unsafe_pwd', type=str, default=None, help='If you want to use a password format like \'test1\'..\'testn\' then specify a string template here. Defaults to None on the basis that you _should_ generate random passwords where possible.')
parser.add_argument('--create_admin', type=bool, default=False, help='Do you want to create an admin user? Defaults to False for basic security reasons.')
parser.add_argument('--admin_user', type=str, default="admin", help='Name of admin user if not \'admin\' (optional)')
parser.add_argument('--admin_len', type=int, default=12, help='Length of admin user password (defaults to 12 for security reasons).')

args=parser.parse_args()

print("Generating usernames and passwords for use by Conjuring container and JupyterHub...")

if args.unsafe_pwd is not None:
    print("\tDefaulting to unsafe passwords based on '{0}' + user number".format(args.unsafe_pwd))

with open(os.path.join('.',custom_dir,users_file), 'w', newline='') as csvfile:
    pwd = csv.writer(csvfile, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
    pwd.writerow(header)

    for i in range(1,args.num+1):
        if args.unsafe_pwd is not None:
            pwd.writerow([args.usernm + str(i), args.unsafe_pwd + str(i)])
        else:
            pwd.writerow([args.usernm + str(i), ''.join(secrets.choice(password_chars) for i in range(args.pwdlen))])
    print("\tCreated username and password for " + str(args.num) + " users.")

    if args.create_admin is True:
        pwd.writerow([args.admin_user, ''.join(secrets.choice(password_chars) for i in range(args.admin_len))])
        print("\tCreated admin username (" + args.admin_user + ") and password.")

exit()