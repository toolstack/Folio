
[GtkTemplate (ui = "/com/toolstack/Folio/notebooks_bar/notebook_menu.ui")]
public class Folio.NotebookMenuPopover : Gtk.Popover {

	[GtkChild]
	unowned Gtk.Button button_edit;

	[GtkChild]
	unowned Gtk.Button button_trash;

	private Window window;
	private Notebook notebook;

	public NotebookMenuPopover (Window window, Notebook notebook) {
		this.window = window;
		this.notebook = notebook;

		button_edit.clicked.connect (on_button_edit_clicked);
		button_trash.clicked.connect (on_button_trash_clicked);
	}

	private void on_button_edit_clicked () {
		popdown ();
		window.request_edit_notebook (notebook);
	}

	private void on_button_trash_clicked () {
		popdown ();
		window.request_delete_notebook (notebook);
	}
}
