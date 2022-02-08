
namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/popup/notebook_create_popup.ui")]
	public class CreatePopup : Adw.Window {

		[GtkChild]
		unowned Gtk.Entry entry;

		[GtkChild]
		unowned Gtk.ColorButton button_color;

		[GtkChild]
		unowned Gtk.Button button_cancel;

		[GtkChild]
		unowned Gtk.Button button_create;

		public CreatePopup (Application app, Notebook? notebook = null) {
			Object ();
			button_cancel.clicked.connect (close);

            if (notebook != null) {
                button_create.label = "Apply";
		        button_color.rgba = notebook.color;
		        entry.text = notebook.name;
			    entry.activate.connect (() => change (app, notebook));
                button_create.clicked.connect (() => change (app, notebook));
            } else {
                entry.activate.connect (() => create (app));
                button_create.clicked.connect (() => create (app));
            }
		}

        private void create (Application app) {
		    var name = entry.text;
		    var color = button_color.rgba;
		    close ();
		    app.try_create_notebook (name, color);
		}

		private void change (Application app, Notebook notebook) {
            var name = entry.text;
            var color = button_color.rgba;
            close ();
            app.try_change_notebook (notebook, name, color);
        }
	}
}
