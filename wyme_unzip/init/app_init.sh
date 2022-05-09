#!/bin/sh
mkdaemon() {
    # dmon options
    #   --stderr-redir  Redirects stderr to the log file as well
    #   --max-respawns  Sets the number of times dmon will restart a failed process
    #   --environ       Sets an environment variable. Used to remove buffering on stdout
    #
    # dslog options
    #   --priority      The syslog priority. Set to DEBUG as these are just the stdout of the 
    #   --max-files     The number of logs that will exist at once
    #
    max_respawns=$1
    shift
    daemon_name=$1
    shift
    dmon \
      --stderr-redir \
      --max-respawns $max_respawns \
      --environ "LD_PRELOAD=libsetunbuf.so" \
      $@ \
      -- dslog \
        --priority DEBUG \
        --facility USER \
        $daemon_name
}
############# Setting register and insert wifi ko ############
insmod /system/driver/tx-isp-t31.ko isp_clk=220000000
insmod /system/driver/exfat.ko
insmod /system/driver/audio.ko spk_gpio=-1 alc_mode=0 mic_gain=0
#insmod /system/driver/avpu.ko
insmod /system/driver/sinfo.ko
insmod /system/driver/mmc_detect_test.ko
insmod /system/driver/sample_pwm_core.ko
insmod /system/driver/sample_pwm_hal.ko
insmod /system/driver/speaker_ctl.ko
insmod /system/driver/ch34x.ko

ubootddr=`sed -n '30p' /proc/jz/clock/clocks | cut -d ' ' -f 7`

if [[ "540.000MHz" == $ubootddr ]]; then
   echo "#############ubootddr = $ubootddr ########"
   insmod /system/driver/avpu.ko clk_name='mpll' avpu_clk=540000000
else
   echo "#############ubootddr = $ubootddr ########"
   insmod /system/driver/avpu.ko
fi

