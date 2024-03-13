search_provider_sources = [
  'search-provider.vala',
  lib_sources,
]

search_provider_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gmodule-2.0'),
  dependency('gtk4'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
]

sp_sources = gnome.gdbus_codegen(
  'shell-search-provider-generated',
  sources: 'org.gnome.Shell.SearchProvider2.xml',
  interface_prefix : 'org.gnome.',
  namespace : 'Folio',
)

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', version)
configure_file(output: 'config.h', configuration: conf)

exec_name = 'folio-search-provider'

executable(
  exec_name,
  search_provider_sources,
  dependencies: search_provider_deps,
  c_args: [
	'-DGETTEXT_PACKAGE="' + app_id + '"'
  ],
  vala_args: [
    meson.project_source_root() + '/src/config.vapi',
    '--target-glib=2.70',
  ],
  install: true,
)

dbusconf = configuration_data()
dbusconf.set('app_id', app_id)
dbusconf.set('version', version)
dbusconf.set('exec_name', exec_name)

gnome_shell_file = configure_file(
  input: 'search-provider.ini',
  output: app_id + '.SearchProvider-search-provider.ini',
  configuration: dbusconf,
)

install_data(
  gnome_shell_file,
  install_dir: get_option('datadir') / 'gnome-shell' / 'search-providers',
)

configuration_file = configure_file(
  input: 'SearchProvider.service.in',
  output: app_id + '.SearchProvider.service',
  configuration: dbusconf,
)

install_data(
  configuration_file,
  install_dir: get_option('datadir') / 'dbus-1' / 'services',
)
