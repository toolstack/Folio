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
  namespace : 'Paper',
)

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', version)
configure_file(output: 'config.h', configuration: conf)

executable(
  'paper-search-provider',
  search_provider_sources,
  dependencies: search_provider_deps,
  vala_args: [
    meson.project_source_root() + '/src/config.vapi',
    '--target-glib=2.70',
  ],
  install: true,
)

install_data(
  'io.posidon.Paper.SearchProvider-search-provider.ini',
  install_dir: get_option('datadir') / 'gnome-shell' / 'search-providers',
)

# The DBUS service file
dbusconf = configuration_data()
configuration_file = configure_file(
  input: 'io.posidon.Paper.SearchProvider.service.in',
  output: 'io.posidon.Paper.SearchProvider.service',
  configuration: dbusconf,
)

install_data(
  configuration_file,
  install_dir: get_option('datadir') / 'dbus-1' / 'services',
)
