#!/bin/sh

# This is a config file repair script [start part].
# Create by ChenX 2021-07-01 @hualaikeji.

echo "(O _ o) welcome to the config file repair script [start part]!"

CONFIG_FILE=/configs/.product_config

to_exit()
{
	sync
	sync
	echo "(- _ -) i will exit!"
	exit
}

umount_and_exit()
{
	sync
	sync
	echo "(- _ -) to umount kback..."
	umount /mnt/
	sync
	sync
	echo "(- _ -) i will exit!"
	exit
}

try_mount_kback_to_mnt()
{
	echo "(O _ o) to mount kback..."
	mount /dev/mtdblock4 /mnt/

	RESULT=$?
	if [ $RESULT -eq 0 ];then
		echo "(^ _ ^) kback mount ok!"
	else
		echo "(T _ T) kback can not mount! result:[$RESULT] retry..."

		# format the kback partition and try mount again
		echo "(O _ o) to format kback..."
		mkfs.vfat /dev/mtdblock4
		echo "(O _ o) to mount kback..."
		mount /dev/mtdblock4 /mnt/

		RESULT=$?
		if [ $RESULT -eq 0 ];then
			echo "(^ _ ^) kback mount ok!"
		else
			echo "(T _ T) kback can not mount! result:[$RESULT] exit..."
			umount_and_exit
		fi
	fi
}

try_format_kback_and_remount()
{
	sync
	sync
	echo "(O _ o) to umount kback..."
	umount /mnt/
	echo "(O _ o) to format kback..."
	mkfs.vfat /dev/mtdblock4
	echo "(O _ o) to mount kback..."
	mount /dev/mtdblock4 /mnt/

	RESULT=$?
	if [ $RESULT -eq 0 ];then
		echo "(^ _ ^) kback mount ok!"
		return 0
	else
		echo "(T _ T) kback can not mount! result:[$RESULT]"
		return 1
	fi
}

check_md5_file()
{
	FILE_NAME=$1

	REAL_MD5=`md5sum $FILE_NAME`
	REAL_MD5=`echo ${REAL_MD5%% *}`

	if [ "$2" = "" ];then
		RECORD_MD5=`echo ${FILE_NAME%.*}`
		RECORD_MD5=`echo ${RECORD_MD5##*.}`
	else
		RECORD_MD5=$2
	fi

	echo "(O _ o)  real  md5 is [$REAL_MD5]"
	echo "(O _ o) record md5 is [$RECORD_MD5]"

	if [ "$REAL_MD5" = "$RECORD_MD5" ];then
		echo "(^ _ ^) check md5 file [$FILE_NAME] is ok!"
		return 0
	else
		echo "(T _ T) check md5 file [$FILE_NAME] failed!"
		return 1
	fi
}

set_read_only()
{
	SET_FILE=$1
	if [ -w $SET_FILE ];then
		echo "(O _ o) set [$SET_FILE] to read-only!"
		chmod 004 $SET_FILE
		sync
		sync
	fi
}

