/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2023 elementary, Inc. (https://elementary.io)
 */

public class Sharing.Plug : Switchboard.Plug {
    private Gtk.Stack? content = null;

    public Plug () {
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("network/share", null);
        Object (category : Category.NETWORK,
                code_name: "io.elementary.settings.sharing",
                display_name: _("Sharing"),
                description: _("Configure file and media sharing"),
                icon: "preferences-system-sharing",
                supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (content == null) {
            var network_alert_view = new Granite.Placeholder (
                _("Network Is Not Available")
            ) {
                icon = new ThemedIcon ("network-error"),
                description = _("While disconnected from the network, sharing services are not available."),
                vexpand = true,
                hexpand = true
            };
            network_alert_view.remove_css_class (Granite.STYLE_CLASS_VIEW);

            var link_button = new Gtk.LinkButton.with_label ("settings://network", _("Network settings…"));
            link_button.halign = Gtk.Align.END;
            link_button.valign = Gtk.Align.END;

            var network_grid_view = new Gtk.Grid () {
                margin_top = 12,
                margin_end = 12,
                margin_start = 12,
                margin_bottom = 12
            };
            network_grid_view.attach (network_alert_view, 0, 0, 1, 1);
            network_grid_view.attach (link_button, 0, 1, 1, 1);

            var headerbar = new Adw.HeaderBar () {
                show_title = false,
                show_end_title_buttons = true,
                show_start_title_buttons = true
            };

            var toolbarview = new Adw.ToolbarView () {
                content = network_grid_view,
                top_bar_style = FLAT
            };
            toolbarview.add_top_bar (headerbar);

            var dlna_page = new Widgets.DLNAPage ();
            var bluetooth_page = new Widgets.BluetoothPage ();

            var settings_view = new Gtk.Stack ();
            settings_view.add_child (dlna_page);
            settings_view.add_child (bluetooth_page);

            // Only offered when GNOME Remote Desktop is installed
            if (Backend.RemoteDesktopManager.is_supported ()) {
                settings_view.add_child (new Widgets.RemoteDesktopPage ());
            }

            var sidebar = new Switchboard.SettingsSidebar (settings_view) {
                show_title_buttons = true
            };

            var main_container = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
                start_child = sidebar,
                end_child = settings_view,
                resize_start_child = false,
                shrink_end_child = false,
                shrink_start_child = false
            };

            var sss = SettingsSchemaSource.get_default ().lookup ("io.elementary.settings", true);
            if (sss != null && sss.has_key ("sidebar-position")) {
                var settings = new Settings ("io.elementary.settings");
                settings.bind ("sidebar-position", main_container, "position", DEFAULT);
            }

            content = new Gtk.Stack ();
            content.add_named (main_container, "main-container");
            content.add_named (toolbarview, "network-alert-view");

            NetworkMonitor.get_default ().network_changed.connect (() => update_content_view ());

            update_content_view ();
        }

        return content;
    }

    public override void shown () {
    }

    public override void hidden () {
    }

    public override void search_callback (string location) {
    }

    /* 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior") */
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Media Streaming")), "");
        search_results.set ("%s → %s".printf (display_name, _("DLNA and UPnP")), "");
        search_results.set ("%s → %s".printf (display_name, _("Bluetooth")), "");
        if (Backend.RemoteDesktopManager.is_supported ()) {
            search_results.set ("%s → %s".printf (display_name, _("Remote Desktop")), "");
            search_results.set ("%s → %s".printf (display_name, _("RDP")), "");
        }
        return search_results;
    }

    private void update_content_view () {
        if (NetworkMonitor.get_default ().get_network_available () || NetworkMonitor.get_default ().get_network_metered ()) {
            content.visible_child_name = "main-container";
        } else {
            content.visible_child_name = "network-alert-view";
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Sharing plug");

    var plug = new Sharing.Plug ();

    return plug;
}
