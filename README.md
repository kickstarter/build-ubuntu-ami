# Looking for maintainers

I'm no longer maintaining this project. If you're interested in maintaining it, please post a comment [on this issue](https://github.com/kickstarter/build-ubuntu-ami/issues/25).

# Create custom Ubuntu AMIs the hard (secure) way

`build-ubuntu-ami` is a simple tool for making secure, custom Ubuntu images for Amazon EC2 from your local computer.

## Why the hard way?

Booting and logging in to a system offers many opportunities to leak secret credentials (even if you [delete them](http://alestic.com/2009/09/ec2-public-ebs-danger)). Creating an AMI from a pristine image rather than a running root volume obviates the need to remove leaked credentials.

This program is based on Eric Hammond's blog post [Creating Public AMIs Securely for EC2](http://alestic.com/2011/06/ec2-ami-security), and his shell script [alestic-git-build-ami](https://github.com/alestic/alestic-git/blob/master/bin/alestic-git-build-ami).

For convenience, this script does not need an AWS EC2 private key & cert for credentials. It uses the AWS Access Key ID and Secret Access Key instead.

## Install

    # Using rubygems
    gem install build-ubuntu-ami

## Configuration

`build-ubuntu-ami` relies on Fog. You will need to configure a `~/.fog` file, like so:

```yaml
:default:
  :aws_access_key_id: A..your key here...Z
  :aws_secret_access_key: A..........your key here...............Z
```

## Basic Usage

if you have not registered an SSH keypair named 'default' with AWS, you will need to supply a `-k` argument.

See [examples](https://github.com/kickstarter/build-ubuntu-ami/tree/master/examples) of custom build scripts.

    # Create a custom AMI from my_script.sh
    build-ubuntu-ami my_script.sh

    # Show options
    build-ubuntu-ami -h

    # Example output
    $ build-ubuntu-ami -k aaron-rsa -g aaron-test -b demoami custom.sh
    Configuration:
      region: us-east-1
      flavor: m1.small
      brand: demoami
      size: 20
      codename: lucid
      key_name: aaron-rsa
      group: aaron-test
      arch: amd64
      canonical ami: ami-0baf7662
      kernel: aki-427d952b
      description: demoami-lucid-amd64-20120609-0938
    Launching server...
    Launched i-dcf145a5; ec2-23-20-92-209.compute-1.amazonaws.com; waiting for it to be available.
    Attaching volume vol-597aef37
    waiting for user_data to complete and server to shut down...
    Follow along by running:
      ssh -l ubuntu ec2-23-20-92-209.compute-1.amazonaws.com 'tail -f /var/log/user.log'
    Detaching volume
    Waiting for volume to detach...
    Taking snapshot demoami-lucid-amd64-20120609-0938 root volume from vol-597aef37
    Creating snapshot snap-a4b6e8db
    Registered imageId ami-abcdef01
    Deleting vol-597aef37
    Terminating i-dcf145a5

## How it works

build-ubuntu-ami uses the ruby [fog](http://fog.io) library to:

1. Boot an EC2 instance from the Canonical Ubuntu AMI
2. Download and mount a copy of the Canonical Ubuntu root volume image
3. Run your custom script in a chrooted environment on that image
4. Attach an new EBS volume
5. Copy the customized boot image to the EBS volume
6. Register an AMI using the customized EBS volume as the root volume.

Since you never booted or logged in to the customized EBS volume, there is reduced risk of leaking confidential information.

## Troubleshooting

If you're running into an issue where you need to run CLI commands, its helpful
to ssh to the instance and enter into the chroot environment. Do the following:

   $ cd /mnt/$IMAGE_NAME
   $ sudo chroot . /bin/bash
