
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/popup/context/note_menu.ui")]
	public class NoteMenuPopover : Gtk.Popover {

		[GtkChild]
		unowned Gtk.Button button_edit;

		[GtkChild]
		unowned Gtk.Button button_recover;

		[GtkChild]
		unowned Gtk.Button button_delete;

		public NoteMenuPopover (Application app, Note note, bool is_in_trash) {
		    if (is_in_trash) {
		        button_edit.visible = false;
                button_recover.clicked.connect (() => {
                    popdown ();
                    app.try_restore_note (note);
                });
		    } else {
		        button_recover.visible = false;
                button_edit.clicked.connect (() => {
                    popdown ();
                    app.request_edit_note (note);
                });
		    }
            button_delete.clicked.connect (() => {
                popdown ();
                if (is_in_trash)
                    app.request_delete_note (note);
                else app.try_delete_note (note);
            });
		}
	}
}
