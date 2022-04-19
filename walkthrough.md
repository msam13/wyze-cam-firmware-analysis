# Wyze Cam Firmware Analysis

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