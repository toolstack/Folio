paper_sources = [
  'main.vala',
  'application.vala',

  'ui/strings.vala',

  'ui/window.vala',
  'ui/preferences.vala',

  'ui/fuzzy_string_sorter.vala',

  'ui/notebooks_bar/notebooks_bar.vala',
  'ui/notebooks_bar/notebook_preview.vala',
  'ui/notebooks_bar/icon.vala',
  'ui/notebooks_bar/notebook_menu.vala',
  'ui/notebooks_bar/notebook_create_popup.vala',

  'ui/notebook_sidebar/note_card.vala',
  'ui/notebook_sidebar/note_menu.vala',
  'ui/notebook_sidebar/note_create_popup.vala',

  'ui/markdown_cheatsheet/markdown_cheatsheet.vala',

  'ui/popup/confirmation_popup.vala',
  'ui/popup/notebook_selection_popup/notebook_list_item.vala',
  'ui/popup/notebook_selection_popup/notebook_selection_popup.vala',

  'ui/markdown/markdown_buffer.vala',
  'ui/markdown/markdown_view.vala',
  'ui/markdown/heading_popover.vala',

  lib_sources,

  'color.vala',
]

subdir('ui')
generated_resources_dir = meson.current_build_dir()

paper_sources += gnome.compile_resources('paper-resources',
  'paper.gresource.xml',
  dependencies: blueprints,
  source_dir: ['src', generated_resources_dir],
  c_name: 'paper'
)

paper_sources += custom_target('blueprint-hack',
  input: blueprints,
  output: 'blueprint.vala',
  command: [find_program('touch'), '@OUTPUT@']
)


conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', version)
conf.set_quoted('GNOMELOCALEDIR', get_option('prefix') / get_option('localedir'))
configure_file(output: 'config.h', configuration: conf)

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: false)

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

executable(
  meson.project_name(),
  paper_sources,
  c_args: [
    '-DGETTEXT_PACKAGE="' + app_id + '"'
  ],
  vala_args: [
    meson.project_source_root() + '/src/config.vapi',
    '--target-glib=2.72.1',
    '--gresourcesdir=' + generated_resources_dir,
  ],
  dependencies: paper_deps,
  implicit_include_directories: true,
  install: true,
)
