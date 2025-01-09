# Source4android
> [!CAUTION]
> Please do not use this as its not complete yet, please proceed with caution.

Source4Android is an open-source, base mod for Half-Life 2 which allows players to port their mods to Android and Android-based systems without using any leaked code.

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
# Crediting where credits are due.
- GuestSneezeOSDev: Created most of the stuff used in the mod such as the build scripts
- nillerusr: The touch support was used from his repository which uses leaked code so I will not be able to link it.
- Valve: Source SDK 2013 base code.