cp /system/driver/*.txt /tmp/
sync

echo "################## to wait wifi vendor id ####################"

# Insert wifi driver...
while [ ! -f /sys/bus/mmc/devices/mmc1\:0001/mmc1\:0001\:1/vendor ]; do
	sleep 0.1
done

WifiVendorId=`cat /sys/bus/mmc/devices/mmc1\:0001/mmc1\:0001\:1/vendor`

if [[ "0x024c" == $WifiVendorId ]]; then
	echo "################## [vendor:$WifiVendorId] rtl8189ftv wifi #################"
	insmod /system/driver/rtl8189ftv.ko
elif [[ "0x007a" == $WifiVendorId ]]; then
	echo "################## [vendor:$WifiVendorId] atbm603x wifi ###################"
	insmod /system/driver/atbm603x_wifi_sdio.ko
elif [[ "0x5653" == $WifiVendorId ]]; then
	echo "################## [vendor:$WifiVendorId] ssv6x5x wifi ####################"
	insmod /system/driver/ssv6x5x.ko stacfgpath=/system/driver/ssv6x5x-wifi.cfg
elif [[ "0x424c" == $WifiVendorId ]]; then
	echo "################## [vendor:$WifiVendorId] bl_fdrv wifi ####################"
	insmod /system/driver/bl_fdrv.ko
else
	echo "################## [vendor:$WifiVendorId] unknown wifi ####################"
fi

# Unknown, Don't change!
devmem 0x10011110 32 0x6e094800
# Clear the drive capability setting for PB04 (minimum drive capability)
devmem 0x10011138 32 0x300
# Set the drive capability of PB04
devmem 0x10011134 32 0x200

############ This is a config file repair script ###########
sh /system/init/config_repair.sh

############ make resolv.conf file for ntp service ###########
touch /tmp/resolv.conf

OLD_USR_CONFIG_FILE='/configs/.parameters'
NEW_USR_CONFIG_FILE='/configs/.user_config'

if [ -e $OLD_USR_CONFIG_FILE ]; then
	mv $OLD_USR_CONFIG_FILE $NEW_USR_CONFIG_FILE -f
	rm $OLD_USR_CONFIG_FILE -f
fi

############ update time to time firmware was built at ###########
FIRMWARE_BUILD_TIME_FILE='/system/init/firmware_build_epoch_time.txt'
if [ -e $FIRMWARE_BUILD_TIME_FILE ]; then
	CURRENT_EPOCH_TIME=$(date +%s)
	FIRMWARE_BUILD_EPOCH_TIME=$(cat $FIRMWARE_BUILD_TIME_FILE)
	FIRMWARE_BUILD_MINUS_ONE_DAY_EPOCH_TIME=$(($FIRMWARE_BUILD_EPOCH_TIME-86400))
	# If "current time" < ("firmware build time" - "one day")
	# Then update time to "firmware build time"
	if [ "$CURRENT_EPOCH_TIME" -lt "$FIRMWARE_BUILD_MINUS_ONE_DAY_EPOCH_TIME" ]; then
		echo "Updating device time to:"
		date -s "@$FIRMWARE_BUILD_EPOCH_TIME"
	fi
fi

#################### Run app process (1) #####################
#telnetd &
/system/bin/ver-comp

############### Select user mode or debug mode ###############
DEBUG_STATUS='/configs/.debug_flag'

if [ ! -f $DEBUG_STATUS ]; then
	echo "#######################"
	echo "#   IS USER PROCESS   #"
	echo "#######################"
	/system/init/factory.sh &
	/system/bin/factorycheck

	if [ -f /tmp/factory ]; then
		exit
	fi

    export DUMPLOAD_CORES_DIR=/media/mmc/cores
    # Allow all processes spawned from init to create core dumps
    ulimit -c unlimited
    # Invoke ucoredmp_collector.sh on a core dump
    sysctl -w kernel.core_pattern="|/system/bin/ucoredmp_collector.sh --pid %p --signal %s --name %e --time %t --output-dir $DUMPLOAD_CORES_DIR"
    # Only process up to 1 core dump at a time.
    # If a second core dump occurs, while this is being processed it will be logged
    # to the kernels log but not processed
    sysctl -w kernel.core_pipe_limit=1
    # Enable the collection of the first page of each ELF (for build-id collection)
    # Applying to self process should be inherited by all child processes
    echo 0x33 > /proc/self/coredump_filter

    # Increase the size of the number of datagrams that can be queue in 1 socket.
    # The default value (10) was causing syslog() to silently drop log messages.
    # 128 was picked randomly as it seemed large enough to never fill up but not too
    # large to use all RAM.
    # Note: 128 is the maximum about of packets that could be stored in the queue,
    #       but those packets are allocated on demand, not statically at the creation
    #       of the queue
    sysctl -w net.unix.max_dgram_qlen=128

    mkdaemon 20 syslogd /sbin/syslogd -C2048 -n -S
    #waiting syslog running
    while [ true ]; do
        pidof syslogd > /dev/null
        if [ $? -eq 0 ]; then
            break;
        fi
    done
    mkdaemon 20 assis /system/bin/assis
    #/system/bin/assis > /dev/null 2>&1 &
    #while [ true ]; do                             
    #    pidof assis > /dev/null                  
    #    if [ $? -eq 0 ]; then                    
    #        break;                               
    #    fi                                       
    #done 
    mkdaemon 20 hl_client /system/bin/hl_client
    mkdaemon 20 sinker /system/bin/sinker
    mkdaemon 0 iCamera /system/bin/iCamera
    mkdaemon 20 dumpload /system/bin/dumpload
    mkdaemon -1 timesync /system/bin/timesync
    mkdaemon 0 audiocardprocess /system/bin/audiocardprocess

	#/system/bin/assis &
	#/system/bin/hl_client &
	#/system/bin/sinker &
	#/system/bin/iCamera &
else
	sleep 0.5
	echo "#######################"
	echo "#   IS DEBUG STATUS   #"
	echo "#######################"
fi
