
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/create_popup.ui")]
public class Paper.NotebookCreatePopup : Adw.Window {

	[GtkChild]
	unowned Gtk.Entry entry;

	[GtkChild]
	unowned Gtk.ComboBox icon_type_combobox;

	[GtkChild]
	unowned Gtk.ColorButton button_color;

	[GtkChild]
	unowned Gtk.Button button_create;

	[GtkChild]
	unowned NotebookPreview preview;

	public NotebookCreatePopup (Application app, Notebook? notebook = null) {
		Object ();

        if (notebook != null) {
            button_create.label = Strings.APPLY;
	        button_color.rgba = notebook.color;
	        entry.text = notebook.name;
	        icon_type_combobox.active = notebook.icon_type;
		    entry.activate.connect (() => change (app, notebook));
            button_create.clicked.connect (() => change (app, notebook));
        } else {
	        icon_type_combobox.active = 0;
            entry.activate.connect (() => create (app));
            button_create.clicked.connect (() => create (app));
        }

        entry.changed.connect (() => {
            preview.notebook_name = entry.text;
        });
        icon_type_combobox.changed.connect (() => {
            preview.icon_type = icon_type_combobox.active;
        });
        button_color.color_set.connect (() => {
            preview.color = button_color.rgba;
        });
        entry.changed ();
        icon_type_combobox.changed ();
        button_color.color_set ();
	}

    private void create (Application app) {
	    var name = entry.text;
	    var color = button_color.rgba;
	    var icon_type = icon_type_combobox.active;
	    close ();
	    app.try_create_notebook (name, color, icon_type);
	}

	private void change (Application app, Notebook notebook) {
        var name = entry.text;
        var color = button_color.rgba;
	    var icon_type = icon_type_combobox.active;
        close ();
        app.try_change_notebook (notebook, name, color, icon_type);
    }
}
