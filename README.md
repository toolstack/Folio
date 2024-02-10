# <img src="./data/icons/hicolor/scalable/apps/io.posidon.Paper.svg" height="64"/>Paper

## Take notes in Markdown

Contributions are appreciated!


## Some of Paper features:

 - Almost WYSIWYG markdown rendering

 - Searchable through GNOME search

 - Highlight and Strikethrough text formatting

 - App recoloring based on notebook color

 - Trash can

 - Markdown document

## Get Paper

The recommended way of installing Paper is through [Flatpak](https://flatpak.org)

<a href="https://flathub.org/apps/details/io.posidon.Paper"><img src="https://flathub.org/assets/badges/flathub-badge-en.png" width="200"/></a>

## Libraries Used
 - [libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
 - [gtksourceview-5](https://gitlab.gnome.org/GNOME/gtksourceview)

## License
The source code is GPLv3

## Notes Storage
By default, notes are stored in `~/.var/app/io.posidon.Paper/data`,
but that can be changed in preferences

## Build Instructions
Flatpak build requires flatpak-building installed.

 - change into the top level source directory
 - to configure the build enviroment (required only once), run ```meson build```
 - change into the build directory
 - to build Paper, run ```ninja```
 - change back to top level source directory
 - to create the flatpak, run ```flatpak-builder flatpak io.posidon.Paper.json```
 - to install the flatpak, run ```flatpak-builder --user --install --force-clean flatpak io.posidon.Paper.json```

You may now run the flatpak with ```flatpak run io.posidon.Paper``` or through your lancher.