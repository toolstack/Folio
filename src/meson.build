paper_sources = [
  'main.vala',
  'application.vala',

  'ui/window.vala',
  'ui/preferences.vala',

  'ui/notebooks_bar/notebooks_bar.vala',
  'ui/notebooks_bar/notebook_preview.vala',
  'ui/notebooks_bar/icon.vala',
  'ui/notebooks_bar/notebook_menu.vala',
  'ui/notebooks_bar/create_popup.vala',

  'ui/notebook_sidebar/note_card.vala',
  'ui/notebook_sidebar/note_menu.vala',

  'ui/markdown_cheatsheet/markdown_cheatsheet.vala',

  'ui/popup/confirmation_popup.vala',
  'ui/popup/note_create_popup.vala',

  'ui/markdown/markdown_buffer.vala',
  'ui/markdown/markdown_view.vala',
  'ui/markdown/heading_popover.vala',

  'interface/note.vala',
  'interface/notebook.vala',
  'interface/provider.vala',
  'interface/trash.vala',
  'interface/local/provider.vala',
  'interface/local/notebook.vala',
  'interface/local/trash/trash.vala',
  'interface/local/trash/trashed_notebook.vala',

  'color.vala',
]

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : false)

paper_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gmodule-2.0'),
  dependency('gtk4'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
  dependency('libadwaita-1', version: '>= 1.0', required: true),
  dependency('gtksourceview-5'),
  m_dep,
]

gnome = import('gnome')

paper_sources += gnome.compile_resources(
  'paper-resources',
  'paper.gresource.xml',
  source_dir: 'src',
  c_name: 'paper'
)

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', version)
configure_file(output: 'config.h', configuration: conf)


executable(
  meson.project_name(),
  paper_sources,
  vala_args: [meson.project_source_root() + '/src/config.vapi', '--target-glib=2.70'],
  dependencies: paper_deps,
  install: true,
)
