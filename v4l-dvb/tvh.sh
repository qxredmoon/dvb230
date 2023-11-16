#! /bin/bash
### Linux 64 bit #######################
# Ubuntu 18.04.x ​​(LTS) is recommended  #
# Packages required:                   #
#       dialog subversion gcc make zip #
###########################################
# Configure where we can find things here #
NDK=r21
###
ARCH="arm" # arm, arm64, x86, x86_64
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
##############################
# Create a prefix directory. #
prefix=$src/sysroot/${ARCH}-${API}
[ ! -d $prefix ] && mkdir -p $prefix
############
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
###################################
export ANDROID_NDK=$src/android-ndk-$NDK
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
export CC="clang --target=$TARGET $FLAGS -I$prefix/include -L$prefix/lib"
export CXX="clang++ --target=$TARGET $FLAGS -I$prefix/include -L$prefix/lib"
#export CROSS_SYSROOT=$prefix
BUILD_SYS=x86_64-linux-gnu
###################################
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
fi
########
if [ ! -e $prefix/bin/iconv ]; then
	build=libiconv-1.16
	[ ! -e $src/$build.tar.gz ] && wget -c -P $src http://ftp.gnu.org/pub/gnu/libiconv/$build.tar.gz
	tar -C $src -xf $src/$build.tar.gz
	cd $src/$build
	./configure --build=${BUILD_SYS} --host=$HOST --prefix=$prefix --disable-rpath --enable-static
	make -j4 install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/$build
	clear
	[ ! -e $prefix/bin/iconv ] && echo "ERROR! $build" && exit
fi
########
if [ ! -e $prefix/lib/pkgconfig/libffi.pc ]; then
	build=libffi-3.3-rc1
	[ ! -e $src/$build.tar.gz ] && wget -c -P $src https://github.com/libffi/libffi/releases/download/v3.3-rc1/$build.tar.gz
	tar -C $src -xf $src/$build.tar.gz
	cd $src/$build
	sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' -i include/Makefile.in
	sed -e '/^includedir/ s/=.*$/=@includedir@/' -e 's/^Cflags: -I${includedir}/Cflags:/' -i libffi.pc.in
	./configure --host=$HOST --prefix=$prefix --enable-static --disable-multi-os-directory
	make -j$cores install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/$build
	clear
	[ ! -e $prefix/lib/pkgconfig/libffi.pc ] && echo "ERROR! $build" && exit
fi
########
if [ ! -e $prefix/bin/gettext ]; then
	build=gettext-0.20.1
	[ ! -e $src/$build.tar.gz ] && wget -c -P $src http://ftp.gnu.org/pub/gnu/gettext/$build.tar.gz
	tar -C $src -xf $src/$build.tar.gz
	cd $src/$build
	./configure --build=${BUILD_SYS} --host=$HOST --prefix=$prefix --disable-rpath --enable-static
	make -j$cores install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/$build
	clear
	[ ! -e $prefix/bin/gettext ] && echo "ERROR! $build" && exit
fi
########
if [ ! -e $prefix/lib/libyasm.a ]; then
	[ ! -e $src/v1.3.0.tar.gz ] && wget -c -P $src https://github.com/yasm/yasm/archive/v1.3.0.tar.gz
	tar -C $src -xf $src/v1.3.0.tar.gz
	cd $src/yasm-1.3.0
	./autogen.sh
	./configure --build=${BUILD_SYS} --host=$HOST --prefix=$prefix --with-sysroot=$prefix --disable-rpath
	make -j$cores install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/yasm-1.3.0
	clear
	[ ! -e $prefix/lib/libyasm.a ] && echo "ERROR! yasm-1.3.0" && exit
fi
########
if [ ! -e $prefix/lib/pkgconfig/libpcre2-8.pc ]; then
	build=pcre2-10.33
	[ ! -e $src/$build.tar.gz ] && wget -c -P $src https://ftp.pcre.org/pub/pcre/$build.tar.gz
	tar -C $src -xf $src/$build.tar.gz
	cd $src/$build
	./configure --build=${BUILD_SYS} --host=$HOST --prefix=$prefix --enable-static
	make -j$cores install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/$build
	clear
	[ ! -e $prefix/lib/pkgconfig/libpcre2-8.pc ] && echo "ERROR! $build" && exit
