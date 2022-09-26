
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/icon.ui")]
public class Paper.NotebookIcon : Gtk.Box {

	construct {
		accessible_role = Gtk.AccessibleRole.LABEL;
	}

	[GtkChild]
	private unowned NotebookPreview icon;

	public Notebook notebook {
	    get { return _notebook; }
	    set {
	        _notebook = value;
	        icon.notebook_info = notebook.info;
			update_property (Gtk.AccessibleProperty.LABEL, notebook.name, -1);
	    }
	}

    private Notebook _notebook;

	public NotebookIcon (Window window) {
	    this.window = window;
	    var long_press = new Gtk.GestureLongPress ();
	    long_press.pressed.connect (show_popup);
	    add_controller (long_press);
	    var right_click = new Gtk.GestureClick ();
	    right_click.button = Gdk.BUTTON_SECONDARY;
	    right_click.pressed.connect ((n, x, y) => show_popup (x, y));
	    add_controller (right_click);
	    var drop_target = new Gtk.DropTarget (typeof (Note), Gdk.DragAction.MOVE);
	    drop_target.preload = true;
	    drop_target.on_drop.connect ((v, x, y) => {
	        var note = v.get_object () as Note;
	        if (note.notebook == _notebook)
	            return false;
	        window.window_model.move_note (note, _notebook);
	        return true;
	    });
	    add_controller (drop_target);
	}

	private Window window;
    private Gtk.Popover? current_popover = null;

	private void show_popup (double x, double y) {
	    if (current_popover != null) {
	        current_popover.popdown();
	    }
	    var popover = new NotebookMenuPopover (window, _notebook);
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
