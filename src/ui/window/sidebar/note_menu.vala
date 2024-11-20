
[GtkTemplate (ui = "/com/toolstack/Folio/sidebar/note_menu.ui")]
public class Folio.NoteMenuPopover : Gtk.Popover {

	[GtkChild]
	unowned Gtk.Button button_edit;

	[GtkChild]
	unowned Gtk.Button button_move;

	[GtkChild]
	unowned Gtk.Button button_recover;

	[GtkChild]
	unowned Gtk.Button button_trash;

	[GtkChild]
	unowned Gtk.Button button_delete;

	[GtkChild]
	unowned Gtk.Button button_open_containing_dir;

	private Window window;
	private Note note;

	public NoteMenuPopover (
		Window window,
		Note note,
		bool is_in_trash,
		Runnable rename
	) {
		this.window = window;
		this.note = note;

		if (is_in_trash) {
			button_edit.visible = false;
			button_trash.visible = false;
			button_move.visible = false;
			button_recover.clicked.connect (on_button_recover_clicked);
			button_delete.clicked.connect (on_button_delete_clicked);
		} else {
			button_recover.visible = false;
			button_delete.visible = false;
			button_move.clicked.connect (on_button_move_clicked);
			// We have to leave this lambda as Vala doesn't support copying the delegate rename function.
			button_edit.clicked.connect (() => {
				popdown ();
				rename ();
			});
			button_trash.clicked.connect (on_button_trash_clicked);
		}

		button_open_containing_dir.clicked.connect (on_button_open_containing_dir_clicked);
	}

	private void on_button_recover_clicked () {
		popdown ();
		window.try_restore_note (note);
	}

	private void on_button_delete_clicked () {
		popdown ();
		window.request_delete_note (note, true);
	}

	private void on_button_move_clicked () {
		popdown ();
		window.request_move_note (note);
	}

	private void on_button_trash_clicked () {
		popdown ();
		window.try_delete_note (note);
	}

	private void on_button_open_containing_dir_clicked () {
		popdown ();
		var uri = File.new_for_path (note.notebook.path).get_uri ();
		try {
			AppInfo.launch_default_for_uri (uri, null);
		} catch (Error e) {
			window.toast (Strings.COULDNT_FIND_APP_TO_HANDLE_URIS);
		}
	}
}
