#! /bin/bash
### Linux 64 bit #######################
# Ubuntu 18.04.x ​​(LTS) is recommended  #
# Packages required:                   #
#       dialog subversion gcc make zip #
###########################################
# Configure where we can find things here #
NDK=r21
###############
#    true|false
APP=true
SVN_MENU=false
ARCH_MENU=false
####################################
export NCURSES_NO_UTF8_ACS=1
export LOCALE=UTF-8
####################################
# Checking the number of CPU cores #
cores=$(cat /proc/cpuinfo | grep "cpu cores" | awk -F: '{ num+=$2 } END{ print num }')
###############################
# Create a sources directory. #
dir=$(pwd)
src="$dir/sources"
[ ! -d $src ] && mkdir -p $src
#########################
# Download Android NDK. #
[ ! -d $src/android-ndk-$NDK ] && wget -c -P $src --progress=bar:force "https://dl.google.com/android/repository/android-ndk-$NDK-linux-x86_64.zip" 2>&1 | while read -d "%" X; do sed 's:^.*[^0-9]\([0-9]*\)$:\1:' <<< "$X"; done | dialog --title "" --clear --stdout --gauge "Download: android-ndk-$NDK-linux-x86_64.zip" 6 50
##################
# Unzip the NDK. #
[ ! -d $src/android-ndk-$NDK ] && unzip -d $src $src/android-ndk-$NDK-linux-x86_64.zip
############
# API Menu #
clear
_16="4.1_Jelly_Bean"
_17="4.2_Jelly_Bean"
_18="4.3_Jelly_Bean"
_19="4.4_KitKat"
_20="Wear_4.4_KitKat"
_21="5.0_Lollipop"
_22="5.1_Lollipop"
_23="6.0_Marshmallow"
_24="7.0_Nougat"
_25="7.1_Nougat"
_26="8.0_Oreo"
_27="8.1_Oreo"
_28="9.0_Pie"
_29="10.0_Q"
list=
for i in $(seq 16 29); do
	p="_$i"
	[ -d $src/android-ndk-$NDK/platforms/android-$i ] && list="$list $i ${!p} "
done
list=($list)
selected=$(dialog --stdout --clear --colors --backtitle $0 --menu "Android NDK $NDK" 16 40 10 ${list[@]})
case $selected in
1* | 2*) API=$selected ;;
*) exit ;;
esac
#############
# ARCH Menu #
ARCH="arm"
###
if $ARCH_MENU; then
	clear
	arch="arm arm64 x86 x86_64"
	s="12 40 4"
	[ "$API" -lt "21" ] && arch="arm x86" && s="10 40 2"
	p="_$API"
	list=
	for i in $arch; do list="$list $i "android$API" "; done
	list=($list)
	selected=$(dialog --stdout --clear --colors --backtitle $0 --menu "${!p}" $s ${list[@]})
	case $selected in
	arm | arm64 | x86 | x86_64) ARCH=$selected ;;
	*) exit ;;
	esac
fi
##############################
# Create a prefix directory. #
prefix=$src/sysroot/${ARCH}-${API}
[ ! -d $prefix ] && mkdir -p $prefix
#############################
# delete cam due to patches #
rm -rf $dir/oscam-svn
################################################
# Download the latest SVN from Cam/trunk repo. #
svn="http://www.streamboard.tv/svn/oscam/trunk"
if $SVN_MENU; then
	clear
	rev=$(svn info $svn | grep Revision | cut -d ' ' -f 2)
	[ -e $src/oscam-svn ] && file_rev=$(svn info $src/oscam-svn | grep Revision | cut -d ' ' -f 2)
	if [ ! $file_rev ]; then
		rev=$(dialog --no-cancel --title " OSCam (1000 to $rev)" --inputbox "" 7 35 "$rev" 3>&1 1>&2 2>&3)
		dialog --infobox 'Please wait...' 3 20
		svn co -r $rev $svn $src/oscam-svn 2>&1 >/dev/null
	else
		dialog --title "OSCam UPDATE" --backtitle "" --yesno "Online SVN ('$rev') = Local SVN ('$file_rev')" 7 50
		case $? in
		0)
			rev=$(dialog --no-cancel --title " Local svn:$file_rev" --inputbox "" 8 35 "$rev" 3>&1 1>&2 2>&3)
			dialog --infobox 'Please wait...' 3 20
			svn co -r $rev $svn $src/oscam-svn 2>&1 >/dev/null
			rev=$(svn info $src/oscam-svn | grep Revision | cut -d ' ' -f 2)
			;;
		esac
	fi
