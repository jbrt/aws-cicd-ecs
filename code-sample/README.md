# Simple Python "Hello-world" application #

## Upload your SSH public key ##

Before cloning the CodeCommit repository, you have to upload your SSH key. Go 
into your IAM console:

1. Click on Users and select your username
2. Click on Security Credentials
3. Upload your SSH **public** key (section "SSH keys for AWS CodeCommit")
4. Finally, copy the SSH key ID displayed, you'll need it after

## Configure SSH ##

On your local machine, create a config file in your .ssh directory with:

```
Host git-codecommit.*.amazonaws.com
 User <YOUR_SSH_KEY_ID>
 IdentityFile <PATH_TO_YOUR_PRIVATE_FILE>
```

## Clone the repository ##

Clone the CodeCommit repository:

`git clone <URL_CODECOMMIT>`

## Push the files to CodeCommit ##

To do that, copy all the files from this present directory to the repository 
that you've just cloned.

Push the files with these commands:

```
git add . 
git commit -m "your comment"
git push origin master
```

Go into CodePipeline console and after few minutes the pipeline will wake up.
Once the deployment is over, use the load balancer URL to show the result.
