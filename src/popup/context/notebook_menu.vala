
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/popup/context/notebook_menu.ui")]
	public class NotebookMenuPopover : Gtk.Popover {

		[GtkChild]
		unowned Gtk.Button button_edit;

		[GtkChild]
		unowned Gtk.Button button_delete;

		public NotebookMenuPopover (Application app, Notebook notebook) {
            button_edit.clicked.connect (() => {
                popdown ();
                app.request_edit_notebook (notebook);
            });
            button_delete.clicked.connect (() => {
                popdown ();
                app.request_delete_notebook (notebook);
            });
		}
	}
}
