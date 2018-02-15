/*
 * Copyright (c) 2011-2015 elementary Developers (https://launchpad.net/elementary)
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

public class Sharing.Widgets.SettingsView : Gtk.Stack {
    private Gee.HashMap<string, SettingsPage> settings_pages;

    construct {
        settings_pages = new Gee.HashMap<string, SettingsPage> ();
        DLNAPage dlna_page = new DLNAPage ();

        settings_pages.@set (dlna_page.id, dlna_page);

        this.add_named (dlna_page, dlna_page.id);
    }

    public SettingsPage[] get_settings_pages () {
        return settings_pages.values.to_array ();
    }

    public void show_service_settings (string service_id) {
        this.set_visible_child_name (service_id);
    }
}
