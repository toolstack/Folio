
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/popup/note_create_popup.ui")]
	public class NoteCreatePopup : Adw.Window {

		[GtkChild]
		unowned Gtk.Entry entry;

		[GtkChild]
		unowned Gtk.Button button_cancel;

		[GtkChild]
		unowned Gtk.Button button_create;

		public NoteCreatePopup (Application app, Note? note = null) {
			Object ();
			button_cancel.clicked.connect (close);

            if (note != null) {
			    button_create.clicked.connect (() => {
			        var name = entry.text;
			        close ();
			        app.try_change_note (note, name);
			    });
			} else button_create.clicked.connect (() => {
		        var name = entry.text;
		        close ();
		        app.try_create_note (name);
		    });
		}
	}
}
