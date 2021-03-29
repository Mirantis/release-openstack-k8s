What is TryMOS
==============

TryMOS is all-in-one QCOW image intended to provide a lightweight
installation of OpenStack on Kubernetes for hands-on experience and
showcase.


What is NOT the case for TryMOS
===============================

* TryMOS is NOT the same as MOS
* TryMOS does NOT support all deployment use-cases supported by MOS
* TryMOS should NOT be used for production and semi-production environments
* TryMOS does NOT contain an MCC layer
* TryMOS is all-in-one installation without HA scenarios
* TryMOS is NOT intended for long running

What is the case for TryMOS
===========================

* Virtual environments only
* Quick deployment of OpenStack on Kubernetes
* Hands-on experience and architecture of OpenStack on Kubernetes
* Support for a limited set of deployment configuration

Obtain the TryMOS image
=======================

#. Navigate to https://binary.mirantis.com/?prefix=trymos/bin/.
#. Download the latest release artifact. For example, ``6.12.0``


Run TryMOS on AWS
=================

#. Download the image as describe in the "Obtain the TryMOS image" step:

   .. code-block:: console

      TRYMOS_IMAGE_FILE="trymos-bionic-amd64-6.12.0-20210323130215.qcow2"

#. Convert the QCOW2 image to the RAW format

   .. code-block:: console

      qemu-img convert -f qcow2 -O raw ${TRYMOS_IMAGE_FILE} ${TRYMOS_IMAGE_FILE%.*}.raw

#. Upload the RAW image to the S3 storage, where ``trymos-raw``
   is the name of a bucket:

   .. code-block:: console

      aws s3 cp ${TRYMOS_IMAGE_FILE%.*}.raw s3://trymos-raw

4. Create a snapshot from the image:

   .. code-block:: console

      cat << EOF > containers.json
      {
        "Description": "TryMOS RAW",
        "Format": "RAW",
        "UserBucket": {
            "S3Bucket": "trymos-raw",
            "S3Key": "${TRYMOS_IMAGE_FILE%.*}.raw"
        }
      }
      EOF
      aws ec2 import-snapshot --disk-container file://containers.json

#. Wait until the task is completed

   .. code-block:: console

      aws ec2 describe-import-snapshot-tasks --import-task-ids <task-id>

#. In the EC2 UI, navigate to ``Service > Elastic Block Store > Snapshots > Actions > Create image``
   to create an image from the snapshot. Create the image with root storage 35 GB and additional volume
   20 GB (volume type EBS (gp3))

#. In the EC2 UI, navigate to ``Service > Images > AMIs > Launch`` to launch the instance from the image
   with flavor minimal 16 CPUs and 30 GB RAM (c4.4xlarge).

#. Connect to the instance through an external IP address with the key file that was defined when
   the instance was brought up as root:

   .. code-block:: console

      ssh <Instance IP> -i ./ssk-key.rsa -l root

#. Run the installation script

   .. code-block:: console

      /usr/share/trymos/launch.sh


Run TryMOS on OpenStack
=======================

#. Download the image as describe in the "Obtain the TryMOS image" step:

   .. code-block:: console

      TRYMOS_IMAGE_FILE="trymos-bionic-amd64-master-20210316183204.qcow2"

#. Upload the image to OpenStack:

   .. code-block:: console

      openstack image create ${TRYMOS_IMAGE_FILE} --file ${TRYMOS_IMAGE_FILE}  --container-format bare --disk-format qcow2

#. Verify that the required resource exists:

   .. code-block:: console

      openstack flavor show mosk.aio.ephemeral
      +----------------------------+--------------------------------------+
      | Field                      | Value                                |
      +----------------------------+--------------------------------------+
      | OS-FLV-DISABLED:disabled   | False                                |
      | OS-FLV-EXT-DATA:ephemeral  | 50                                   |
      | access_project_ids         | None                                 |
      | disk                       | 100                                  |
      | id                         | e6a602cb-e882-44c4-ad36-e0512164ac57 |
      | name                       | mosk.aio.ephemeral                   |
      | os-flavor-access:is_public | True                                 |
      | properties                 |                                      |
      | ram                        | 32768                                |
      | rxtx_factor                | 1.0                                  |
      | swap                       |                                      |
      | vcpus                      | 16                                   |
      +----------------------------+--------------------------------------+

4. Download Heat templates:

   .. code-block:: console

      git clone https://github.com/Mirantis/release-openstack-k8s
      git branch -a
      git checkout -b <latest release>
      cd trymos/heat-templates

#. Set the correct image in the Heat environment:

   .. code-block:: console

      sed -i "s/trymos-bionic-amd64-nightly/${TRYMOS_IMAGE_FILE}" env/aio.yaml

#. Launch the stack:

   .. code-block:: console

      openstack stack create -t top.yaml -e env/aio.yaml trymos-stack

#. Launch the VM and verify the deployment status:

   .. code-block:: console

      tail -f /var/log/cloud-init-output.log
