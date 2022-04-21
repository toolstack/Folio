
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/notebook_menu.ui")]
public class Paper.NotebookMenuPopover : Gtk.Popover {

	[GtkChild]
	unowned Gtk.Button button_edit;

	[GtkChild]
	unowned Gtk.Button button_trash;

	public NotebookMenuPopover (Application app, Notebook notebook) {
        button_edit.clicked.connect (() => {
            popdown ();
            app.request_edit_notebook (notebook);
        });
        button_trash.clicked.connect (() => {
            popdown ();
            app.request_delete_notebook (notebook);
        });
	}
}
