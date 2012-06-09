# Create custom Ubuntu AMIs the hard (secure) way

`build-ubunut-ami` is a simple, secure tool for customizing Ubuntu images for Amazon EC2 from your local computer.

## Why the hard way?

Booting and logging in to a system offers many opportunities to leak secret credentials (even if you [delete them](http://alestic.com/2009/09/ec2-public-ebs-danger)). Creating an AMI from a pristine image rather than a running root volume obviates the need to remove leaked credentials.

This program is based heavily on Eric Hammond's blog post [Creating Public AMIs Securely for EC2](http://alestic.com/2011/06/ec2-ami-security), and his shell script [alestic-git-build-ami](https://github.com/alestic/alestic-git/blob/master/bin/alestic-git-build-ami).

For convenience, this script does not need an AWS EC2 private key & cert for credentials. It uses the AWS Access Key ID and Secret Access Key instead.

## Install

    # Using rubygems
    gem install build-ubuntu-ami

## Basic Usage

    # Create a custom AMI from my_script.sh (see examples/ dir)
    build-ubuntu-ami my_script.sh

    # Show options
    build-ubuntu-ami -h

## How it works

build-ubuntu-ami uses the ruby [fog](http://fog.io) library to:

1. Boot an EC2 instance from the Canonical Ubuntu AMI
2. Download and mount a copy of the Canonical Ubuntu root volume image
3. Run your custom script in a chrooted environment on that image
4. Attach an new EBS volume
5. Copy the customized boot image to the EBS volume
6. Register an AMI using the customized EBS volume as the root volume.

Since you never booted or logged in to the customized EBS volume, there is reduced risk of leaking confidential information.

