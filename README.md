# Build Ubuntu AMI

A simple, secure tool for customizing Ubuntu images for Amazon EC2 from your local computer.

## Install

    gem install build-ubuntu-ami

## Basic Usage

See [examples](https://github.com/kickstarter/build-ubuntu-ami/tree/master/examples) of custom build scripts.

    # Create a custom AMI from my_script.sh
    build-ubuntu-ami my_custom_script.sh

    # Show options
    build-ubuntu-ami -h

## How it works

This program is based on Eric Hammond's blog post [Creating Public AMIs Securely for EC2](http://alestic.com/2011/06/ec2-ami-security), and his shell script [alestic-git-build-ami](https://github.com/alestic/alestic-git/blob/master/bin/alestic-git-build-ami).

It works as follows:

1. Boot an official Ubuntu EC2 instance
2. Download and mount a copy of the official Ubuntu root volume image
3. Run the custom user script in a chrooted environment on that image
4. Attach an empty EBS volume
5. Copy the customized boot image to the EBS volume
6. Register an AMI from the customized EBS volume

Booting and logging in to a system offers many opportunities to leak secret credentials (even if you [delete them](http://alestic.com/2009/09/ec2-public-ebs-danger)). Creating an AMI from a pristine image rather than a running root volume obviates the need to remove leaked credentials.

This script does not need a private key & cert for credentials. It uses the AWS Access Key ID and Secret Access Key.

## Troubleshooting

If you're running into an issue where you need to run CLI commands, its helpful to ssh to the instance and enter into the chroot environment. Do the following:

   $ cd /mnt/$IMAGE_NAME
   $ sudo chroot . /bin/bash

