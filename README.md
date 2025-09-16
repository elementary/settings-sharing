# Sharing Settings
[![Translation status](https://l10n.elementaryos.org/widget/settings/sharing/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libadwaita-1-dev (>= 1.4)
* libgranite-7-dev
* libgtk-4-dev (>= 4.10)
* libswitchboard-3-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
