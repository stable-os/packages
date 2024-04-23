/usr/sbin/make-ca -g
python -m ensurepip
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo $GHCRTOKEN | skopeo login ghcr.io --username $ACTOR --password-stdin

mkdir /var/tmp

mkdir /tmp/packages && git clone https://github.com/stable-os/packages.git /tmp/packages
cd /tmp/packages

pkg-builder packages/$1/$1.toml /tmp/out

echo Created package, creating build repository

cd /

mkdir /build-repo && ostree --repo=/build-repo init --mode=bare-user

echo Created build repository, importing packages

# loop through all packages in the /tmp/out directory
for file in /tmp/out/*; do
  if [ -f "$file" ]; then
    stripped_file=$(basename $file .tar.gz)

    echo "==================================================="
    echo "Handling sub-package $stripped_file"
    echo "==================================================="

    # Check if there are less than 3 files in the package
    if [ $(tar -tvf $file | wc -l) -lt 3 ]; then
      echo "Package $file has less than 3 files"
      exit 1
    fi

    echo "==================================================="
    echo "Uploading sub-package $stripped_file"
    echo "==================================================="

    # Import the package
    ostree --repo=/build-repo commit -b stable-os/$(uname -m)/$stripped_file --tree=tar=$file

    # Export the package as OCI image and push to GitHub Container Registry
    /usr/bin/ostree-ext-cli container encapsulate --repo=/build-repo stable-os/$(uname -m)/$stripped_file docker://ghcr.io/stable-os/package-$stripped_file-$(uname -m)-builtonstableos:latest

    echo "==================================================="
    echo "Finished sub-package $stripped_file"
    echo "==================================================="
  fi
done

# ostree --repo=/build-repo commit -b stable-os/$(uname -m)/linux --tree=tar=/tmp/out.tar.gz

# echo Cleaning up to save disk space

# rm -rf /tmp
# mkdir /tmp

# echo Imported package, exporting as OCI image

# ostree-ext-cli container encapsulate --repo=/build-repo stable-os/$(uname -m)/linux docker://ghcr.io/stable-os/package-$1-$(uname -m)-builtonstableos:latest