fi
########
if [ ! -e $prefix/lib/libdvbcsa.a ]; then
	build=android-external-libdvbcsa
	rev=6074ba4949c8c418f6a2f1c118a054633478b268
	[ ! -e $src/android-external-libdvbcsa ] && wget -c -P $src https://github.com/vitmod/$build/archive/$rev.tar.gz
	tar -C $src -xf $src/$rev.tar.gz
	cd $src/$build-$rev
	./configure --build=${BUILD_SYS} --host=arm --prefix=$prefix --with-sysroot=$prefix --enable-static=yes
	make clean
	make -j$cores install
	rm -rf $prefix/lib/*.so $prefix/lib/*.la $src/$build-$rev
	clear
	[ ! -e $prefix/lib/libdvbcsa.a ] && echo "ERROR! android-external-libdvbcsa" && exit
fi
## ps ##
if [ ! -e $prefix/bin/busybox ]; then
	build=busybox-1.31.1
	[ ! -e $src/$build.tar.bz2 ] && wget -c -P $src https://busybox.net/downloads/$build.tar.bz2
	[ ! -d $src/$build ] && tar -C $src -xf $src/$build.tar.bz2 && patch -d $src/$build -p1 <$dir/patches/busybox/busybox.diff && cp $dir/patches/busybox/busybox-android.config $src/$build/.config
	cd $src/$build
	make clean
	#make menuconfig
	export CONFIG_EXTRA_CFLAGS="-DSK_RELEASE -Os -fno-short-enums -fgcse-after-reload -frename-registers -fno-builtin-stpcpy -fuse-ld=bfd"
	make -j$cores CROSS_COMPILE="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$HOST-" \
		ARCH=arm CC="$CC" \
		CONFIG_EXTRA_CFLAGS="$CONFIG_EXTRA_CFLAGS"

	cp $src/$build/busybox $prefix/bin/busybox
	rm -rf $src/$build
	clear
	[ ! -e $prefix/bin/busybox ] && echo "ERROR! $build" && exit
fi
###############
## tvheadend ##
build=tvheadend
[ ! -d $src/$build ] && mkdir $src/$build
cd $src
clear
git clone https://github.com/tvheadend/tvheadend.git $src/$build
###################################
# delete tvheadend due to patches #
rm -rf $dir/$build $prefix/bin/$build && cp -r $src/$build $dir
patch_=($dir/patches/$build/$build*.patch)
for i in ${patch_[@]}; do [ -e "${i}" ] && patch -d $dir/$build -p1 <${i}; done
cd $dir/$build
# git checkout 912078267423fd54d52ee31e645cc778323fdd2b
./configure \
	--build=${BUILD_SYS} --host=$HOST --prefix=$prefix \
	--enable-android \
	--arch=armeabi-v7a \
	--enable-dvbcsa \
	--enable-tvhcsa \
	--enable-epoll \
	--enable-bundle \
	--enable-hdhomerun_client \
	--enable-hdhomerun_static \
	--disable-dbus_1 \
	--disable-avahi \
	--disable-v4l \
	--disable-libav \
	--disable-inotify \
	--disable-ffmpeg_static \
	--enable-libfdkaac_static \
	--enable-libopus_static \
	--disable-libtheora \
	--disable-libtheora_static \
	--enable-libvorbis_static \
	--enable-libvpx_static \
	--enable-libx264_static \
	--enable-libx265_static \
	--disable-libav \
	--disable-libfdkaac \
	--disable-libopus \
	--disable-libvorbis \
	--disable-libvpx \
	--disable-libx264 \
	--disable-libx265 \
	--disable-bintray_cache \
	--nowerror \
	--release
#export CROSS_COMPILE=$CC-
make -j$cores install
######################
p="_$API"
mkdir -p $dir/${!p}
zip -j $dir/${!p}/tvheadend-$ABI.zip -xi $prefix/bin/tvheadend
zip -j $dir/${!p}/busybox-$ABI.zip -xi $prefix/bin/busybox
#rm -rf $dir/tvheadend
########################################################
if [ -e $dir/${!p}/tvheadend-$ABI.zip ]; then
	clear
	text="Happy: $dir/${!p}/tvheadend-$ABI.zip "
	for i in $(seq 0 $(expr length "${text}")); do
		echo -e -n "$(echo "\033[44m\033[1;33m")${text:$i:1}"
		sleep 0.1
	done
	echo -e $(echo "\033[m")
fi
########################################################
# run example: tvheadend -B -C -u root -g video -c /sdcard/"folder" -l /sdcard/"folder"/log.log
########################################################
exit
