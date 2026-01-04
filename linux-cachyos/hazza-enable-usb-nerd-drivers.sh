#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-config}

set_sym_m() {
  local sym="$1"
  if grep -q "^${sym}=" "$CONF"; then
    sed -i "s/^${sym}=.*/${sym}=m/" "$CONF"
  elif grep -q "^# ${sym} is not set" "$CONF"; then
    sed -i "s/^# ${sym} is not set/${sym}=m/" "$CONF"
  else
    echo "${sym}=m" >> "$CONF"
  fi
}

set_sym_y() {
  local sym="$1"
  if grep -q "^${sym}=" "$CONF"; then
    sed -i "s/^${sym}=.*/${sym}=y/" "$CONF"
  elif grep -q "^# ${sym} is not set" "$CONF"; then
    sed -i "s/^# ${sym} is not set/${sym}=y/" "$CONF"
  else
    echo "${sym}=y" >> "$CONF"
  fi
}

# ------------- Hazza nerd pack -------------

# USB serial junk for dev boards & dongles
set_sym_m CONFIG_USB_ACM
set_sym_m CONFIG_USB_SERIAL
set_sym_m CONFIG_USB_SERIAL_FTDI_SIO
set_sym_m CONFIG_USB_SERIAL_CP210X
set_sym_m CONFIG_USB_SERIAL_CH341
set_sym_m CONFIG_USB_SERIAL_PL2303
set_sym_m CONFIG_USB_SERIAL_OPTION

# HID + macro toys
set_sym_y CONFIG_HIDRAW
set_sym_m CONFIG_UHID
set_sym_m CONFIG_INPUT_UINPUT
set_sym_m CONFIG_USB_HID
set_sym_m CONFIG_HID_GENERIC
set_sym_m CONFIG_HID_STEAM
set_sym_m CONFIG_HID_XPAD
set_sym_m CONFIG_JOYSTICK_XPAD

# VFIO stack for future PCI passthrough chaos
set_sym_m CONFIG_VFIO
set_sym_m CONFIG_VFIO_PCI
set_sym_m CONFIG_VFIO_IOMMU_TYPE1

echo "Updated $CONF with Hazza USB / HID / VFIO options."
