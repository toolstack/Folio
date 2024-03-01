# <img src="./data/icons/hicolor/scalable/apps/com.toolstack.Folio.svg" height="64"/>Folio

## Take notes in markdown

A fork of [Paper](https://gitlab.com/posidon_software/paper).

Contributions are appreciated!


## Some of Folio's features:

 - Almost WYSIWYG markdown rendering

 - Searchable through GNOME search

 - Highlight and strikethrough text formatting

 - Application theming based on notebook color

 - Trash can

 - Markdown document

## Get Folio

The recommended way of installing Folio is through [Flatpak](https://flatpak.org)

Coming soon!

In the mean time, head over to the [GitHub Actions](https://github.com/toolstack/Folio/actions) page, select the latest release, and download the Artifacts package called `Folio-x86-64`.  Once downloaded, unzip it, and use `flatpak install Folio.flatpak` to install Folio on your computer.

You can use the same process to update to a newer release as well.

## Libraries Used
 - [libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
 - [gtksourceview-5](https://gitlab.gnome.org/GNOME/gtksourceview)

## License
The source code is GPLv3

## Notes Storage
By default, notes are stored in `~/.var/app/com.toolstack.Folio/data`,
but that can be changed in preferences

## Build Instructions
Flatpak build requires flatpak-building installed.

### Local builds (NOT RECOMMENDED)
 - change into the top level source directory
 - to configure the build environment (required only once), run ```meson build```
 - change into the build directory
 - to build Folio, run ```ninja```
 - to install Folio, run ```ninja install```

### Flatpak builds
 - change into the top level source directory
 - to build the flatpak, run ```flatpak-builder flatpak com.toolstack.Folio.json```
 - to install the flatpak, run ```flatpak-builder --user --install --force-clean flatpak com.toolstack.Folio.json```
 - to launch the flatpak, run ```flatpak run com.toolstack.Folio```

## Release instructions
 Folio uses a YY.## version format string, where YY is the two digit year (aka 23, 24, 25, etc) and ## is the release number of the year (aka 01 for the first release, 02 for the second release, etc., not the month number).

 The release version is located in the main `meson.build` file, no other files contain the version number.

 The full changelog is located in `data/app.metainfo.xml.in` and the current release for the about dialog is in `src/application.vala`.
