/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 */

/*
 * Configures RDP screen sharing through gnome-remote-desktop. grdctl handles the
 * systemd user unit and the keyring, so we don't depend on libsecret ourselves.
 */
public class Sharing.Backend.RemoteDesktopManager : Object {
    private const string SCHEMA_ID = "org.gnome.desktop.remote-desktop.rdp";
    private const string GRDCTL = "grdctl";
    private const string OPENSSL = "openssl";

    public GLib.Settings? settings { get; private set; default = null; }

    public bool available {
        get {
            return settings != null;
        }
    }

    construct {
        if (is_supported ()) {
            settings = new GLib.Settings (SCHEMA_ID);
        }
    }

    /* Whether gnome-remote-desktop is installed */
    public static bool is_supported () {
        return SettingsSchemaSource.get_default ().lookup (SCHEMA_ID, true) != null
            && Environment.find_program_in_path (GRDCTL) != null;
    }

    public uint16 get_port () {
        return settings.get_value ("port").get_uint16 ();
    }

    /* Turns RDP on or off; grdctl starts and stops the user unit as needed */
    public async void set_enabled (bool enable) throws Error {
        if (enable) {
            yield ensure_tls_certificate ();
        }

        yield run_grdctl ({ "rdp", enable ? "enable" : "disable" });
    }

    public async void set_credentials (string username, string password) throws Error {
        // Pass the password on stdin so it doesn't show up in the process list
        yield run_grdctl ({ "rdp", "set-credentials", username }, password + "\n");
    }

    /* Reads the stored RDP login details, null when they haven't been set */
    public async void get_credentials (out string? username, out string? password) throws Error {
        username = null;
        password = null;

        var output = yield run_grdctl ({ "status", "--show-credentials" });

        var in_rdp_section = false;
        foreach (unowned var line in output.split ("\n")) {
            var stripped = line.strip ();
            if (!line.has_prefix ("\t")) {
                in_rdp_section = stripped == "RDP:";
            } else if (in_rdp_section && stripped.has_prefix ("Username: ")) {
                username = credential_value (stripped.substring ("Username: ".length));
            } else if (in_rdp_section && stripped.has_prefix ("Password: ")) {
                password = credential_value (stripped.substring ("Password: ".length));
            }
        }
    }

    private static string? credential_value (string value) {
        return value == "" || value == "(null)" || value == "(empty)" ? null : value;
    }

    /* gnome-remote-desktop refuses to start RDP without a TLS certificate and key */
    private async void ensure_tls_certificate () throws Error {
        var cert_path = settings.get_string ("tls-cert");
        var key_path = settings.get_string ("tls-key");
        if (
            cert_path != "" && FileUtils.test (cert_path, EXISTS) &&
            key_path != "" && FileUtils.test (key_path, EXISTS)
        ) {
            return;
        }

        // Same location GNOME Settings uses, so both share one certificate
        var dir = Path.build_filename (Environment.get_user_data_dir (), "gnome-remote-desktop");
        DirUtils.create_with_parents (dir, 0700);

        cert_path = Path.build_filename (dir, "rdp-tls.crt");
        key_path = Path.build_filename (dir, "rdp-tls.key");

        yield run ({
            OPENSSL, "req", "-new", "-x509", "-nodes",
            "-newkey", "rsa:4096",
            "-days", "720",
            "-subj", "/CN=%s".printf (Environment.get_host_name ()),
            "-out", cert_path,
            "-keyout", key_path
        });
        FileUtils.chmod (key_path, 0600);

        yield run_grdctl ({ "rdp", "set-tls-cert", cert_path });
        yield run_grdctl ({ "rdp", "set-tls-key", key_path });
    }

    private async string run_grdctl (string[] args, string? stdin_text = null) throws Error {
        string[] argv = { GRDCTL };
        foreach (unowned var arg in args) {
            argv += arg;
        }

        return yield run (argv, stdin_text);
    }

    private async string run (string[] argv, string? stdin_text = null) throws Error {
        var flags = SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE;
        if (stdin_text != null) {
            flags |= SubprocessFlags.STDIN_PIPE;
        }

        var launcher = new SubprocessLauncher (flags);
        // grdctl's output is parsed, keep it untranslated
        launcher.setenv ("LC_ALL", "C", true);

        var process = launcher.spawnv (argv);

        string stdout_text, stderr_text;
        yield process.communicate_utf8_async (stdin_text, null, out stdout_text, out stderr_text);

        if (!process.get_successful ()) {
            // grdctl prints usage errors on stdout
            var message = stderr_text.strip () != "" ? stderr_text.strip () : stdout_text.strip ();
            throw new IOError.FAILED ("%s %s failed: %s", argv[0], argv.length > 1 ? argv[1] : "", message);
        }

        return stdout_text;
    }
}
