
[GtkTemplate (ui = "/com/toolstack/Folio/toolbar.ui")]
public class Folio.Toolbar : Gtk.Box {

	public bool compacted {
		get { return small_toolbar.visible; }
	}

	public int heading_i { get; set; }

	public bool cheatsheet_enabled { get; set; }

	public signal void heading_i_changed (int i);

	[GtkChild] unowned Gtk.Box regular_toolbar;
	[GtkChild] unowned Gtk.Box small_toolbar;
	[GtkChild] unowned Gtk.Box squeezer;
	[GtkChild] unowned Gtk.DropDown format_heading_type;
	[GtkChild] unowned Gtk.DropDown format_heading_type_mobile;

	construct {
		notify["heading-i"].connect (() => {
			format_heading_type.set_selected (heading_i);
			format_heading_type_mobile.set_selected (heading_i);
		});
		format_heading_type.set_selected (heading_i);
		format_heading_type_mobile.set_selected (heading_i);
		format_heading_type.notify["selected-item"].connect (() => {
			heading_i_changed((int)format_heading_type.get_selected ());
		});
		format_heading_type_mobile.notify["selected-item"].connect (() => {
			heading_i_changed((int)format_heading_type_mobile.get_selected ());
		});
		var settings = new Settings (Config.APP_ID);
		settings.bind ("cheatsheet-enabled", this, "cheatsheet-enabled", SettingsBindFlags.DEFAULT);
	}

	public void resize_toolbar () {
		var width = squeezer.get_width ();

		if ( width < 500 && width > 0) {
			regular_toolbar.visible = false;
			small_toolbar.visible = true;
		} else {
			regular_toolbar.visible = true;
			small_toolbar.visible = false;
		}
	}
}
