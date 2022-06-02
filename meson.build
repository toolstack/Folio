project(
  'io.posidon.Paper',
  ['c', 'vala'],
  version: '22.6',
  meson_version: '>= 0.59.4',
  default_options: [
    'warning_level=2',
  ],
)

i18n = import('i18n')
gnome = import('gnome')

app_id = meson.project_name()
version = meson.project_version()

add_project_arguments(
  [
    '--enable-experimental',
  ],
  language: 'vala'
)

subdir('lib')
subdir('po')
subdir('data')
subdir('src')
subdir('search-provider')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)
