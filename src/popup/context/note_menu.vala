
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/popup/context/note_menu.ui")]
	public class NoteMenuPopover : Gtk.Popover {

		[GtkChild]
		unowned Gtk.Button button_edit;

		[GtkChild]
		unowned Gtk.Button button_delete;

		public NoteMenuPopover (Application app, Note note) {
            button_edit.clicked.connect (() => {
                popdown ();
                app.request_edit_note (note);
            });
            button_delete.clicked.connect (() => {
                popdown ();
                app.request_delete_note (note);
            });
		}
	}
}