else
	dialog --infobox 'Please wait...' 3 20
	##################
	# SVN_MENU false #
	#svn co -r 11507 http://www.streamboard.tv/svn/oscam/trunk $src/oscam-svn 2>&1 >/dev/null
	svn co $svn $src/oscam-svn 2>&1 >/dev/null
fi
############
# USE Menu #
CONF_DIR="/data/local"
USE=
EXTRA_CFLAGS=
libusb=false
pcsc=false
patch_=($dir/patches/oscam/*.patch)
cp -r $src/oscam-svn $dir
rev=$(svn info $dir/oscam-svn | grep Revision | cut -d ' ' -f 2)
[ -e "${patch_[0]}" ] && _patch="patches "patches" on"
$APP && _pcsc="pcsc "USE_PCSC" off"
list=(emu "emu" off $_patch utf8 "USE_UTF8" off libusb "USE_LIBUSB" off $_pcsc)
clear
for selected in $(dialog --clear --separate-output --no-cancel --checklist "OSCam svn$rev $ARCH-android$API" 12 50 5 "${list[@]}" 2>&1 >/dev/tty); do
	case $selected in
	emu)
		dialog --infobox 'Please wait...' 3 20
		svn co https://github.com/oscam-emu/oscam-emu/trunk $src/oscam-emu 2>&1 >/dev/null
		patch -d $dir/oscam-svn -p0 <$src/oscam-emu/oscam-emu.patch
		;;
	patches)
		for i in ${patch_[@]}; do [ -e "${i}" ] && patch -d $dir/oscam-svn -p0 <${i}; done
		sleep 3
		;;
	utf8) USE="$USE USE_UTF8=1" ;;
	libusb)
		libusb=true
		EXTRA_CFLAGS="-DWITH_LIBUSB"
		USE="$USE USE_LIBUSB=1 LIBUSB_LIB=$prefix/lib/libusb-1.0.a LIBUSB_CFLAGS=-I$prefix/include/libusb-1.0 EXTRA_LIBS=-llog"
		;;
	pcsc)
		pcsc=true
		libusb=true
		EXTRA_CFLAGS="$EXTRA_CFLAGS -DWITH_PCSC"
		USE="$USE USE_PCSC=1 PCSC_LIB=$prefix/lib/libpcsclite.a PCSC_CFLAGS=-I$prefix/include/PCSC"
		;;
	esac
done
clear
#################
# CONF DIR Menu #
USE="$USE CONF_DIR=$(dialog --clear --no-cancel --title "OSCam config dir:" --inputbox $CONF_DIR 8 30 $CONF_DIR 3>&1 1>&2 2>&3)"
##########################
# patches error checking #
rej=($(find $dir/oscam-svn -name "*.rej"))
[ -e "${rej[0]}" ] && clear && find $dir/oscam-svn -name "*.rej" -exec echo WARNING PATCH ERROR! {} \; && exit
################
FLAGS="-fpic -fno-addrsig -ffunction-sections -fdata-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -Wno-invalid-command-line-argument -Wno-unused-command-line-argument -DANDROID -D__ANDROID_API__=$API"
case "$ARCH" in
arm)
	ABI="armeabi-v7a"
	HOST="arm-linux-androideabi"
	TARGET="armv7a-linux-androideabi$API"
	FLAGS="-march=armv7-a -mtune=cortex-a9 -mfloat-abi=softfp -mfpu=vfpv3-d16 $FLAGS"
	;;
x86)
	ABI="$ARCH"
	HOST="i686-linux-android"
	TARGET="${HOST}${API}"
	;;
arm64)
	ABI="arm64-v8a"
	HOST="aarch64-linux-android"
	TARGET="${HOST}${API}"
	[ "$API" -lt "21" ] && API="21"
	;;
x86_64)
	ABI="$ARCH"
	HOST="x86_64-linux-android"
	TARGET="${HOST}${API}"
	[ "$API" -lt "21" ] && API="21"
	;;
esac
#######################
# Export Android NDK. #
export ANDROID_NDK=$src/android-ndk-$NDK
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export CC="clang --target=$TARGET $FLAGS -I$prefix/include -L$prefix/lib"
export CXX="clang++ --target=$TARGET $FLAGS -I$prefix/include -L$prefix/lib"
#################################
# Download and Install OpenSSl. #
if [ ! -e $prefix/lib/libcrypto.a ]; then
	build=openssl-1.1.1d
	[ ! -e $src/$build.tar.gz ] && wget -c -P $src http://www.openssl.org/source/$build.tar.gz
	[ ! -d $src/$build ] && tar -C $src -xf $src/$build.tar.gz
	cd $src/$build
	./Configure android-$ARCH --api=0.9.8 -D__ANDROID_API__=$API no-afalgeng no-aria no-asan no-asm no-async no-autoalginit no-autoerrinit no-autoload-config no-bf no-blake2 no-camellia no-capieng no-cast no-chacha no-cmac no-cms no-comp no-crypto-mdebug no-crypto-mdebug-backtrace no-ct no-devcryptoeng no-dgram no-dh no-dsa no-dso no-dtls no-dynamic-engine no-ec no-ec2m no-ecdh no-ecdsa no-ec_nistp_64_gcc_128 no-egd no-engine no-err no-external-tests no-filenames no-fuzz-libfuzzer no-fuzz-afl no-gost no-heartbeats no-idea no-makedepend no-md2 no-mdc2 no-md4 no-msan no-multiblock no-nextprotoneg no-ocb no-ocsp no-pic no-poly1305 no-posix-io no-psk no-rc2 no-rc4 no-rc5 no-rdrand no-rfc3779 no-rmd160 no-scrypt no-sctp no-seed no-shared no-siphash no-sm2 no-sm3 no-sm4 no-srp no-srtp no-sse2 no-ssl no-ssl-trace no-tests no-threads no-tls no-ts no-ubsan no-ui-console no-unit-test no-whirlpool no-weak-ssl-ciphers no-zlib no-zlib-dynamic no-ssl3 no-ssl3-method no-tls1 no-tls1-method no-tls1_1 no-tls1_1-method no-tls1_2 no-tls1_2-method no-tls1_3 no-dtls1 no-dtls1-method no-dtls1_2 no-dtls1_2-method --prefix=$prefix
	make clean
	make -j$cores install_sw
	rm -rf $prefix/lib/*.so $src/$build
	clear
	[ ! -e $prefix/lib/libcrypto.a ] && echo "ERROR! $build" && exit
	cd $dir
fi
################################
# Download and Install libusb. #
if $libusb && [ ! -e $prefix/lib/libusb-1.0.a ]; then
	build=libusb-1.0.22
	[ ! -e $src/$build.tar.bz2 ] && wget -c -P $src https://github.com/libusb/libusb/releases/download/v1.0.22/$build.tar.bz2
	[ ! -d $src/$build ] && tar -C $src -jxf $src/$build.tar.bz2
	cd $src/$build
	./configure --host=$HOST --enable-static --disable-shared --disable-udev --prefix=$prefix
	cp $src/$build/android/config.h $src/$build/config.h
	make clean
	make -j$cores install
	rm -rf $prefix/lib/*.so $src/$build
	clear
	[ ! -e $prefix/lib/libusb-1.0.a ] && echo "ERROR! $build" && exit
	cd $dir
fi
###############################
# Download and Install pcscd. #
if $pcsc && [ ! -e $prefix/lib/libpcsclite.a ]; then
	build=pcsc-lite-1.8.24
	[ ! -e $src/$build.tar.bz2 ] && wget -c -P $src https://pcsclite.apdu.fr/files/$build.tar.bz2
	[ ! -d $src/$build ] && tar -C $src -jxf $src/$build.tar.bz2
	cd $src/$build
	FILE="./configure"
	mv $FILE $FILE~
	sed 's#as_fn_error $? "libusb not found, use ./configure LIBUSB_LIBS=..." "$LINENO" 5#echo "./configure LIBUSB_LIBS=..."#g' $FILE~ >$FILE
	chmod 775 $FILE
	rm -rf $FILE~
	./configure --host=$HOST --disable-libudev --enable-static --enable-serial --enable-static --disable-shared --enable-usb --enable-libusb --disable-libsystemd --enable-usbdropdir="/data/data/osebuild.cam/files/drivers" --enable-ipcdir="/dev" --enable-confdir="/data/data/osebuild.cam/files/reader.conf.d" LIBUSB_LIBS=$prefix/lib/libusb-1.0.a LIBUSB_CFLAGS=-I$prefix/include/libusb-1.0 LIBS=-llog --prefix=$prefix
	make clean
	make -j$cores
	### install ###
	mkdir -p $prefix/sbin
	mv $src/$build/src/pcscd $prefix/sbin
	mv $src/$build/src/.libs/libpcsclite.a $prefix/lib
	mkdir -p $prefix/include/PCSC
	cp $src/$build/src/PCSC/*.h $prefix/include/PCSC
	rm -rf $prefix/lib/*.so $src/$build
	clear
	[ ! -e $prefix/lib/libpcsclite.a ] && echo "ERROR! $build" && exit
	cd $dir
fi
##############################
# Download and Install ccid. #
if $pcsc && [ ! -e $prefix/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so ]; then
	build=ccid-1.4.30
	[ ! -e $src/$build.tar.bz2 ] && wget -c -P $src https://ccid.apdu.fr/files/$build.tar.bz2
	[ ! -d $src/$build ] && tar -C $src -jxf $src/$build.tar.bz2
	cd $src/$build
	FILE="./configure"
	mv $FILE $FILE~
	sed 's#as_fn_error $? "libusb not found, use ./configure LIBUSB_LIBS=..." "$LINENO" 5#echo "./configure LIBUSB_LIBS=..."#g' $FILE~ >$FILE~~
	sed 's#as_fn_error $? "SCardEstablishContext() not found, install pcsc-lite, or use PCSC_LIBS=...  ./configure" "$LINENO" 5#echo "./configure PCSC_LIBS=..."#g' $FILE~~ >$FILE
	chmod 775 $FILE
	rm -rf $FILE~ $FILE~~
	./configure --host=$HOST --enable-twinserial --enable-usbdropdir="/data/data/osebuild.cam/files/drivers" --enable-serialconfdir="/data/data/osebuild.cam/files/reader.conf.d" --enable-static --enable-shared LIBUSB_LIBS=$prefix/lib/libusb-1.0.a LIBUSB_CFLAGS=-I$prefix/include/libusb-1.0 LIBS=-llog PCSC_LIBS=$prefix/lib/libpcsclite.a PCSC_CFLAGS=-I$prefix/include/PCSC --prefix=$prefix
	make clean
	make -j$cores
	### install ###
	mkdir -p $prefix/drivers/ifd-ccid.bundle/Contents/Linux/ $prefix/drivers/serial
	mv $src/$build/src/.libs/libccid.so $prefix/drivers/ifd-ccid.bundle/Contents/Linux/
	mv $src/$build/src/.libs/libccidtwin.so $prefix/drivers/serial/
	make -C $src/$build/src Info.plist
	cp $src/$build/src/Info.plist $prefix/drivers/ifd-ccid.bundle/Contents/
	rm -rf $prefix/lib/*.so $src/$build
	clear
	[ ! -e $prefix/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so ] && echo "ERROR! $build" && exit
	cd $dir
fi
####################################
# Start interactive configuration. #
$dir/oscam-svn/config.sh --gui
################################
# Disable CLOCKFIX. (no librt) #
$dir/oscam-svn/config.sh --disable CLOCKFIX
#######################################
# Cross Compile Cam with Android NDK. #
cd $dir/oscam-svn
make -j$cores \
	$USE EXTRA_CFLAGS="$EXTRA_CFLAGS" \
	USE_LIBCRYPTO=1 \
	CC="$CC" \
	LIB_RT= \
	LIB_PTHREAD= \
	STRIP=$HOST-strip \
	TARGET="$TARGET"
######
rm -rf $dir/oscam-svn/Distribution/*.debug
cp $dir/oscam-svn/Distribution/oscam*$rev*android* $dir
################
# APP compress #
if $APP; then
	p="_$API"
	mkdir -p $dir/${!p}
	rm -rf $dir/${!p}/oscam-$ABI.zip
	zip -j $dir/${!p}/oscam-$ABI.zip -xi $dir/oscam-svn/Distribution/oscam*$rev*android*
	if $pcsc; then
		zip -j $dir/${!p}/pcscd-${ABI}.zip -xi $prefix/sbin/pcscd
		zip -j $dir/${!p}/libccid-${ABI}.zip -xi $prefix/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so
		zip -j $dir/${!p}/libccidtwin-${ABI}.zip -xi $prefix/drivers/serial/libccidtwin.so
		zip -j $dir/${!p}/Info.plist.zip -xi $prefix/drivers/ifd-ccid.bundle/Contents/Info.plist
	fi
fi
######
exit
