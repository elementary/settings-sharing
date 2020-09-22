/*
 * Copyright (c) 2016 elementary LLC (https://launchpad.net/switchboard-plug-sharing)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class Sharing.Widgets.BluetoothPage : SettingsPage {
    private const string SCHEMA = "io.elementary.desktop.wingpanel.bluetooth";
    GLib.Settings bluetooth_settings;
    Gtk.ComboBoxText accept_combo;
    Gtk.Switch notify_switch;

    public BluetoothPage () {
        base ("bluetooth",
              _("Bluetooth"),
              "preferences-bluetooth",
              _("While enabled, bluetooth devices can send files to Downloads."),
              _("While disabled, bluetooth devices can not send files to Downloads."));

        var settings_schema = SettingsSchemaSource.get_default ().lookup (SCHEMA, true);
        if (settings_schema != null) {
            bluetooth_settings = new Settings (SCHEMA);
            bluetooth_settings.bind ("bluetooth-obex-enabled", service_switch, "active", SettingsBindFlags.NO_SENSITIVITY);
            bluetooth_settings.bind ("bluetooth-accept-files", accept_combo, "active", SettingsBindFlags.DEFAULT);
            bluetooth_settings.bind ("bluetooth-notify", notify_switch, "active", SettingsBindFlags.DEFAULT);
            bluetooth_settings.changed ["bluetooth-enabled"].connect (set_service_state);
        }
        service_switch.notify ["active"].connect (set_service_state);

        set_service_state ();
    }

    construct {
        var notify_label = new Gtk.Label (_("Notify about newly received files:"));
        ((Gtk.Misc)notify_label).xalign = 1.0f;

        notify_switch = new Gtk.Switch ();
        notify_switch.halign = Gtk.Align.START;

        var accept_label = new Gtk.Label (_("Accept files from bluetooth devices:"));
        ((Gtk.Misc) accept_label).xalign = 1.0f;

        accept_combo = new Gtk.ComboBoxText ();
        accept_combo.hexpand = true;
        accept_combo.append ("bonded", _("When paired"));
        accept_combo.append ("ask", _("Ask me"));

        alert_view.title = _("Bluetooth Sharing Is Not Available");
        alert_view.description = _("The bluetooth device is either disconnected or disabled. Check bluetooth settings and try again.");
        alert_view.icon_name ="bluetooth-disabled";
        alert_view.valign = Gtk.Align.CENTER;

        content_grid.attach (notify_label, 0, 0, 1, 1);
        content_grid.attach (notify_switch, 1, 0, 1, 1);
        content_grid.attach (accept_label, 0, 1, 1, 1);
        content_grid.attach (accept_combo, 1, 1, 1, 1);

        link_button.label = _("Bluetooth settings…");
        link_button.tooltip_text = _("Open bluetooth settings");
        link_button.uri = "settings://network/bluetooth";
        link_button.no_show_all = false;
    }

    private void set_service_state () {
        if (bluetooth_settings != null) {
            if (bluetooth_settings.get_boolean ("bluetooth-enabled")) {
                update_state (bluetooth_settings.get_boolean ("bluetooth-obex-enabled") ? ServiceState.ENABLED : ServiceState.DISABLED);
            } else {
                update_state (ServiceState.NOT_AVAILABLE);
            }
        }
    }
}
