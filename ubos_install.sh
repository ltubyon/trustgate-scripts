#!/bin/bash

set -x

useradd -s /bin/bash -d /home/ubuntu/ -m -G sudo ubuntu

# Allow ubuntu sudo command without password.
grep "^ubuntu" /etc/sudoers > /dev/null 2>&1 || echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

cat > /root/setup_ubos.sh << 'BIGEOF'
#!/bin/bash

set -x

INSTALL_FINISHED="/root/.setup_ubos"

if [ -f $INSTALL_FINISHED ] ; then
  echo "Install has already finished."
  exit
fi

setup_repo()
{
  mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get -y update
}

systemctl stop --now unattended-upgrades.service
systemctl stop --now apt-daily.service
systemctl stop --now apt-daily-upgrade.service

systemctl disable --now unattended-upgrades.service
systemctl disable --now apt-daily.service
systemctl disable --now apt-daily-upgrade.service

# Completely mask off update and upgrade timer
systemctl mask apt-daily.timer
systemctl mask apt-daily-upgrade.timer

# Create default docker bridge: docker0
cat > /etc/netplan/51-docker0-init.yaml << 'EOF'
network:
  version: 2
  bridges:
    docker0:
      dhcp4: false
      dhcp6: false
      addresses: [172.17.0.1/16]
      parameters:
        stp: no
EOF

netplan apply
sleep 10

# Install docker
apt-get -y update

# Wait for any possibly running unattended upgrade to finish
systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true

# Install basic packages.
apt-get install -y ca-certificates curl gnupg lsb-release rsync

# Add Docker's official GPG key and repo.
grep "download.docker.com" /etc/apt/sources.list > /dev/null 2>&1 || \
  test -f /etc/apt/keyrings/docker.gpg || setup_repo

apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Add quay.io ubos read robo token.
DOCKER_DIR=/home/ubuntu/.docker
mkdir -p $DOCKER_DIR
cat > ${DOCKER_DIR}/config.json << 'EOF'

{
  "auths": {
    "quay.io": {
      "auth": "%(QUAY_IO_TOKEN)s",
      "email": ""
    }
  }
}

EOF

# Generate ssh key for ubos ssh into host.
SSH_DIR=/home/ubuntu/.ssh
mkdir -p $SSH_DIR
ssh-keygen -f ${SSH_DIR}/id_rsa -t rsa -N ''
cat ${SSH_DIR}/id_rsa.pub >> ${SSH_DIR}/authorized_keys

# Add ubos boot environment.
ETC_DIR=/etc/ubos
mkdir -p $ETC_DIR/tls
mkdir -p $ETC_DIR/package/k8s
# add boot script which loads environment variables
cat > ${ETC_DIR}/export_ubos_env << 'EOF'

# Export CLUSTER_UUID, NODE_UUID, and CORE_SERVER_ENDPOINT
CLUSTER_UUID=%(CLUSTER_UUID)s
NODE_UUID=%(NODE_UUID)s
CORE_SERVER_ENDPOINT=%(CORE_SERVER_ENDPOINT)s
USER_BLOB=%(USER_BLOB)s
EOF

# Change ownership to ubuntu
chown -R ubuntu:ubuntu ${DOCKER_DIR}
chown -R ubuntu:ubuntu ${SSH_DIR}
usermod -aG docker ubuntu

# Install ubos.service to systemd location
cat > /etc/systemd/system/ubos.service << 'EOF'
[Unit]
Description=Ubyon Base OS
After=docker.service

[Service]
TimeoutStartSec=0
User=ubuntu
Group=ubuntu
ExecStartPre=/usr/bin/docker pull quay.io/ubyon/ubos:1.1.0
ExecStart=/usr/bin/docker run --rm --name ubos \
    --env-file /etc/ubos/export_ubos_env \
    -p 2017:2019/tcp \
    -v /home/ubuntu/.ssh/id_rsa:/etc/tls/ubos_ssh_key:Z \
    -v /etc/ubos/package/k8s:/etc/ubos/package/k8s \
    quay.io/ubyon/ubos:1.1.0
ExecStop=/usr/bin/docker stop ubos
Restart=always
RestartSec=20

[Install]
WantedBy=multi-user.target
EOF

systemctl start --no-block ubos
systemctl enable ubos
touch $INSTALL_FINISHED

echo
echo "Installation completed successfully."
BIGEOF

chmod +x /root/setup_ubos.sh
cat > /etc/systemd/system/setup_ubos.service << 'EOF'
[Unit]
Description=Setup ubos
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/setup_ubos.sh
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl start setup_ubos
systemctl enable setup_ubos
