#!/bin/bash

set -x

DISTRO=$1
SERIES=$2
IMAGE_NAME=$3

# get our stack env vars
. ~/stackrc

# create the image
sudo OVERWRITE_OLD_IMAGE=1 DIB_RELEASE=${SERIES} disk-image-create -o ${IMAGE_NAME}.qcow2 ${DISTRO} vm

# does the image already exist?
IMAGE_ID=`openstack image show ${IMAGE_NAME} -c id -f value`

# upload the new image, retrying twice if it fails
n=0
until [ $n -ge 2 ]
do
	glance image-create --visibility public --file ${IMAGE_NAME}.qcow2 --name ${IMAGE_NAME} --container-format bare --disk-format qcow2 && break
	n=$[$n+1]
	sleep 15
done

if [ $n -eq 2 ]
then
	echo Upload Failed
	exit 1
fi

if [ -n "${IMAGE_ID}" ] ; then
	# delete the old one
	glance image-delete ${IMAGE_ID}
fi
