plug_files = files(
    'Plug.vala',
    'Widgets/DLNAPage.vala',
    'Widgets/BluetoothPage.vala',
    'Widgets/RemoteDesktopPage.vala',
    'Backend/RygelStartupManager.vala',
    'Backend/RygelConfigFile.vala',
    'Backend/SharingDBusInterface.vala',
    'Backend/RemoteDesktopManager.vala'
)

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4', version: '>=4.10'),
        dependency('libadwaita-1', version: '>=1.4'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'network')
)
