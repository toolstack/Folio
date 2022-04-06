
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/icon.ui")]
public class Paper.NotebookIcon : NotebookPreview {

	public Notebook notebook {
	    get { return _notebook; }
	    set {
	        _notebook = value;
	        notebook_name = _notebook.name;
	        color = _notebook.color;
	    }
	}

    private Notebook _notebook;

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

	private Application app;
    private Gtk.Popover? current_popover = null;

	private void show_popup (double x, double y) {
	    if (current_popover != null) {
	        current_popover.popdown();
	    }
	    var popover = new NotebookMenuPopover (app, _notebook);
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
