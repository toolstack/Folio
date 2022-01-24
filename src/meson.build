paper_sources = [
  'main.vala',
  'window.vala',
  'preferences.vala',
  'application.vala',
  'notebook_icon.vala',
  'note_card.vala',
  'popup/confirmation_popup.vala',
  'popup/notebook_create_popup.vala',
  'popup/note_create_popup.vala',
  'popup/context/note_menu.vala',
  'popup/context/notebook_menu.vala',
  'interface/note.vala',
  'interface/notebook.vala',
  'interface/provider.vala',
  'interface/local/note.vala',
  'interface/local/provider.vala',
  'interface/local/notebook.vala',
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
  join_paths('res', 'paper.gresource.xml'),
  source_dir: 'res',
  c_name: 'paper'
)

app_id = 'io.posidon.Paper'

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
configure_file(output: 'config.h', configuration: conf)


executable(
  meson.project_name(),
  paper_sources,
  vala_args: [meson.project_source_root() + '/src/config.vapi', '--target-glib=2.70'],
  dependencies: paper_deps,
  install: true,
)
