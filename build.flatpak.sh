#! /usr/bin/env bash

# Store the current working directory
export ROOTDIR=$PWD

# Get our current base directory name
export BASEDIR=${PWD##*/}

if [ "$BASEDIR" != "Folio" ]; then
	echo "Not in Folio root directory... aborting!"
	exit
fi

# Create/clean the build directory
if [ -d "flatpak" ]; then
	rm -rf flatpak
fi

mkdir flatpak
cd flatpak

flatpak-builder --repo=repo --force-clean flatpak ../com.toolstack.Folio.json
flatpak build-bundle repo Folio-x86_64.flatpak --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo --arch=x86_64 com.toolstack.Folio master
