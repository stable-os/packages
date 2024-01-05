/usr/sbin/make-ca -g
python -m ensurepip
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo $GHCRTOKEN | skopeo login ghcr.io --username $ACTOR --password-stdin

mkdir /tmp/packages && git clone https://github.com/stable-os/packages.git /tmp/packages
cd /tmp/packages

# THIS IS A TEST!
pkg-builder packages/linux/linux.toml /tmp/out.tar.gz

echo Created package, creating build repository

mkdir /tmp/build-repo && ostree --repo=/tmp/build-repo init --mode=bare-user

echo Created build repository, importing package

ostree --repo=/tmp/build-repo commit -b stable-os/$(uname -m)/linux --tree=tar=/tmp/out.tar.gz

echo Imported package, exporting as OCI image

ostree-ext-cli container encapsulate --repo=/tmp/build-repo stable-os/$(uname -m)/linux docker://ghcr.io/stable-os/package-linux-$(uname -m)-builtonstableos:latest
