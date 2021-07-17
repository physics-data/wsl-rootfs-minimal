#!/bin/bash

set -e

EXTRA=$(awk '{print $1}' packages.txt | paste -s -d, -)
EXCLUDED=$(awk '{print $1}' excluded.txt | paste -s -d, -)

echo "Extra packages: $EXTRA"
echo "Excluded packages: $EXCLUDED"

debootstrap --include=$EXTRA --exclude=$EXCLUDED focal ./rootfs

cat > ./rootfs/etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-security main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-updates main restricted universe multiverse
EOF

cat >> ./rootfs/root/.bashrc << EOF
GATEWAY=\$(ip r | grep "^default" | awk '{ print $3 }')
export DISPLAY=\$GATEWAY:0
EOF

rm -rf ./rootfs/var/cache/*

tar -cf ./rootfs.tar -C ./rootfs .

sha256sum rootfs.tar > rootfs.tar.sha256
