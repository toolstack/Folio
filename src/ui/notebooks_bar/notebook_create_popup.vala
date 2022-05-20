
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/create_popup.ui")]
public class Paper.NotebookCreatePopup : Adw.Window {

	[GtkChild]
	unowned Gtk.Entry entry;

	[GtkChild]
	unowned Gtk.ComboBox icon_type_combobox;

	[GtkChild]
	unowned Gtk.ColorButton button_color;

	[GtkChild]
	unowned Gtk.MenuButton button_icon;

	[GtkChild]
	unowned Gtk.GridView icon_grid;

	[GtkChild]
	unowned Gtk.Button button_create;

	[GtkChild]
	unowned NotebookPreview preview;

	public NotebookCreatePopup (Application app, Notebook? notebook = null) {
		Object ();

        var model = new Gtk.SingleSelection (new Gtk.StringList ({
            "dialog-information-symbolic",
            "code-symbolic",
            "icon-heart-symbolic",
            "icon-music-symbolic",
            "icon-patch-symbolic",
            "icon-plant-symbolic",
            "icon-plus-symbolic",
            "icon-science-symbolic",
            "icon-skull-symbolic",
            "icon-toki-symbolic",
            "icon-toki-pona-symbolic"
        }));

        model.selection_changed.connect (() => {
            var icon_name = (model.selected_item as Gtk.StringObject).string;
            button_icon.icon_name = icon_name;
            preview.icon_name = icon_name;
        });

        var factory = new Gtk.SignalListItemFactory ();

        factory.setup.connect ((it) => it.child = new Gtk.Image ());
        factory.bind.connect ((it) => {
            var icon_name = (it.item as Gtk.StringObject).string;
            (it.child as Gtk.Image).icon_name = icon_name;
        });

        icon_grid.model = model;
        icon_grid.factory = factory;

        if (notebook != null) {
            button_create.label = Strings.APPLY;
            preview.notebook_info = new NotebookInfo (
                notebook.name,
                notebook.color,
                notebook.icon_type,
                notebook.info.icon_name
            );
	        button_color.rgba = notebook.color;
	        entry.text = notebook.name;
	        icon_type_combobox.active = notebook.icon_type;
	        for (uint i = 0; i < model.get_n_items (); i++) {
	            var v = model.get_item (i);
	            if ((v as Gtk.StringObject).string == notebook.info.icon_name) {
	                model.set_selected (i);
	                break;
	            }
	        }
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
            button_icon.visible = icon_type_combobox.active == NotebookIconType.PREDEFINED_ICON;
        });
        button_color.color_set.connect (() => {
            preview.color = button_color.rgba;
        });
        entry.changed ();
        icon_type_combobox.changed ();
        button_color.color_set ();

        model.selection_changed (0, 1);
	}

    private void create (Application app) {
        var info = preview.notebook_info;
	    close ();
	    app.try_create_notebook (info);
	}

	private void change (Application app, Notebook notebook) {
        var info = preview.notebook_info;
        close ();
        app.try_change_notebook (notebook, info);
    }
}
