#!/bin/bash -e
# Run this script without any arguments for a dry run
# Run the script with root and with the argument exec to really remove
# the list of old kernels and modules printed in the dry run
# authors: alex Burdusel and @eitch on https://askubuntu.com/a/1409370/34298

uname -a
IN_USE=$(uname -a | awk '{ print $3 }')
echo "Your in use kernel is $IN_USE"

OLD_KERNELS=$(
    dpkg --get-selections |
        grep -v "linux-headers-generic" |
        grep -v "linux-image-generic" |
        grep -v "linux-image-generic" |
        grep -v "${IN_USE%%-generic}" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $1 }'
)
echo "Old Kernels to be removed:"
echo "$OLD_KERNELS"

OLD_MODULES=$(
    ls /lib/modules |
    grep -v "${IN_USE%%-generic}" |
    grep -v "${IN_USE}"
)
echo "Old Modules to be removed:"
echo "$OLD_MODULES"

if [ "$1" == "exec" ]; then
  apt-get purge $OLD_KERNELS
  for module in $OLD_MODULES ; do
    rm -rf /lib/modules/$module/
  done
else
    echo "If all looks good, run it again like this: sudo $0 exec"
fi
