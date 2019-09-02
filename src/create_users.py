#!/usr/bin/env python

# This script is designed to make it easy (easier) to create the CSV file
# of usernames and passwords expected by the Conjuring Dockerfile. We need
# to do this because JupyterHub expects all users to have entries in PAM
# (or it's equivalent), so as part of the setup we need to create a 'real'
# user in the container for JupyterHub to use.
#
# Please use create_users.py -h to see available options for generating these. 
# A few parameters are specified within this script since they are unlikely to
# ever be changed by the user. These can be found just below the import statements.

import os
import csv 
import string
import secrets
import argparse

# Where to find Conjuring's custom directory and, within that, the users file 
# that will be used to create users in the container.
custom_dir = 'custom'
users_file = 'users.csv'

# Some necessary elements of the CSV file and password creation process.
header = ['Username','Password']
password_chars = list(string.ascii_letters) + list(string.digits) + ['_',':',';','(',')']

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
parser.add_argument('--append', type=bool, default=False, help='If we have already created users but need to add some more then we don\'t want to blow away the existing users.')

args=parser.parse_args()

print("Generating usernames and passwords for use by Conjuring container and JupyterHub...")

# Figure we should reinforce this choice for the user (in case the param name wasn't enough).
if args.unsafe_pwd is not None:
    print("\tDefaulting to unsafe passwords based on '{0}' + user number".format(args.unsafe_pwd))

# If we are appending then we need to see where we stopped creating users so that we can 
# initialise our starting point as the maximum + 1 of the _previous_ list of user numbers.
start_pt = 1
write_md = 'w'
if args.append is True:
    # Read in the file 
    with open(os.path.join('.',custom_dir,users_file), 'r') as csvfile:
        pwd = csv.reader(csvfile, delimiter=',',
                            quotechar='|')
        
        # We're going to try to extract the _last_ username if there's
        # no admin user, or the _second to last_ username if there is an
        # admin user. Note that this assumes you're aren't changing the 
        # settings after running the users script for the first time!
        try: 
            last_user = list(pwd)[(-2 if args.create_admin is True else -1)][0] # Ternary operator to switch between -1 and -2 from users list
            start_pt  = int(last_user.replace(args.usernm,''))+1 # Assume user name template can't change so to just remove the template and take what's left (should be an int)
            write_md = 'a' # Change the write mode to append
            args.create_admin = False # Don't re-create the admin user
        except IndexError:
            # Suggests that the file exists but is empty/uninitialised, so pass without setting write mode.
            # You could also get other errors from the above section, but they would suggest that 
            # user has changed the configuration parameters _after_ initialising the container
            # which is something we don't want to deal with.
            pass 

# And write the CSV file
with open(os.path.join('.',custom_dir,users_file), write_md, newline='') as csvfile:
    pwd = csv.writer(csvfile, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
    
    # Only write header row if _not_ appending.
    if args.append is False: 
        pwd.writerow(header)

    # Create new users from starting point (can be 1 for new file or the last
    # non-admin user created if appending to file)
    for i in range(start_pt,start_pt+args.num):

        # Generate password according to specified user policy.
        if args.unsafe_pwd is not None:
            pwd.writerow([args.usernm + str(i), args.unsafe_pwd + str(i)])
        else:
            pwd.writerow([args.usernm + str(i), ''.join(secrets.choice(password_chars) for i in range(args.pwdlen))])
    print("\tCreated username and password for " + ('' if args.append is False else 'another ') + str(args.num) + " users.")

    # Create admin user. This can be set to False above if script detects that 
    # file already exists so that user doesn't accidentally re-create the
    # admin user later.
    if args.create_admin is True:
        pwd.writerow([args.admin_user, ''.join(secrets.choice(password_chars) for i in range(args.admin_len))])
        print("\tCreated admin username (" + args.admin_user + ") and password.")

exit()