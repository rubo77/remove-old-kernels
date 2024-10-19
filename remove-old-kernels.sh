#!/usr/bin/env bash

# -o pipefail = set exit code of a sequence of piped commands to an error if any of them errored
# -e          = exit on first error
set -eo pipefail

_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

RED='\033[0;31m'
URED='\033[4;31m' # underlined
NC='\033[0m' # No Color

#--------------------------------------------------------------------------------
# Current Kernel Info & Scary Warning
#--------------------------------------------------------------------------------

echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo -e "║ WARNING: ${RED}Reboot${NC} after installing a new kernel and ${URED}before${NC} running this script! ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"

echo
echo "─current───────────────────────────────────"
echo
echo "Full system info:"
echo "  $(uname -a)"

IN_USE=$(uname -a | awk '{ print $3 }')
echo
echo "Your in use kernel is version:"
echo "  $IN_USE"

#--------------------------------------------------------------------------------
# Get Lists of Old Kernel Packages & Modules
#--------------------------------------------------------------------------------

echo
echo "─old───────────────────────────────────"

# Want to give feedback for null case if this fails so unset exit-on-error for a sec.
set +e
OLD_KERNELS=$(
    dpkg --get-selections |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        grep -v "linux-headers-generic" |
        grep -v "linux-image-generic" |
        grep -v "linux-image-amd64" |
        grep -v "linux-image-arm64" |
        grep -v "${IN_USE%%-generic}" |
        awk '{ print $1 }'
)
declare -i EXIT_CODE=$?
set -e

echo
echo "Old kernels to be removed:"
if [[ $EXIT_CODE -ne 0 ]]; then
    if [[ ! -z "$OLD_KERNELS" ]]; then
        echo "ERROR finding kernels?"
        exit $EXIT_CODE
    else
        NO_KERNEL_ACTION="true"
        echo "  - None."
    fi
else
    for PACKAGE in $OLD_KERNELS; do
        echo "  - $PACKAGE"
    done
fi

# Same null feedback thing.
set +e
OLD_MODULES=$(
    ls /lib/modules |
        grep -v "${IN_USE%%-generic}" |
        grep -v "${IN_USE}"
)
EXIT_CODE=$?
set -e

echo
echo "Old modules to be removed:"

if [[ $EXIT_CODE -ne 0 ]]; then
    if [[ ! -z "$OLD_MODULES" ]]; then
        echo "ERROR finding modules?"
        exit $EXIT_CODE
    else
        NO_MODULE_ACTION="true"
        echo "  - None."
    fi
else
    for MODULE in $OLD_KERNELS; do
        echo "  - $MODULE"
    done
fi

#--------------------------------------------------------------------------------
# Execute or Dry Run?
#--------------------------------------------------------------------------------

if [ "$1" == "exec" ]; then
    echo
    echo "─rm─kernel─packages─────────────────────"
    if [[ -z "$OLD_KERNELS" ]]; then
        echo "  No old kernels; nothing to remove."
    else
        set -x
        apt-get purge $OLD_KERNELS
        # Unset cmd echo flag without echoing the unsetting of said flag.
        {
            set +x
        } 2>/dev/null
    fi

    echo
    echo "─rm─kernel─modules──────────────────────"
    if [[ -z "$OLD_MODULES" ]]; then
        echo "  No old modules; nothing to remove."
    else
        for module in $OLD_MODULES ; do
            set -x
            rm -rf /lib/modules/$module/
            {
                set +x
            } 2>/dev/null
        done
    fi
else
    echo
    echo "─dry─run─complete───────────────────────"
    echo
    echo "If all looks good, run it again like this:"
    echo "  sudo $0 exec"
fi
