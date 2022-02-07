
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/note_card.ui")]
	public class NoteCard : Gtk.Box {

		[GtkChild]
		unowned Gtk.Label label;

		[GtkChild]
		unowned Gtk.Label subtitle;

		private bool is_in_trash;

		public NoteCard (bool is_in_trash) {
		    this.is_in_trash = is_in_trash;
		    subtitle.visible = is_in_trash;
		    var long_press = new Gtk.GestureLongPress ();
		    long_press.pressed.connect (show_popup);
		    add_controller (long_press);
		    var right_click = new Gtk.GestureClick ();
		    right_click.button = Gdk.BUTTON_SECONDARY;
		    right_click.pressed.connect ((n, x, y) => show_popup (x, y));
		    add_controller (right_click);
		}

		public void set_window (Window window) {
		    this.window = window;
		}

		public void set_note (Note note) {
		    this.note = note;
		    label.label = note.name;
		    subtitle.label = note.notebook.name;
		    tooltip_text = note.name;
		}

		private Window window;
		private Note note;
        private Gtk.Popover? current_popover = null;

		private void show_popup (double x, double y) {
		    if (current_popover != null) {
		        current_popover.popdown();
		    }
		    var popover = new NoteMenuPopover (get_app (), note, is_in_trash);
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
		    return (Application) window.application;
		}
	}
}
