#! /bin/sh


rewrite_config_value()
{
    file=$1
    key=$2
    newvalue=$3
    if [ -f $file ]; then
        sed -i "s/$key=.*/$key=$newvalue/g" $file
    fi
}

cp -rf /system/bin/wpa.conf /tmp/wpa.conf

wpaconf_file=/tmp/wpa.conf
wifissid=$(cat /configs/.wifissid)
wifipasswd=$(cat /configs/.wifipasswd)

rewrite_config_value $wpaconf_file  ssid  "\"$wifissid\""
rewrite_config_value $wpaconf_file  psk  "\"$wifipasswd\""
rewrite_config_value $wpaconf_file  scan_ssid  1

ifconfig wlan0 up
wpa_supplicant -D nl80211 -iwlan0 -c /tmp/wpa.conf -B &
sleep 3
udhcpc -i wlan0

