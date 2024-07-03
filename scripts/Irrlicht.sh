#!/bin/bash -e
irrlicht_ver=a2884e40000548a48b1e39842bbdc4558bc3b918
png_ver=1.6.40
jpeg_ver=3.0.0

download () {
	if [ ! -d irrlicht/.git ]; then
		git clone https://github.com/minetest/irrlicht/releases/tag/1.9.0mt10 irrlicht
		pushd irrlicht
		git checkout $irrlicht_ver
		popd
	fi
	get_tar_archive libpng "https://download.sourceforge.net/libpng/libpng-${png_ver}.tar.gz"
	get_tar_archive libjpeg "https://download.sourceforge.net/libjpeg-turbo/libjpeg-turbo-${jpeg_ver}.tar.gz"
}

build () {
	# Build libjpg and libpng first because Irrlicht needs them
	mkdir -p libpng
	pushd libpng
	$srcdir/libpng/configure --host=$CROSS_PREFIX
	make && make DESTDIR=$PWD install
	popd

	mkdir -p libjpeg
	pushd libjpeg
	cmake $srcdir/libjpeg "${CMAKE_FLAGS[@]}" -DENABLE_SHARED=OFF
	make && make DESTDIR=$PWD install
	popd

	local libpng=$PWD/libpng/usr/local/lib/libpng.a
	local libjpeg=$(echo $PWD/libjpeg/opt/libjpeg-turbo/lib*/libjpeg.a)
	cmake $srcdir/irrlicht "${CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DPNG_LIBRARY=$libpng \
		-DPNG_PNG_INCLUDE_DIR=$(dirname "$libpng")/../include \
		-DJPEG_LIBRARY=$libjpeg \
		-DJPEG_INCLUDE_DIR=$(dirname "$libjpeg")/../include
	make

	cp -p lib/Android/libIrrlichtMt.a $libpng $libjpeg $pkgdir/
	cp -a $srcdir/irrlicht/include $pkgdir/include
	cp -a $srcdir/irrlicht/media/Shaders $pkgdir/Shaders
}