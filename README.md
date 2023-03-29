# trustgate-scripts
Ubyon miscellaneous trustgate related scripts.

ubos_install.sh
---------------

  This script is used to bootstrap Ubyon TrustGate cluster. Ubyon TrustGate is
  cloud managed k8s-based cluster. This script first installs systemd daemon
  *ubos.service*. *ubos.service* then establishes communication with Ubyon
  mgmt cloud to complete TrustGate cluster installation.

  Note the following string patterns should be replaced before user runs
  *ubos_install.sh*:
  * %(QUAY_IO_TOKEN)s
  * %(CLUSTER_UUID)s
  * %(NODE_UUID)s
  * %(CORE_SERVER_ENDPOINT)s
  * %(USER_BLOB)s

ubos_prepare.sh
----------------

  This script can be used to prepare a Ubuntu20 VM to be ready to run
  *ubos_install.sh*.

  Note *ubos_prepare.sh* is not required if TrustGate is deployed on any of the
  cloud provider VM (AWS, Azure, and GCP). *ubos_install.sh* has been verified
  to work on these cloud provider VMs.

  To run the script:
  * curl https://raw.githubusercontent.com/Ubyon/trustgate-scripts/main/ubos_prepare.sh | bash
