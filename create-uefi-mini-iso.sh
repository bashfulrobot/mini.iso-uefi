#!/bin/bash

# Path to project root
PROJROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Path to downloaded mini.iso
MINIISO="$PROJROOT/raw/mini.iso"

read -p "Does the $MINIISO file exist? If so, press [ENTER] to continue..."

# Build directory
BUILD="$PROJROOT/usbdisk"

# New ISO Name(s)
IMAGE_NAME="Ubuntu Mini UEFI"
IMAGE=mini-uefi.iso

#### Binaries

# Making things portable
ECHO="$(which echo)"
PRINTF="$(which printf)"
DPKGQUERY="$(which dpkg-query)"
GREP="$(which grep)"
APT="$(which apt)"

#### Colours

BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

main() {
  extractISO && writeISO
}

echoHeader() {
  $ECHO ""
  $PRINTF "%s \n" "$BLUE === $1 $NC"
  $ECHO ""
}

echoSubheader() {
  $ECHO ""
  $PRINTF "%s \n" "$CYAN - $1 ... $NC"
  $ECHO ""
}

echoCompledNtfy() {
  $ECHO ""
  $PRINTF "%s \n" "$GREEN $1 Completed. $NC"
  $ECHO ""
}

install-tools() {

  # Packges to install
  declare -a APTPKGS
  APTPKGS=(p7zip-full p7zip-rar xorriso isolinux)

  echoHeader "Checking SW Dependencies"
  # Don't need to loop an array, just making pretty output.
  for i in "${APTPKGS[@]}"; do

    # For each array item, check if it is installed, and install if needed.
    if [ $($DPKGQUERY -W -f='${Status}' $i 2>/dev/null | $GREP -c "ok installed") -eq 0 ]; then
      echoSubheader "Installing $i package"
      sudo $APT install $i -y
    fi

  done
  echoCompledNtfy "SW Dependencies"

  echoHeader "Cleanup Install"
  sudo $APT install -f -y
  sudo $APT autoremove -y
  echoCompledNtfy "Installation Cleanup"

}

extractISO() {
  $SEVENZ x -ousbdisk $MINIISO
  $SEVENZ x -ousbdisk $PROJROOT/usbdisk/boot/grub/efi.img
}

writeISO() {
    cd $BUILD
    # Write the installer back to an ISO
xorriso -as mkisofs \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c boot.cat \
  -b isolinux.bin \
  -V "$IMAGE_NAME" \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o ../$IMAGE \
  $BUILD/.
}

#### Run it all.

# Go to project root
cd $PROJROOT

# Installing needed packages
install-tools

# Chicken and egg. Make installed binaries portable
SEVENZ="$(which 7z)"

# go!
main

exit 0
