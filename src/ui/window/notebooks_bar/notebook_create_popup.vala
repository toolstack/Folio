
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

	public NotebookCreatePopup (Window window, Notebook? notebook = null) {
		Object ();

        var model = new Gtk.SingleSelection (new Gtk.StringList ({
            "dialog-information-symbolic",
            "icon-food-symbolic",
            "icon-gaming-symbolic",
            "icon-music-symbolic",
            "icon-like-symbolic",
            "icon-heart-symbolic",
            "icon-star-symbolic",
            "icon-car-symbolic",
            "icon-travel-symbolic",
            "icon-home-symbolic",
            "icon-plus-symbolic",
            "icon-code-symbolic",
            "icon-settings-symbolic",
            "icon-science-symbolic",
            "icon-nature-symbolic",
            "icon-plant-symbolic",
            "icon-patch-symbolic",
            "icon-pin-symbolic",
            "icon-skull-symbolic",
            "icon-sport-symbolic",
            "icon-school-symbolic",
            "icon-work-symbolic",
            "icon-toki-symbolic",
            "icon-toki-pona-symbolic"
        }));

        model.selection_changed.connect (() => {
            var icon_name = (model.selected_item as Gtk.StringObject).string;
            button_icon.icon_name = icon_name;
            preview.icon_name = icon_name;
        });

        var factory = new Gtk.SignalListItemFactory ();

        factory.setup.connect (obj => (obj as Gtk.ListItem).child = new Gtk.Image ());
        factory.bind.connect (obj => {
            var list_item = obj as Gtk.ListItem;
            var icon_name = (list_item.item as Gtk.StringObject).string;
            (list_item.child as Gtk.Image).icon_name = icon_name;
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
		    entry.activate.connect (() => change (window, notebook));
            button_create.clicked.connect (() => change (window, notebook));
        } else {
	        icon_type_combobox.active = 0;
            entry.activate.connect (() => create (window));
            button_create.clicked.connect (() => create (window));
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
            recolor (button_color.rgba);
        });
        entry.changed ();
        icon_type_combobox.changed ();
        button_color.color_set ();

        model.selection_changed (0, 1);
	}

    private void create (Window window) {
        var info = preview.notebook_info;
	    close ();
	    window.try_create_notebook (info);
	}

	private void change (Window window, Notebook notebook) {
        var info = preview.notebook_info;
        close ();
        window.try_change_notebook (notebook, info);
    }

    private Gtk.CssProvider? last_css_provider = null;
	private void recolor (Gdk.RGBA color) {
        var rgba = Gdk.RGBA ();
        var light_rgba = Gdk.RGBA ();
        var rgb = Color.RGBA_to_rgb (color);
        var hsl = Color.rgb_to_hsl (rgb);
        {
            hsl.l = 0.5f;
            Color.hsl_to_rgb (hsl, out rgb);
            Color.rgb_to_RGBA (rgb, out rgba);
            hsl.l = 0.7f;
            Color.hsl_to_rgb (hsl, out rgb);
            Color.rgb_to_RGBA (rgb, out light_rgba);
        }
        if (last_css_provider != null) {
            entry.get_style_context ().remove_provider (last_css_provider);
            button_create.get_style_context ().remove_provider (last_css_provider);
        }
        var css = new Gtk.CssProvider ();
        css.load_from_data (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;".data);
        entry.get_style_context ().add_provider (css, -1);
        button_create.get_style_context ().add_provider (css, -1);
        last_css_provider = css;
	}
}
