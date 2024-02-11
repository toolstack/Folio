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

 - change into the top level source directory
 - to configure the build environment (required only once), run ```meson build```
 - change into the build directory
 - to build Folio, run ```ninja```
 - change back to top level source directory
 - to create the flatpak, run ```flatpak-builder flatpak com.toolstack.Folio.json```
 - to install the flatpak, run ```flatpak-builder --user --install --force-clean flatpak com.toolstack.Folio.json```

You may now run the flatpak with ```flatpak run com.toolstack.Folio``` or through your launcher.