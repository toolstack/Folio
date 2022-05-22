
[GtkTemplate (ui = "/io/posidon/Paper/notebook_sidebar/note_card.ui")]
public class Paper.NoteCard : Gtk.Box {

	[GtkChild]
	unowned Gtk.Label label;

	[GtkChild]
	unowned Gtk.Label subtitle;

	public NoteCard () {
	    var long_press = new Gtk.GestureLongPress ();
	    long_press.pressed.connect (show_popup);
	    add_controller (long_press);
	    var right_click = new Gtk.GestureClick ();
	    right_click.button = Gdk.BUTTON_SECONDARY;
	    right_click.pressed.connect ((n, x, y) => show_popup (x, y));
	    add_controller (right_click);
	}

	public Window window {
	    set {
	        this._window = value;
	    }
	}

	public Note note {
	    set {
	        this._note = value;
	        if (value != null) {
	            label.label = value.name;
	            var time_string = value.time_modified.format ("%e %b, %H:%m").strip ();
	            subtitle.label = _window.current_state == Window.State.NOTEBOOK ? time_string : @"%s - %s".printf (time_string, value.notebook.name);
	            tooltip_text = value.name;
	        }
	    }
	}

	private Window _window;
	private Note _note;
    private Gtk.Popover? current_popover = null;

	private void show_popup (double x, double y) {
	    if (current_popover != null) {
	        current_popover.popdown();
	    }
	    var popover = new NoteMenuPopover (get_app (), _note, _window.current_state == Window.State.TRASH);
	    popover.closed.connect (() => {
	        current_popover.unparent ();
	        current_popover = null;
	    });
	    popover.autohide = true;
	    popover.has_arrow = true;
        popover.position = Gtk.PositionType.TOP;
	    popover.set_parent (label);
	    popover.popup ();
	    current_popover = popover;
	}

	private Application get_app () {
	    return (Application) _window.application;
	}
}
