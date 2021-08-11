#!/bin/bash

set -e

EXTRA=$(awk '{print $1}' packages.txt | paste -s -d, -)
EXCLUDED=$(awk '{print $1}' excluded.txt | paste -s -d, -)

echo "Extra packages: $EXTRA"
echo "Excluded packages: $EXCLUDED"

rm -rf ./rootfs

debootstrap --include=$EXTRA --exclude=$EXCLUDED bullseye ./rootfs

cat > ./rootfs/etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-security main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-updates main contrib non-free
EOF

cat >> ./rootfs/etc/wsl.conf << EOF
[user]
default=debian
EOF

chroot ./rootfs << EOF
useradd -m -s /bin/bash debian
usermod -G sudo -a debian

echo "debian:deadly-solar-laser" | chpasswd
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install wheel matplotlib h5py pandas scipy numpy pillow
EOF

cat >> ./rootfs/home/debian/.bashrc << EOF
SSH_ENV="$HOME/.ssh/agent-environment"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi
EOF

rm -rf ./rootfs/var/cache/*

tar -cf ./rootfs.tar -C ./rootfs .
sha256sum rootfs.tar > rootfs.tar.sha256
zip -9 rootfs.tar.zip rootfs.tar
