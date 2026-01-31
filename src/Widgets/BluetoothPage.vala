/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class Sharing.Widgets.BluetoothPage : Switchboard.SettingsPage {
    private GLib.Settings daemon_settings;

    public BluetoothPage () {
        Object (activatable: true);
    }

    construct {
        title = _("Bluetooth");
        icon = new ThemedIcon ("preferences-bluetooth");
        show_end_title_buttons = true;

        var accept_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var accept_label = new Gtk.Label (_("Ask before accepting files:")) {
            halign = END,
            mnemonic_widget = accept_switch
        };

        var box = new Gtk.Box (HORIZONTAL, 12);
        box.append (accept_label);
        box.append (accept_switch);

        child = box;

        var settings_button = add_button (_("Bluetooth Settings…"));

        daemon_settings = new GLib.Settings ("io.elementary.desktop.bluetooth");
        daemon_settings.bind ("sharing", status_switch, "active", NO_SENSITIVITY);
        daemon_settings.bind ("confirm-accept-files", accept_switch, "active", DEFAULT);

        set_service_state ();

        daemon_settings.changed ["enabled"].connect (() => {
            set_service_state ();
        });

        status_switch.notify["active"].connect (() => {
            set_service_state ();
        });

        settings_button.clicked.connect (() => {
            var uri_launcher = new Gtk.UriLauncher ("settings://network/bluetooth");
            uri_launcher.launch.begin (((Gtk.Application) Application.get_default ()).active_window, null);
        });
    }

    private void set_service_state () {
        if (!daemon_settings.get_boolean ("enabled")) {
            description = _("The Bluetooth device is either disconnected or disabled. Check Bluetooth settings and try again.");
            status_type = ERROR;
            status = _("Not Available");

            return;
        }

        if (daemon_settings.get_boolean ("sharing")) {
            description = _("While enabled, Bluetooth devices can send files to Downloads.");
            status = _("Enabled");
            status_type = SUCCESS;
        } else {
            description = _("While disabled, Bluetooth devices can not send files to Downloads.");
            status = _("Disabled");
            status_type = OFFLINE;
        }
    }
}
