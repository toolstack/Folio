# <img src="./data/icons/hicolor/scalable/apps/com.toolstack.Folio.svg" height="64"/> Folio

## Take notes in markdown

A beautiful markdown note-taking app for GNOME (forked from [Paper](https://gitlab.com/posidon_software/paper)).

Contributions are appreciated, see below for how to help translate Folio!

## Some of Folio's features are:

 - Almost WYSIWYG markdown rendering
 - Searchable through GNOME search
 - Highlight and strike-through text formatting
 - Application theming based on notebook color
 - Trash can
 - Markdown document
 - Optional line numbers
 - Optional auto save
 - Open links with Control-Click
 - Link to other notes in Folio
 - Automatically create links for bare URL's and e-mail addresses

## Get Folio

The recommended way of installing Folio is through [Flatpak](https://flatpak.org) or [Snap](https://snapcraft.io) or as an [AppImage](https://appimage.org):

### From Flathub
<a href="https://flathub.org/apps/com.toolstack.Folio" target="_blank">
  <img src="https://flathub.org/assets/badges/flathub-badge-en.png" width="200"/>
</a>

### From Snapcraft
<a href="https://snapcraft.io/folio">
  <img alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg" />
</a>

### AppImage
<a href="https://github.com/toolstack/Folio/releases">
  <img alt="Get it as an AppImage" src="https://raw.githubusercontent.com/KhushrajRathod/TeleDrive/main/icon/vector/download-appimage.svg" />
</a>

### Manually
Go to the current [GitHub Releases](https://github.com/toolstack/Folio/releases) page, select the latest release, and download the asset called `Folio-YY.##.flatpak`.  Once downloaded, use `flatpak install Folio-YY.##.flatpak` to install Folio on your computer.

You can use the same process to update to a newer release as well.

## Libraries Used
 - [libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
 - [gtksourceview-5](https://gitlab.gnome.org/GNOME/gtksourceview)

## License
The source code is GPLv3

## Notes Storage
By default, notes are stored in `~/.var/app/com.toolstack.Folio/data`,
but that can be changed in preferences

## Translations
Folio has been translated into several different languages by users.  Previously this was done by submitting pull requests to add the various language files.

Folio now has an online [localization portal](https://localize.toolstack.com/glotpress), if you would like to participate in translating Folio, send an [e-mail](mailto://greg@toolstack.com) and request access for the language you would like to translate.

## Build Instructions
Flatpak build requires flatpak-building installed.

### Local builds (NOT RECOMMENDED)
 - change into the top level source directory
 - to configure the build environment (required only once), run `meson build`
 - change into the build directory
 - to build Folio, run `ninja`
 - to install Folio, run `ninja install`
 - to run Folio, run `src/com.toolstack.Folio`

### Flatpak builds
 - install flatpak-builder if not already installed
 - change into the top level source directory
 - to build the flatpak, run `flatpak-builder --force-clean flatpak com.toolstack.Folio.json`
 - to build and install the flatpak, run `flatpak-builder --user --install --force-clean flatpak com.toolstack.Folio.json`
 - to launch the flatpak, run `flatpak run com.toolstack.Folio`

### Snap builds
 - Install snapcraft if not already installed
 - change into the top level source directory
 - to build the snap, run `snapcraft`
 - to install locally, run `sudo snap install ./folio_YY.XX_amd64.snap --dangerous`
 - to launch the snap, run `folio`

### AppImage builds
 - Install linuxdeploy if not already installed
 - change into the AppImage directory in the main Folio directory
 - run AppImage script `./folio.build.appimage.sh`
 - to launch the AppImage, run `./Folio-x86_64.AppImage`

## Release instructions
Folio uses a YY.## version format string, where YY is the two digit year (aka 23, 24, 25, etc) and ## is the release number of the year (aka 01 for the first release, 02 for the second release, etc., not the month number).

The release version is located in the main `meson.build` file, no other files contain the version number.

The full changelog is located in `data/app.metainfo.xml.in` and the current release for the about dialog is in `src/application.vala`.

Before doing a release, make sure to e-mail the translation editors to let them know to update the translations.  This should be done at least 2 days in advance to give them time to make their updates.  Once they update are done, make sure to export the translations and commit them to git.

Once updated, edit the flatpak and snap files:
 - change into the top level source directory
 - edit `com.toolstack.Folio.json` and update the `tag` value for sources, also **remove** the `commit` hash (don't forget to remove the comma on the line above) temporarily (we'll add it back later)
 - change into the `snap` directory
 - edit `snapcraft.yaml` and update the `source-tag`

Commit everything to git.

Now go to github and do the release.

After the release is done get the hash value for the commit for the new release tag and then add back the `commit` line in `com.toolstack.Folio.json`.  Commit it back to git as well.

Two actions should have been kicked off on the github release, one to build the flatpak and the other to build the snap.  These will take a few minutes to complete, but once they do, go to each one and download the built assets.

You will need to build the AppImage manually, follow the instructions above on how to do that and retrieve the generated Folio-x86_64.AppImage file.

Extract both zips that you downloaded and rename the resulting flatpak/snap/AppImage to "Folio-YY.XX\[-platform\].\[flatpak/snap/AppImage\]".

Go back to the release and attach these files to the release assets.

Now do the releases on Flathub and Snapcraft.

### Flathub release
 - get a clone of the flathub repo: `https://github.com/flathub/com.toolstack.Folio.git`
 - create a new branch labeled "YY.XX"
 - switch to the new branch
 - edit `com.toolstack.Folio.json` and update both the `tag` and `commit` lines to reflect the new release as well as any other changes since the last release (ie. runtime version, etc.)
 - commit the changes
 - go to github and create a new PR to merge the branch into master
 - commit the PR
 - monitor the [buildbot](https://buildbot.flathub.org/#/)

### Snap release (old way)
 - after build, login to your snapcraft [account](https://snapcraft.io)
 - go to the folio page, then select releases
 - find the new build  in the "Revisions available to release" section
 - click on "Promote/close" and select latest/stable
 - click on "Save"

### Snap release (new way)
 - after build, login to your snapcraft account `snapcraft login`
 - upload the build `snapcraft upload --release=stable folio_YY.##_amd64.snap`

### Snap release (new, new way)
 - login to your snapcraft [account](https://snapcraft.io)
 - go to the folio builds page
 - wait for builds to complete
 - go to the releases page
 - find the current release and select "Promote/close" (hover over the release line to see the button)
 - select latest/stable

## Generate translation POT
 Folio uses POT/PO files for it's translations, the POT file defines all the strings that are used by Folio.

 Before generating the POT file you must have already run meson for the first time and have run a local build.

 To generate the POT file:
 - change into the PO directory
 - run `./generate-POT-file.sh`

## FAQ

### How to link to other notes
Folio supports linking to other notes via the standard markdown link syntax, with the url being a relative path to another note.  For example, if you want to link to a note called "My big list of links" in the same notebook, then any of the following will work:

- `[my link](file://./My big list of links)`
- `[my link](./My big list of links)`
- `[my link](./My big list of links.md)`

If you want to link to another notebook called "Junk links", you can use any of the following formats:

- `[my link](file://../Junk links/My big list of links)`
- `[my link](../Junk links/My big list of links)`
- `[my link](../Junk links/My big list of links.md)`

### Integrating with Nextcloud Notes
Nextcloud notes uses markdown files to store it's information in and has an API to access these, however Folio does not support the API, but can still integrate with Nextcloud notes.

You have two options, either connect with WebDav and expose the notes directory as a filesystem or use the Nextcloud desktop client to synchronize the notes directory to your desktop.

In either case you can then go into Folio's preferences and change the storage location to the Nextcloud Notes folder.  You might want to unhide the trash folder, otherwise you'll see a ".trash" folder in your Nextcloud Notes on other clients (unhiding renames it to "Trash").

You may also want to change the trash folder's location to somewhere else on the file system to avoid synchronizing it back to Nextcloud.

There are a few cavitates when using Folio with Nextcloud notes:

- Folio will monitor the currently displayed note for any changes on the filesystem and reload it automatically if no changes have been made in Folio.  If a change has been made, Folio will prompt you to either reload the note or overwrite it.
- Folio will also check if a note has been changed when you save it, once more prompting for what to do if it sees a change on the file system that Folio did not make itself.
- Folio will *not* monitor for new notes or notebooks at this time, issue #[58](https://github.com/toolstack/Folio/issues/58) is open to address this at some point in the future.
- Folio only supports a single level of notebooks, so any Nextcloud notes that are store more than one level deep (aka in subfolders of subfolders) will not be displayed in Folio.  Issue #[11](https://github.com/toolstack/Folio/issues/11) is open to address this at some point in the future.

### Why fork Paper?
Unfortunately Paper is out of date and the developer does not have the time/interest to maintain it any more.

### Ok, so what is Folio's main focus
The primary focus of my fork is getting everything up to date and supported for the long term.

A secondary focus is feature additions.  Some new features that have already been added are:
- Better handling of escaped characters in code spans.
- Reworking of the format bar to act more like use user expect, including toggling formatting and smarter formatting.
- Control-click to open links in a browser.
- Marking non-markdown formatted links and email addresses.
- Fixed a ton of crashes caused by files without ending EOL markers.
- Automatically insert formatting around current words instead of in the middle of them.

You can see what's planned via the [issue tracker at GitHub](https://github.com/toolstack/Folio/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement).

### So what isn't planned
Folio is not a replacement for applications like OneNote or other advanced note taking apps, as such, there are some features that will never be added to Folio, like:

- Image markup
- Handwriting support
- MathML
- PDF or other document type embedding

Basically anything that tries to make Folio into something other than a markdown editor.

Of course if someone created a PR that added one or more of those things, I'd be open to reviewing it and see if the implementation fits well or not.

### Using Folio with cloud storage providers
You can use Folio with cloud storage providers like Google Drive, however there are a few things to keep in mind:

- Cloud services are slower than local storage, large notebook/note collections may be slow to load on startup.
- Detection of changes to notes may be impacted, as cloud providers may not indicate a file change on the server in a way that Folio will detect.

#### Google Drive Integration with GNOME
- Google Drive's integration in GNOME does not use display names on disk, but instead file hashes, so when selecting the notes folder you will see the display names, but after selecting the folder the hash values will be displayed in the file location box on the preferences screen.  Display names will be used in the notebook and notes list.
- Performance may be impacted as the display names must be retrieved from the cloud, which is of course slow in comparison to local file names.

#### Nextcloud Integration with GNOME
- GNOME's integration with Nextcloud is effectively a WebDAV connection so all data is keep in the cloud.  This may impact performance.

#### Non GNOME Integrated Cloud Providers
Cloud providers that do not integrate directly with GNOME or have alternatives to GNOME's integration (like Nextcloud) should work and may not have the above mentioned issues.

In general, if your cloud provider has a sync client, that copies your data to your local disk and keeps it up to date, you will have a better experience with Folio than a client that tries to use the cloud directly.
