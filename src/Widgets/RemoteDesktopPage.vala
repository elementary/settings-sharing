/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023-2026 elementary, Inc. (https://elementary.io)
 */

public class Sharing.Widgets.RemoteDesktopPage : Switchboard.SettingsPage {
    private const uint DEFAULT_PORT = 3389;

    private Backend.RemoteDesktopManager remote_desktop;
    private Gtk.Entry rdp_url_entry;
    private Gtk.Entry username_entry;
    private Gtk.PasswordEntry password_entry;
    private uint save_timeout_id = 0;
    private bool syncing = false;
    private bool has_credentials = false;
    private string? error_message = null;

    public RemoteDesktopPage () {
        Object (activatable: true);
    }

    construct {
        title = _("Remote Desktop");
        icon = new ThemedIcon ("video-display");
        show_end_title_buttons = true;

        remote_desktop = new Backend.RemoteDesktopManager ();

        var control_switch = new Gtk.Switch () {
            halign = START,
            valign = CENTER
        };

        var control_label = new Gtk.Label (_("Remote Control")) {
            halign = END,
            mnemonic_widget = control_switch,
            tooltip_text = _("Allow connected devices to control this computer")
        };

        var device_name_entry = new Gtk.Entry () {
            editable = false,
            can_focus = false,
            text = Environment.get_host_name (),
            width_chars = 28
        };

        var device_name_label = new Gtk.Label (_("Device Name")) {
            halign = END,
            mnemonic_widget = device_name_entry
        };

        rdp_url_entry = new Gtk.Entry () {
            editable = false,
            width_chars = 28
        };

        var rdp_url_label = new Gtk.Label (_("RDP URL")) {
            halign = END,
            mnemonic_widget = rdp_url_entry
        };

        username_entry = new Gtk.Entry () {
            width_chars = 28
        };

        var username_label = new Gtk.Label (_("User Name")) {
            halign = END,
            mnemonic_widget = username_entry
        };

        password_entry = new Gtk.PasswordEntry () {
            show_peek_icon = true,
            width_chars = 28
        };

        var password_label = new Gtk.Label (_("Password")) {
            halign = END,
            mnemonic_widget = password_entry
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            halign = CENTER,
            margin_top = 24
        };
        grid.attach (control_label, 0, 0);
        grid.attach (control_switch, 1, 0);
        grid.attach (device_name_label, 0, 1);
        grid.attach (device_name_entry, 1, 1);
        grid.attach (rdp_url_label, 0, 2);
        grid.attach (rdp_url_entry, 1, 2);
        grid.attach (username_label, 0, 3);
        grid.attach (username_entry, 1, 3);
        grid.attach (password_label, 0, 4);
        grid.attach (password_entry, 1, 4);

        child = grid;

        var network_button = add_button (_("Network Settings…"));
        network_button.clicked.connect (() => {
            var uri_launcher = new Gtk.UriLauncher ("settings://network");
            uri_launcher.launch.begin (((Gtk.Application) Application.get_default ()).active_window, null);
        });

        var settings = remote_desktop.settings;
        settings.bind ("view-only", control_switch, "active", INVERT_BOOLEAN);
        settings.changed["port"].connect (update_address);
        settings.changed["enable"].connect (sync_switch);

        sync_switch ();

        status_switch.notify["active"].connect (() => {
            if (!syncing) {
                set_enabled.begin ();
            }
        });

        username_entry.changed.connect (queue_save_credentials);
        password_entry.changed.connect (queue_save_credentials);

        update_address ();
        load_credentials.begin ();
    }

    private async void set_enabled () {
        error_message = null;

        var enabled = status_switch.active;
        try {
            yield remote_desktop.set_enabled (enabled);
        } catch (Error e) {
            critical ("Unable to %s remote desktop: %s", enabled ? "enable" : "disable", e.message);
            error_message = e.message;
        }

        sync_switch ();
    }

    private void sync_switch () {
        syncing = true;
        status_switch.active = remote_desktop.settings.get_boolean ("enable");
        syncing = false;

        set_service_state ();
    }

    private async void load_credentials () {
        string? username, password;
        try {
            yield remote_desktop.get_credentials (out username, out password);
        } catch (Error e) {
            warning ("Unable to read remote desktop credentials: %s", e.message);
            return;
        }

        has_credentials = username != null && password != null;

        syncing = true;
        // Suggest the account name until other login details are saved
        username_entry.text = username ?? Environment.get_user_name ();
        password_entry.text = password ?? "";
        syncing = false;

        set_service_state ();
    }

    private void queue_save_credentials () {
        if (syncing) {
            return;
        }

        if (save_timeout_id != 0) {
            Source.remove (save_timeout_id);
        }

        save_timeout_id = Timeout.add (500, () => {
            save_timeout_id = 0;

            if (username_entry.text != "" && password_entry.text != "") {
                remote_desktop.set_credentials.begin (username_entry.text, password_entry.text, (obj, res) => {
                    try {
                        remote_desktop.set_credentials.end (res);
                        has_credentials = true;
                    } catch (Error e) {
                        critical ("Unable to save remote desktop credentials: %s", e.message);
                    }

                    set_service_state ();
                });
            }

            return Source.REMOVE;
        });
    }

    private void update_address () {
        var host = Environment.get_host_name ();
        var port = remote_desktop.get_port ();
        rdp_url_entry.text = port == DEFAULT_PORT ? "rdp://%s".printf (host) : "rdp://%s:%u".printf (host, port);
    }

    private void set_service_state () {
        if (error_message != null) {
            description = _("Remote Desktop settings could not be changed: %s").printf (error_message);
            status = _("Not Available");
            status_type = ERROR;
        } else if (remote_desktop.settings.get_boolean ("enable") && !has_credentials) {
            description = _("Set a user name and password below before connecting from another device.");
            status = _("Login Details Needed");
            status_type = WARNING;
        } else if (remote_desktop.settings.get_boolean ("enable")) {
            description = _("While enabled, other devices on the network can find and connect to this computer, and control it if allowed, after signing in.");
            status = _("Enabled");
            status_type = SUCCESS;
        } else {
            description = _("While disabled, this computer can not be found, viewed or controlled by other devices on the network.");
            status = _("Disabled");
            status_type = OFFLINE;
        }
    }
}