copy_config_file_to_kback()
{
	CFG_GET_NEW_MD5=`md5sum $CONFIG_FILE`
	CFG_REAL_NEW_MD5=`echo ${CFG_GET_NEW_MD5%% *}`
	RECORD_NAME="/mnt/MD5."$CFG_REAL_NEW_MD5".config"

	rm -f "/mnt/MD5.*"
	sync
	sync
	cp -fa $CONFIG_FILE $RECORD_NAME
	sync
	sync

	# re-mount the kback and re-copy
	if [ ! -f $RECORD_NAME ];then
		echo "(T _ T) the md5 file copy fail! try remount..."
		try_format_kback_and_remount
		if [ $? -ne 0 ];then
			umount_and_exit
		fi
	fi

	rm -f "/mnt/MD5.*"
	sync
	sync
	cp -fa $CONFIG_FILE $RECORD_NAME
	sync
	sync

	if [ ! -f $RECORD_NAME ];then
		echo "(T _ T) the md5 file copy fail!"
		umount_and_exit
	fi

	check_md5_file $RECORD_NAME
	if [ $? -eq 0 ];then
		echo "(^ _ ^) the md5 file copy ok!"
		umount_and_exit
	else
		echo "(T _ T) the md5 file copy fail, try again!"
		rm -f "/mnt/MD5.*"
		sync
		sync
		cp -fa $CONFIG_FILE $RECORD_NAME
		sync
		sync
		
		# re-mount the kback and re-copy
		if [ ! -f $RECORD_NAME ];then
			echo "(T _ T) the md5 file copy fail! try remount..."
			try_format_kback_and_remount
			if [ $? -ne 0 ];then
				umount_and_exit
			fi
		fi

		rm -f "/mnt/MD5.*"
		sync
		sync
		cp -fa $CONFIG_FILE $RECORD_NAME
		sync
		sync

		if [ ! -f $RECORD_NAME ];then
			echo "(T _ T) the md5 file copy fail!"
			umount_and_exit
		fi
	
		check_md5_file $RECORD_NAME
		if [ $? -eq 0 ];then
			echo "(^ _ ^) the md5 file copy ok!"
			umount_and_exit
		else
			echo "(T _ T) the md5 file copy fail!"
			rm -f "/mnt/MD5.*"
			umount_and_exit
		fi
	fi
}

copy_config_md5_file_to_config()
{
	echo "(O _ o) to copy /configs md5 file to /configs!"
	sync
	sync

	CFG_MD5_FILE=`find /configs/MD5.*.config`
	if [ $? -ne 0 ];then
		echo "(T _ T) not found the md5 file in /configs!"
		umount_and_exit
	fi
	echo "(O _ o) found the md5 file in /configs! [$CFG_MD5_FILE]"

	check_md5_file $CFG_MD5_FILE
	if [ $? -ne 0 ];then
		echo "(T _ T) the md5 file in /configs is fail!"
		umount_and_exit
	fi
	echo "(^ _ ^) the md5 file in /configs is ok!"

	# copy /configs md5 file to kback
	rm -f "/mnt/MD5.*"
	sync
	sync
	cp -fa $CFG_MD5_FILE /mnt
	sync
	sync

	# create the /mnt md5 file name
	MD5_FILE_NAME=`echo ${CFG_MD5_FILE##*/}`
	MNT_FILE_NAME="/mnt/"$MD5_FILE_NAME

	if [ -f $MNT_FILE_NAME ];then
		check_md5_file $MNT_FILE_NAME
		if [ $? -eq 0 ];then
			echo "(^ _ ^) the configs md5 file copy to kback ok!"
		else
			echo "(T _ T) the configs md5 file copy to kback fail! md5 error!"
			# format + remount
			try_format_kback_and_remount
			if [ $? -eq 0 ];then
				# retry: copy /configs md5 file to kback
				rm -f "/mnt/MD5.*"
				sync
				sync
				cp -fa $CFG_MD5_FILE /mnt
				sync
				sync
				echo "(O _ o) retry copy the configs md5 file to kback!"
				# without check again...
			fi
		fi
	else
		echo "(T _ T) the configs md5 file copy to kback fail! no file!"
		# format + remount
		try_format_kback_and_remount
		if [ $? -eq 0 ];then
			# retry: copy /configs md5 file to kback
			rm -f "/mnt/MD5.*"
			sync
			sync
			cp -fa $CFG_MD5_FILE /mnt
			sync
			sync
			echo "(O _ o) retry copy the configs md5 file to kback!"
			# without check again...
		fi
	fi

	# copy /configs md5 file to /configs
	rm -f $CONFIG_FILE
	sync
	sync
	cp -fa $CFG_MD5_FILE $CONFIG_FILE
	sync
	sync

	if [ ! -f $CONFIG_FILE ];then
		echo "(T _ T) the new config file copy fail, try again!"
		rm -f $CONFIG_FILE
		sync
		sync
		cp -fa $CFG_MD5_FILE $CONFIG_FILE
		sync
		sync
		
		if [ ! -f $CONFIG_FILE ];then
			echo "(T _ T) the new config file copy fail!"
			umount_and_exit
		fi
	fi

	# check new config file copy ok
	RECORD_MD5=`echo ${CFG_MD5_FILE%.*}`
	RECORD_MD5=`echo ${RECORD_MD5##*.}`

	check_md5_file $CONFIG_FILE $RECORD_MD5
	if [ $? -eq 0 ];then
		echo "(^ _ ^) the new config file copy ok!"
		# check the file permissions
		set_read_only $CONFIG_FILE
		umount_and_exit
	else
		echo "(T _ T) the new config file copy fail, try again!"
		rm -f $CONFIG_FILE
		sync
		sync
		cp -fa $CFG_MD5_FILE $CONFIG_FILE
		sync
		sync

		if [ ! -f $CONFIG_FILE ];then
			echo "(T _ T) the new config file copy fail, try again!"
			rm -f $CONFIG_FILE
			sync
			sync
			cp -fa $CFG_MD5_FILE $CONFIG_FILE
			sync
			sync
			
			if [ ! -f $CONFIG_FILE ];then
				echo "(T _ T) the new config file copy fail!"
				umount_and_exit
			fi
		fi

		check_md5_file $CONFIG_FILE $RECORD_MD5
		if [ $? -eq 0 ];then
			echo "(^ _ ^) the new config file copy ok!"
			# check the file permissions
			set_read_only $CONFIG_FILE
			umount_and_exit
		else
			echo "(T _ T) the new config file copy fail!"
			umount_and_exit
		fi
	fi
}

