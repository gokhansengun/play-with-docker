### Deploying to the cloud

#### Creating SSH Key Pair

The public key here will be uploaded to the VM so that the private key could be used to SSH into it

Move to `deploy/ssh` folder and create and `ssh` key pair using `ssh-keygen`. Program will prompt you with the path of `ssh` key pair. Respond the prompt with `./id_rsa` so that it creates the files in the current folder.

#### Creating VMs

Move to the folder for the cloud provider, ex `do` for `DigitalOcean`. Run following commands in order

```
terraform init
terraform apply
```


