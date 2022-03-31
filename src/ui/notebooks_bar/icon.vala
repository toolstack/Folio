
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/icon.ui")]
public class Paper.NotebookIcon : Gtk.Box {

	[GtkChild]
	unowned Gtk.Label label;


	public NotebookIcon (Application app) {
	    this.app = app;
	    var long_press = new Gtk.GestureLongPress ();
	    long_press.pressed.connect (show_popup);
	    add_controller (long_press);
	    var right_click = new Gtk.GestureClick ();
	    right_click.button = Gdk.BUTTON_SECONDARY;
	    right_click.pressed.connect ((n, x, y) => show_popup (x, y));
	    add_controller (right_click);
	}

	public void set_notebook (Notebook notebook) {
	    this.notebook = notebook;
	    label.label = notebook.name.slice (0, 2);
	    tooltip_text = notebook.name;

	    recolor (notebook);
	}

	private void recolor (Notebook notebook) {
        var fg_rgba = Gdk.RGBA ();
        {
            var rgb = Color.RGBA_to_rgb (notebook.color);
            var hsl = Color.rgb_to_hsl (rgb);
            var l = Color.get_luminance(rgb.r, rgb.g, rgb.b);
            var is_notebook_light = l > 0.7f;
            hsl.l = is_notebook_light ? 0.1f : 0.645f;
            hsl.s = 1.0f;
            var m = is_notebook_light ? 1.0f : 3.0f;
            Color.hsl_to_rgb (hsl, out rgb);
            fg_rgba.alpha = 1f;
            fg_rgba.red = rgb.r * m;
            fg_rgba.green = rgb.g * m;
            fg_rgba.blue = rgb.b * m;
        }
		var css = new Gtk.CssProvider ();
		css.load_from_data (@"@define-color notebook_color $(notebook.color);@define-color notebook_fg_color $fg_rgba;".data);
		get_style_context ().add_provider (css, -1);
	}

	private Notebook notebook;
	private Application app;
    private Gtk.Popover? current_popover = null;

	private void show_popup (double x, double y) {
	    if (current_popover != null) {
	        current_popover.popdown();
	    }
	    var popover = new NotebookMenuPopover (app, notebook);
	    popover.closed.connect (() => {
	        current_popover.unparent ();
	        current_popover = null;
	    });
	    popover.autohide = true;
	    popover.has_arrow = true;
        popover.position = Gtk.PositionType.RIGHT;
	    popover.set_parent (this);
	    popover.popup ();
	    current_popover = popover;
	}
}