missing_config_file_handler()
{
	echo "(O _ o) into missing config file handler!"
	sync
	sync	

	# try mount the kback partition
	try_mount_kback_to_mnt
	
	# check if the md5 file exists in the kback partition 
	MD5_FILE=`find /mnt/MD5.*.config`
	if [ $? -ne 0 ];then
		echo "(O _ o) not found the md5 file in kback!"
		copy_config_md5_file_to_config
	fi
	echo "(O _ o) found the md5 file in kback! [$MD5_FILE]"

	# check kback md5 file not bad
	check_md5_file $MD5_FILE
	if [ $? -ne 0 ];then
		echo "(T _ T) the md5 file in kback is bad!"
		copy_config_md5_file_to_config
	fi
	echo "(^ _ ^) the md5 file in kback is ok!"

	# copy md5 file to configs
	rm -f $CONFIG_FILE
	sync
	sync
	cp -fa $MD5_FILE $CONFIG_FILE
	sync
	sync

	# try re-copy
	if [ ! -f $CONFIG_FILE ];then
		echo "(T _ T) the new config file copy fail, try again!"
		rm -f $CONFIG_FILE
		sync
		sync
		cp -fa $MD5_FILE $CONFIG_FILE
		sync
		sync
		
		if [ ! -f $CONFIG_FILE ];then
			copy_config_md5_file_to_config
		fi
	fi
	
	# check new config file copy ok
	RECORD_MD5=`echo ${MD5_FILE%.*}`
	RECORD_MD5=`echo ${RECORD_MD5##*.}`

	check_md5_file $CONFIG_FILE $RECORD_MD5
	if [ $? -eq 0 ];then
		echo "(^ _ ^) the new config file copy ok!"
		set_read_only $CONFIG_FILE
		umount_and_exit
	fi

	echo "(T _ T) the new config file copy fail, try again!"
	rm -f $CONFIG_FILE
	sync
	sync
	cp -fa $MD5_FILE $CONFIG_FILE
	sync
	sync

	# try re-copy
	if [ ! -f $CONFIG_FILE ];then
		echo "(T _ T) the new config file copy fail, try again!"
		rm -f $CONFIG_FILE
		sync
		sync
		cp -fa $MD5_FILE $CONFIG_FILE
		sync
		sync
		
		if [ ! -f $CONFIG_FILE ];then
			copy_config_md5_file_to_config
		fi
	fi

	# check new config file copy ok
	check_md5_file $CONFIG_FILE $RECORD_MD5
	if [ $? -eq 0 ];then
		echo "(^ _ ^) the new config file copy ok!"
		set_read_only $CONFIG_FILE
		umount_and_exit
	else
		echo "(T _ T) the new config file copy fail!"
		copy_config_md5_file_to_config
	fi
}

