
[GtkTemplate (ui = "/com/toolstack/Folio/sidebar/create_popup.ui")]
public class Folio.NoteCreatePopup : Adw.Dialog {

	[GtkChild]
	unowned Gtk.Entry entry;

	[GtkChild]
	unowned Gtk.Button button_create;

	private Window window;
	private Note? note;

	public NoteCreatePopup (Window window, Note? note = null) {
		Object ();

		this.window = window;
		this.note = note;

		if (note != null) {
			button_create.label = Strings.RENAME;
			entry.text = note.name;
			entry.activate.connect (change);
			button_create.clicked.connect (change);
		} else {
			entry.activate.connect (create);
			button_create.clicked.connect (create);
		}
	}

	private void create () {
		var name = entry.text;
		close ();
		window.try_create_note (name);
	}

	private void change () {
		var file_name = entry.text;
		close ();
		window.try_rename_note (note, file_name);
	}
}
