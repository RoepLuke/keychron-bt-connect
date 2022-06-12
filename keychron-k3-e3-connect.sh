#!/bin/bash

echo ""

# Check User
if [[ "$USER" != "root" ]]; then
  echo "Script must be executed as root or with sudo, exiting."
  exit 1
fi

# Variables
prefix='[Keychron Connect]'
unpriv_user="lroeper"
kernel_module_apple_hid_fnmode_check=$(cat /sys/module/hid_apple/parameters/fnmode)
usb_device_manufacturer="Keychron"
usb_device_manufacturer_check=$(lsusb -v -d 05ac: | grep -m 1 'iManufacturer' | awk '{print $3}')
bt_skip="false"
bt_device_mac="DC:2C:26:26:BF:F4"
bt_device_name="Keychron K3"
bt_device_found="false"

# Detect USB-Device
echo -n "$prefix Detecting if Keychron Device is connected via USB... "
if [[ "$usb_device_manufacturer_check" = "$usb_device_manufacturer" ]]; then
  echo "detected!"
  echo ""
  bt_skip="true"
else
  echo "not found!"
  echo ""
fi

# Detect & connect Bluetooth Device
echo -n "$prefix Detecting if Keychron Device is available for pairing via Bluetooth... "
if [[ "$bt_skip" = "true" ]]; then
  echo "skipped!"
  echo ""
else
  # check rfkill & unblock
  rfkill_id=$(rfkill list | grep -i "Bluetooth" | awk '{print $1}' | sed 's/://')
  soft_blocked=$(rfkill list | grep -i --after-context 2 "Bluetooth" | grep -i "soft blocked" | awk '{print $3}')
  hard_blocked=$(rfkill list | grep -i --after-context 2 "Bluetooth" | grep -i "hard blocked" | awk '{print $3}')
  if [[ "$soft_blocked" = "yes" ]]; then
    rfkill unblock $rfkill_id
  fi
  if [[ "$hard_blocked" = "yes" ]]; then
    echo "bluetooth could not be enabled (hard-blocked)."
    sleep 5s
    exit 2
  fi
  
  # Check if already paired and unpair
  check_paired_by_mac=$(sudo -u $unpriv_user bluetoothctl paired-devices | grep -m 1 "$bt_device_mac")
  check_paired_by_name=$(sudo -u $unpriv_user bluetoothctl paired-devices | grep -m 1 "$bt_device_name")
  if [[ "$check_paired_by_mac" != "" || "$check_paired_by_name" != "" ]]; then
    # found device paired, unpairing
    result=$(sudo -u $unpriv_user bluetoothctl remove $bt_device_mac | grep -i "Device has been removed")
    if [[ "$result" = "" ]]; then
      echo "is paired and could not be unpaired."
      sleep 5s
      exit 3
    fi
  fi
  
  # scan for devices for 10 seconds
  sudo -u $unpriv_user bluetoothctl --timeout 10 scan on 2>&1 1> /dev/null
  
  # check if device was found
  bt_device_found_via_mac=$(sudo -u $unpriv_user bluetoothctl devices | grep -m 1 $bt_device_mac)
  bt_device_found_via_name=$(sudo -u $unpriv_user bluetoothctl devices | grep -m 1 "$bt_device_name")
  if [[ "$bt_device_found_via_mac" != "" ]]; then
    bt_device_found="true"
  elif [[ "$bt_device_found_via_name" != "" ]]; then
    bt_device_mac=$(echo "$bt_device_found_via_name" | awk '{print $2}')
    bt_device_found="true"
  else
    echo "was not found when searching for pairable devices."
    sleep 5s
    exit 4
  fi
  
  # echo found info
  if [[ "$bt_device_found" = "true" ]]; then
    echo "device found and available!"
    echo ""
  else
    echo "device not found!"
    sleep 5s
    exit 4
  fi
  
  # pair & connect or exit
  echo -n "$prefix BT-Pairing with Device... "
  bt_pair_result=$(sudo -u $unpriv_user bluetoothctl pair "$bt_device_mac" | grep -i "Pairing successful")
  if [[ "$bt_pair_result" != "" ]]; then
    echo "success!"
    echo ""
  else 
    echo "failed!"
    echo ""
    bt_fail="true"
  fi
  sleep 1s
  echo -n "$prefix BT-Connecting with Device... "
  bt_conn_result=$(sudo -u $unpriv_user bluetoothctl connect "$bt_device_mac" | grep -i "Connection successful")
  if [[ "$bt_conn_result" != "" ]]; then
    echo "success!"
    echo ""
  else 
    echo "failed!"
    echo ""
    bt_fail="true"
  fi
  
  if [[ "$bt_fail" = "true" ]]; then
    echo "$prefix Trying to fix bluetooth problems... DEBUG below"
    echo ""
    echo "$prefix > blocking bluetooth adapter"
    rfkill block $rfkill_id
    sleep 1s
    echo ""
    echo "$prefix > disabling bluetooth adapter"
    sudo -u $unpriv_user bluetoothctl power off
    sleep 1s
    echo ""
    echo "$prefix > unblocking bluetooth adapter"
    rfkill unblock $rfkill_id
    sleep 1s
    echo ""
    echo "$prefix > enabling bluetooth adapter"
    sudo -u $unpriv_user bluetoothctl power on
    sleep 1s
    echo ""
    echo "$prefix > scanning for pairable bluetooth devices for 20sec"
    bluetoothctl --timeout 20 scan on
    sleep 1s
    echo ""
    echo "$prefix > trying to pair device"
    bluetoothctl pair "$bt_device_mac"
    sleep 1s
    echo ""
    echo "$prefix > trying to connect device"
    bluetoothctl connect "$bt_device_mac"
    sleep 5s
  fi
  
fi  

# Set FN-Key Behaviour
if [[ $kernel_module_apple_hid_fnmode_check -ne 2 ]]; then
  echo 2 > /sys/module/hid_apple/parameters/fnmode
fi

sleep 5s
echo "SUCCESS"
exit 0