invalid_mac_address_handler()
{
	echo "(O _ o) this is invalid mac! not finish factory test..."
	to_exit
}

valid_mac_address_handler()
{
	echo "(O _ o) this is valid mac!"
	sync
	sync
	
	# check the file permissions
	set_read_only $CONFIG_FILE

	# try mount the kback partition
	try_mount_kback_to_mnt

	# check if the md5 file exists in the kback partition 
	MD5_FILE=`find /mnt/MD5.*.config`
	if [ $? -eq 0 ];then
		echo "(O _ o) found the md5 file in kback! [$MD5_FILE]"

		# check kback md5 file not bad
		check_md5_file $MD5_FILE
		if [ $? -eq 0 ];then
			echo "(^ _ ^) the md5 file in kback is ok!"
			sync
			sync
			umount_and_exit
		else
			echo "(T _ T) the md5 file in kback is bad!"
			rm -f "/mnt/MD5.*"
			sync
			sync
		fi
	else
		echo "(O _ o) not found the md5 file in kback!"
	fi

	# copy the md5 file into the kback partition
	CFG_MD5_FILE=`find /configs/MD5.*.config`
	if [ $? -eq 0 ];then
		echo "(O _ o) found the md5 file in /configs! [$CFG_MD5_FILE]"

		# check configs md5 file not bad
		check_md5_file $CFG_MD5_FILE
		if [ $? -eq 0 ];then
			echo "(^ _ ^) the md5 file in /configs is ok!"

			cp -fa $CFG_MD5_FILE /mnt/
			sync
			sync

			# create the /mnt md5 file name
			MD5_FILE_NAME=`echo ${CFG_MD5_FILE##*/}`
			MNT_FILE_NAME="/mnt/"$MD5_FILE_NAME
			
			if [ -f $MNT_FILE_NAME ];then
				check_md5_file $MNT_FILE_NAME
				if [ $? -eq 0 ];then
					echo "(^ _ ^) the md5 file copy ok!"
					umount_and_exit
				else
					echo "(T _ T) the md5 file copy fail! md5 error!"
					copy_config_file_to_kback
				fi
			else
				echo "(T _ T) the md5 file copy fail! no file!"
				copy_config_file_to_kback
			fi
		else
			echo "(T _ T) the md5 file in configs is bad!"
			rm -f "/configs/MD5.*.config"
			sync
			sync
			copy_config_file_to_kback
		fi
	else
		echo "(O _ o) not found the md5 file in /configs, to copy config file!"
		copy_config_file_to_kback
	fi
}

# check the config file is complete
if [ ! -f $CONFIG_FILE ];then
	missing_config_file_handler
fi

if [ ! -r $CONFIG_FILE ];then
	missing_config_file_handler
fi

CONFIG_FILE_LEN=`ls -l $CONFIG_FILE | awk '{ print $5 }'`

if [ $CONFIG_FILE_LEN -eq 0 ];then
	missing_config_file_handler
fi

# check the mac address in the config file
CONFIG_INFO_LINE=`cat $CONFIG_FILE | grep 'CONFIG_INFO='`
CONFIG_INFO_LINE_LEN=`echo ${#CONFIG_INFO_LINE}`

if [ $CONFIG_INFO_LINE_LEN -lt 24 ];then
	echo "(T _ T) len of CONFIG_INFO is less than 24 (is $CONFIG_INFO_LINE_LEN)"
	missing_config_file_handler
fi

MAC=`echo ${CONFIG_INFO_LINE%%|*}`
MAC=`echo ${MAC#*=}`

if [ "$MAC" = "080808080808" ];then
	invalid_mac_address_handler
else
	valid_mac_address_handler
fi

umount_and_exit
