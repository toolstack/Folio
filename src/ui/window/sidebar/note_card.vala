
[GtkTemplate (ui = "/io/posidon/Paper/sidebar/note_card.ui")]
public class Paper.NoteCard : Gtk.Box {

	public Window window { set { this._window = value; } }

	public Note note {
	    set {
	        this._note = value;
	        if (value != null) {
	            label.label = value.name;
	            var time_string = value.time_modified.format ("%e %b, %H:%m").strip ();
	            subtitle.label = _window.current_state == Window.State.NOTEBOOK ? time_string : @"%s - %s".printf (time_string, value.notebook.name);
	            tooltip_text = value.name;
                var v = Value (typeof (Note));
                v.set_object (value);
                drag_controller.content = new Gdk.ContentProvider.for_value (v);
	        }
	    }
	}

	[GtkChild] unowned Gtk.Label label;
	[GtkChild] unowned Gtk.Entry entry;
	[GtkChild] unowned Gtk.Button button_edit;
	[GtkChild] unowned Gtk.Button button_apply;
	[GtkChild] unowned Gtk.Label subtitle;

	private Gtk.DragSource drag_controller;

	private Window _window;
	private Note _note;
    private Gtk.Popover? current_popover = null;

	construct {
	    var long_press = new Gtk.GestureLongPress ();
	    long_press.pressed.connect (show_popup);
	    add_controller (long_press);
	    var right_click = new Gtk.GestureClick ();
	    right_click.button = Gdk.BUTTON_SECONDARY;
	    right_click.pressed.connect ((n, x, y) => show_popup (x, y));
	    add_controller (right_click);
	    drag_controller = new Gtk.DragSource ();
	    drag_controller.actions = Gdk.DragAction.MOVE;
	    drag_controller.drag_begin.connect ((drag) => {
	        get_style_context ().add_class ("dragged");
	        queue_draw ();
	        var paintable = new Gtk.WidgetPaintable (this);
	        drag_controller.set_icon (paintable, 0, 0);
	    });
	    drag_controller.drag_end.connect ((drag) => {
	        get_style_context ().remove_class ("dragged");
	    });
	    add_controller (drag_controller);

	    button_edit.clicked.connect (request_rename);
        var controller = new Gtk.EventControllerKey ();
        controller.key_pressed.connect ((keyval) => {
            if (keyval == Gdk.Key.Escape) {
                maybe_exit_rename ();
                return true;
            }
            return false;
        });
        add_controller (controller);
	}

	public void request_rename () {
        entry.buffer.set_text (_note.name.data);
        entry.visible = true;
        entry.grab_focus ();
        _window.notify["focus-widget"].connect (maybe_exit_rename);
        button_apply.clicked.connect (() => rename (entry.buffer.text));
        entry.activate.connect (() => rename (entry.buffer.text));
	}

	private void maybe_exit_rename () {
	    var focused = _window.focus_widget;
        if (focused == null
        ||  focused == label
        ||  focused == entry
        ||  focused == button_edit
        ||  focused == button_apply
        ||  focused == this
        ||  focused == parent
        ) return;
        exit_rename ();
	}

	private void exit_rename () {
        entry.visible = false;
        _window.notify["focus-widget"].disconnect (maybe_exit_rename);
	}

	private void rename (string name) {
        exit_rename ();
        if (get_app ().try_change_note (_note, name))
            note = _note;
	}

	private void show_popup (double x, double y) {
	    if (current_popover != null) {
	        current_popover.popdown();
	    }
	    var popover = new NoteMenuPopover (
	        get_app (),
	        _note,
	        _window.current_state == Window.State.TRASH,
	        request_rename
	    );
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

	private Application get_app () { return (Application) _window.application; }
}
