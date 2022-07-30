
[GtkTemplate (ui = "/io/posidon/Paper/toolbar.ui")]
public class Paper.Toolbar : Gtk.Box {

	public bool compacted {
	    get { return squeezer.visible_child == small_toolbar; }
	}

	public int heading_i { get; set; }

	public bool cheatsheet_enabled { get; set; }

	public signal void heading_i_changed (int i);

    [GtkChild] unowned Gtk.Box small_toolbar;
    [GtkChild] unowned Adw.Squeezer squeezer;
	[GtkChild] unowned Gtk.ComboBox format_heading_type;
	[GtkChild] unowned Gtk.ComboBox format_heading_type_mobile;

    construct {
        notify["heading-i"].connect (() => {
            format_heading_type.active = heading_i;
            format_heading_type_mobile.active = heading_i;
        });
        format_heading_type.active = heading_i;
        format_heading_type_mobile.active = heading_i;
        format_heading_type.changed.connect (() => {
            heading_i_changed(format_heading_type.active);
        });
        format_heading_type_mobile.changed.connect (() => {
            heading_i_changed(format_heading_type_mobile.active);
        });
        var settings = new Settings (Config.APP_ID);
	    settings.bind ("cheatsheet-enabled", this, "cheatsheet-enabled", SettingsBindFlags.DEFAULT);
	    squeezer.notify["visible-child"].connect (() => notify_property ("compacted"));
    }
}
