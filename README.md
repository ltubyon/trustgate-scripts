# trustgate-scripts
Ubyon miscellaneous trustgate related scripts.

ubos_install.sh
--------------

  This script is used to bootstrap Ubyon TrustGate cluster. Ubyon TrustGate is
  cloud managed k8s-based cluster. This script first installs systemd daemon
  'ubos.service'. 'ubos.service' then establishes communication with Ubyon
  mgmt cloud to complete TrustGate cluster installation.

  Note the following string patterns should be replaced before user runs
  'ubos_install.sh':
  * %(QUAY_IO_TOKEN)s
  * %(CLUSTER_UUID)s
  * %(NODE_UUID)s
  * %(CORE_SERVER_ENDPOINT)s
  * %(USER_BLOB)s
