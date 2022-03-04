#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#disable swap
echo "..Disabling swap"
echo "**********************************************" >>../prereq.log
echo "***               Disable swap             ***" >>../prereq.log
echo "**********************************************" >>../prereq.log

if ! $(grep -q "#/swap.img" "/etc/fstab"); then
echo "...Disable swap for current session"
$(swapoff -a)
echo "...Disable mounting swap in fstab"
$(sed -i 's+/swap.img+#/swap.img+g' /etc/fstab)
else
echo "...Swap already disabled"
fi

echo "" >>../prereq.log
echo "" >>../prereq.log
