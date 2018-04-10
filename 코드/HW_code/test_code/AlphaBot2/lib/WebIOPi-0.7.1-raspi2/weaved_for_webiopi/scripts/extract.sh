#!/bin/bash
echo "Extracting Weaved Software into `pwd`"
# searches for the line number where finish the script and start the tar.gz
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`
#remember our file name
THIS=`pwd`/$0
# take the tarfile and pipe it into tar
tail -n +$SKIP $THIS | tar -xz
# Any script here will happen after the tar file extract.
echo "Finished extracting"
cd ./weaved_for_webiopi
./installer.sh
exit 0
# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__
