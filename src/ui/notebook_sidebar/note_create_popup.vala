
[GtkTemplate (ui = "/io/posidon/Paper/notebook_sidebar/create_popup.ui")]
public class Paper.NoteCreatePopup : Adw.Window {

	[GtkChild]
	unowned Gtk.Entry entry;

	[GtkChild]
	unowned Gtk.Button button_create;

	public NoteCreatePopup (Application app, Note? note = null) {
		Object ();

        if (note != null) {
            button_create.label = Strings.RENAME;
            entry.text = note.name;
		    entry.activate.connect (() => change (app, note));
		    button_create.clicked.connect (() => change (app, note));
		} else {
		    entry.activate.connect (() => create (app));
		    button_create.clicked.connect (() => create (app));
	    }
	}

	private void create (Application app) {
        var name = entry.text;
        close ();
        app.try_create_note (name);
    }

	private void change (Application app, Note note) {
        var name = entry.text;
        close ();
        app.try_change_note (note, name);
    }
}
