#! /usr/bin/env bash

# Store the current working directory
export ROOTDIR=$PWD

# Get our current base directory name
export BASEDIR=${PWD##*/}

if [ "$BASEDIR" != "AppImage" ]; then
	echo "Not in AppImage directory... aborting!"
	exit
fi

# Create/clean the buid directory
if [ -d "build" ]; then
	rm -rf build
fi
mkdir build

if [ -f "Folio-x86_64.AppImage" ]; then
	rm Folio-x86_64.AppImage
fi

# Setup our export variables for the build
export DESTDIR="../AppImage/build"
export NO_STRIP=true

# Execute the build/install
cd $ROOTDIR/../build
ninja install

# Complile the gschema
cd $ROOTDIR/build/usr/local/share/glib-2.0/schemas
glib-compile-schemas .

# Change back to the build directory
cd $ROOTDIR/build

# Create the appimage
linuxdeploy --appdir=. -d usr/local/share/applications/com.toolstack.Folio.desktop  -i usr/local/share/icons/hicolor/scalable/apps/com.toolstack.Folio.svg -e usr/local/bin/com.toolstack.Folio --custom-apprun=../AppRun.shim --output appimage

# Move the appimage up one level.
mv Folio-x86_64.AppImage ..

# Cleanup
cd $ROOTDIR
rm -rf build
