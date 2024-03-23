/usr/sbin/make-ca -g
python -m ensurepip
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo $GHCRTOKEN | skopeo login ghcr.io --username $ACTOR --password-stdin

mkdir /var/tmp

mkdir /tmp/packages && git clone https://github.com/stable-os/packages.git /tmp/packages
cd /tmp/packages

pkg-builder packages/linux/$1.toml /tmp/out.tar.gz

echo Created package, creating build repository

cd /

mkdir /build-repo && ostree --repo=/build-repo init --mode=bare-user

echo Created build repository, importing package

ostree --repo=/build-repo commit -b stable-os/$(uname -m)/linux --tree=tar=/tmp/out.tar.gz

echo Cleaning up to save disk space

rm -rf /tmp
mkdir /tmp

echo Imported package, exporting as OCI image

ostree-ext-cli container encapsulate --repo=/build-repo stable-os/$(uname -m)/linux docker://ghcr.io/stable-os/package-$1-$(uname -m)-builtonstableos:latest
