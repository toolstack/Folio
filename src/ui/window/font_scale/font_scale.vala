
[GtkTemplate (ui = "/com/toolstack/Folio/font_scale.ui")]
public class Folio.FontScale : Gtk.Box {

	[GtkChild] unowned Gtk.Button dec;
	[GtkChild] unowned Gtk.Button inc;
	[GtkChild] unowned Gtk.Label zoom_level;

	private EditView edit_view;

	construct {
		dec.clicked.connect(edit_view.zoom_out);
		inc.clicked.connect(edit_view.zoom_in);
	}

	public FontScale (EditView edit_view) {
		this.edit_view = edit_view;
		edit_view.notify["scale"].connect(update_scale);
		update_scale ();
	}

	private void update_scale () {
		zoom_level.label = edit_view.scale.to_string () + "%";
		dec.sensitive = edit_view.scale > EditView.MIN_SCALE;
		inc.sensitive = edit_view.scale < EditView.MAX_SCALE;
	}
}
