# coiled-deploy
test deployment of [Coiled dask cluster](https://docs.coiled.io/user_guide/backends_aws.html#using-your-own-aws-account) on AWS us-west-2 on our own account.

## Set up cloud infrastructure on AWS

You'll need to install [terraform](https://www.terraform.io). On a Mac you can run:
```
brew install tfenv
tfenv install 0.14.8
tfenv use 0.14.8
```

### Create a bucket for storing remote terraform state
```
cd s3backend
terraform init
terraform apply
```

### Create a 'coiled' iam user and roles with permissions to create clusters
```
# from coiled-deploy root folder
terraform init
terraform apply
```
That command will output two access keys, you must visit your coiled account page and enter them under "Cloud Backend Options". Printing these keys in plain text to a terminal is not the best idea, but we assume you're doing this from your personal laptop. It's a good idea to store them encrypted in a password manager.

### Best practices with Cloud accounts

Treat your Cloud account just like a bank account (in fact most accounts are backed by credit cards), and be very careful with your access keys and permissions! We follow guidelines for best-practices here by creating a dedicated 'bot' user that only has permissions to do setup our infrastructure rather than setting everything up with our personal user account with full administrator access.

AWS has the security concepts of "Roles" and "Policies" for restricting access to cloud resources.

We create a user `coiled` who by default can't do anything on our account. We then create a Role "coiled-role" that our bot user (or other users in our account) can assume. It is the Role that has permissions "Policies" attached to it, and these policies allow us to do things that cost money like create EC2 instances, S3 buckets, etc.
