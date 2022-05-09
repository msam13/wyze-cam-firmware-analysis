# Wyze Cam Firmware Analysis

##Initial analysis

> binwalk demo_wcv3.bin

```
image name: "jz_fw"
image type: Firmware Image
OS: Linux
CPU: MIPS

image name: "Linux-3.10.14__isvp_swan_1.0__"
image type: OS Kernel Image
OS: Linux 
CPU: MIPS

Squashfs filesystem 1 : little endian, version 4.0, compression:xz, size: 3853788 bytes, 384 inodes, blocksize: 131072 bytes

Squashfs filesystem2 :  little endian, version 4.0, compression:xz, size: 3815722 bytes, 194 inodes, blocksize: 131072 bytes, created: 2022-02-17 02:13:24
```

> file demo_wcv3.bin
```
demo_wcv3.bin: u-boot legacy uImage, jz_fw, Linux/MIPS, Firmware Image (Not compressed), 9846784 bytes, Thu Feb 17 02:13:24 2022, Load Address: 0x00000000, Entry Point: 0x00000000, Header CRC: 0x75A4CF47, Data CRC: 0x1B15405A
```

> Steps to mount squash file sytem 1
```
dd if=demo_wcv3.bin skip=2031680 count=35788480 of=filesys iflag=skip_bytes,count_bytes
sudo mount filsys .
```

Running Trommel on the mounted filesytem directory 1
>python trommel.py -p /home/esslp/wyze-cam-firmware-analysis/demo_wcv3_4.36.8.32 -o /home/esslp/Desktop/firmwarefinding

output file of the command is filesystem  is 'image 1_TROMMEL_20220503_202956'


Running firwalker on the mounted file system directory 1
> ./firmwalker.sh /home/esslp/wyze-cam-firmware-analysis/wyme_unzip  /home/esslp/Desktop/filesys

output file for the command is 'filesystem image 2_FIRMWALKER_ouput.txt'

#### etc/shadow 

shadow is the most interesting file, as it has the has of the root user's password. The hashing used is salted SHA-512. For understanding Hash check [here](https://www.cyberciti.biz/faq/understanding-etcshadow-file/. 
)

```
$6$wyzecamv3$8gyTEsAkm1d7wh12Eup5MMcxQwuA1n1FsRtQLUW8dZGo1b1pGRJgtSieTI02VPeFP9f4DodbIt2ePOLzwP0WI

```


file system has been mounted as read-only. Small trick using sasquatch has to be done to make it read and writeable. 

```
$ sasquatch /home/esslp/wyze-cam-firmware-analysis/demo_wcv3_4.36.8.32/filesys
$ sudo chmod 777 shadow
```

now that we can edit the shadow file. 

```
$ perl -e 'print crypt("esslp","\$6\$wyzecamv3\$")."\n"'

$6$wyzecamv3$Jgd8pQHFFZxPg5C.a1hN17sKDeU4aIBc8IpNhPk/iCFsNcvogroptl66jPO0au4IK2NRqxvQvHFqgzlCA6hty1

```

##  Repacking the firmware

#### blob of bootloder, firmware and OS
> dd if=demo_wcv3.bin skip=0 count=2031680 of=img iflag=skip_bytes,count_bytes


#### blob of file system 1
> mksquashfs /home/esslp/workspace/embedtools/squashfs-root /home/esslp/wyze-cam-firmware-analysis/firmware_recreate/filesys1.sqsh -comp xz -b 131072
#### blob of file system 2
>dd if=demo_wcv3.bin skip=602937 of=fs2 iflag=skip_bytes

####All together
> cat img filesys1.sqsh filesys2 > image

