#!/bin/bash

set -e

EXTRA=$(awk '{print $1}' packages.txt | paste -s -d, -)

echo "Extra packages: $EXTRA"

debootstrap --include=$EXTRA focal ./rootfs

cat > ./rootfs/etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-security main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-updates main restricted universe multiverse
EOF

tar -cf ./rootfs.tar -C ./rootfs .

sha256sum rootfs.tar > rootfs.tar.sha256
