
[GtkTemplate (ui = "/io/posidon/Paper/notebook_sidebar/note_menu.ui")]
public class Paper.NoteMenuPopover : Gtk.Popover {

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

	public NoteMenuPopover (Application app, Note note, bool is_in_trash) {
	    if (is_in_trash) {
	        button_edit.visible = false;
	        button_trash.visible = false;
	        button_move.visible = false;
            button_recover.clicked.connect (() => {
                popdown ();
                app.try_restore_note (note);
            });
            button_delete.clicked.connect (() => {
                popdown ();
                app.request_delete_note (note);
            });
	    } else {
	        button_recover.visible = false;
	        button_delete.visible = false;
            button_move.clicked.connect (() => {
                popdown ();
                app.request_move_note (note);
            });
            button_edit.clicked.connect (() => {
                popdown ();
                app.request_edit_note (note);
            });
            button_trash.clicked.connect (() => {
                popdown ();
                app.try_delete_note (note);
            });
	    }
	    button_open_containing_dir.clicked.connect (() => {
            popdown ();
	        var uri = File.new_for_path (note.notebook.path).get_uri ();
	        try {
	            AppInfo.launch_default_for_uri (uri, null);
	        } catch (Error e) {
	            app.window.toast ("Couldn't find an app to handle file uris");
	        }
	    });
	}
}
