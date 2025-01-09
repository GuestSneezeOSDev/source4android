# Source4android
> [!CAUTION]
> Please do not use this as its not complete yet, please proceed with caution.

Source4Android is an open-source, base mod for Half-Life 2 which allows players to port their mods to Android and Android-based systems without using any leaked code.

# How to build.
Firstly, you will need to install build dependencies[[1]](https://developer.valvesoftware.com/wiki/Source_SDK_2013#Step_One:_Getting_the_basic_C/C++_development_tools), here are the required packages.
- If you're on Arch Linux or any pacman-based run
```bash
sudo pacman -S base-devel gcc dpkg
```
- If you're on Debian or any APT-Based distro run
```bash
sudo apt-get install gcc-multilib g++-multilib # For x86_64
sudo apt-get install build-essential # For x86/i386
```
Download the Steam Client Runtime and copy the files from this repo to there.
<br>
Now you will need to run the `buildandroid.sh` file located in `src/` directory.
```bash
cd source4android/src/
./buildandroid.sh
```
Now build the makefile
```bash
make -f [MAKEFILE].mak
```

# Mods using Source4Android
- HL2 ReCharged → https://www.moddb.com/mods/half-life-2-overcharged-redux
- HL2 Rebuild → https://www.moddb.com/mods/half-life-2-rebuild1

# Troubleshooting
if you get this output:
```bash
creating: source4android-main/src/thirdparty/libiconv-1.15/m4/
  inflating: source4android-main/src/thirdparty/libiconv-1.15/m4/cp.m4
  inflating: source4android-main/src/thirdparty/libiconv-1.15/m4/eilseq.m4
  inflating: source4android-main/src/thirdparty/libiconv-1.15/m4/endian.m4
  inflating: source4android-main/src/thirdparty/libiconv-1.15/m4/general.m4
  inflating: source4android-main/src/thirdparty/libiconv-1.15/m4/libtool.m4
source4android-main/src/thirdparty/libiconv-1.15/m4/libtool.m4:  write error (disk full?).  Continue? (y/n/^C)
```
then you do not have enough diskspace. Clear some storage [Guide for Debian.](https://askubuntu.com/questions/5980/how-do-i-free-up-disk-space), [Guide for other distro's](https://unix.stackexchange.com/questions/774199/how-to-clean-up-a-linux-system-to-free-up-disk-space)

# Credits
- GuestSneezeOSDev: Created most of the stuff used in the mod such as the build scripts
- nillerusr: The touch support was used from his repository which uses leaked code so I will not be able to link it.
- Valve: Source SDK 2013 base code.
- XutaxKamay: For the swept ray box fixes.
- sortie: Linux ports of VRAD, VVIS, and VBSP.
