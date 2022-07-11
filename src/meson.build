paper_sources = [
  'main.vala',
  'application.vala',

  'ui/strings.vala',

  'ui/window/window.vala',
  'ui/preferences/preferences.vala',

  'ui/edit_view/edit_view.vala',
  'ui/edit_view/toolbar/toolbar.vala',
  'ui/file_editor/file_editor_window.vala',

  'ui/fuzzy_string_sorter.vala',

  'ui/window/notebooks_bar/notebooks_bar.vala',
  'ui/window/notebooks_bar/icon.vala',
  'ui/window/notebooks_bar/notebook_menu.vala',
  'ui/window/notebooks_bar/notebook_create_popup.vala',
  'ui/window/notebooks_bar/notebook_sidebar_item.vala',

  'ui/window/sidebar/note_card.vala',
  'ui/window/sidebar/note_menu.vala',
  'ui/window/sidebar/note_create_popup.vala',

  'ui/edit_view/cheatsheet/markdown_cheatsheet.vala',

  'ui/popup/notebook_selection_popup/notebook_list_item.vala',
  'ui/popup/notebook_selection_popup/notebook_selection_popup.vala',

  'ui/widgets/markdown/markdown_buffer.vala',
  'ui/widgets/markdown/markdown_view.vala',
  'ui/widgets/markdown/heading_popover.vala',

  'ui/widgets/save_indicator/save_indicator.vala',
  'ui/widgets/save_indicator/save_status.vala',
  'ui/widgets/theme_selector/theme_selector.vala',
  'ui/widgets/notebook_icon/notebook_preview.vala',

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
  dependency('libadwaita-1', version: '>= 1.1', required: true),
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
