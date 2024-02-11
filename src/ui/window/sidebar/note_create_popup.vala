
[GtkTemplate (ui = "/com/toolstack/Folio/sidebar/create_popup.ui")]
public class Folio.NoteCreatePopup : Adw.Window {

	[GtkChild]
	unowned Gtk.Entry entry;

	[GtkChild]
	unowned Gtk.Button button_create;

	public NoteCreatePopup (Window window, Note? note = null) {
		Object ();

        if (note != null) {
            button_create.label = Strings.RENAME;
            entry.text = note.name;
		    entry.activate.connect (() => change (window, note));
		    button_create.clicked.connect (() => change (window, note));
		} else {
		    entry.activate.connect (() => create (window));
		    button_create.clicked.connect (() => create (window));
	    }
	}

	private void create (Window window) {
        var name = entry.text;
        close ();
        window.try_create_note (name);
    }

	private void change (Window window, Note note) {
        var file_name = entry.text;
        close ();
        window.try_rename_note (note, file_name);
    }
}
