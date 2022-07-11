
[GtkTemplate (ui = "/io/posidon/Paper/toolbar.ui")]
public class Paper.Toolbar : Gtk.Box {

	public bool compacted { get; set; }

	public int heading_i { get; set; }

	public signal void heading_i_changed (int i);

	[GtkChild]
	unowned Gtk.ComboBox format_heading_type;

	[GtkChild]
	unowned Gtk.ComboBox format_heading_type_mobile;

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
    }
}
