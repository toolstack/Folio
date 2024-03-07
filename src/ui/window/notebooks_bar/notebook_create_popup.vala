
[GtkTemplate (ui = "/com/toolstack/Folio/notebooks_bar/create_popup.ui")]
public class Folio.NotebookCreatePopup : Adw.Window {

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

	[GtkChild]
	unowned Gtk.Label notebook_name_warning;

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
			var so = model.selected_item as Gtk.StringObject;
			if (so != null) {
				var icon_name = so.string;
				button_icon.icon_name = icon_name;
				preview.icon_name = icon_name;
			}
		});

		var factory = new Gtk.SignalListItemFactory ();

		factory.setup.connect (obj => {
			var li = obj as Gtk.ListItem;
			if (li != null) {
				li.child = new Gtk.Image ();
			}
		});
		factory.bind.connect (obj => {
			var list_item = obj as Gtk.ListItem;
			if (list_item != null) {
				var so = list_item.item as Gtk.StringObject;
				if (so != null) {
					var icon_name = so.string;
					var img = list_item.child as Gtk.Image;
					if (img != null) {
						img.icon_name = icon_name;
					}
				}
			}
		});

		icon_grid.model = model;
		icon_grid.factory = factory;

		// Setup a variable to use if we're editing a notebook name.
		var original_notebook_name = "";

		if (notebook != null) {
			original_notebook_name = notebook.name;
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
				var so = v as Gtk.StringObject;
				if (so != null) {
					if (so.string == notebook.info.icon_name) {
						model.set_selected (i);
						break;
					}
				}
			}
			entry.activate.connect (() => change (window, notebook));
			button_create.clicked.connect (() => change (window, notebook));
		} else {
			icon_type_combobox.active = 0;
			entry.activate.connect (() => create (window));
			button_create.clicked.connect (() => create (window));
			button_create.set_sensitive (false);
		}

		var settings = new Settings (Config.APP_ID);
		var path = settings.get_string ("notes-dir");
		var notes_dir = path.has_prefix ("~/") ? Environment.get_home_dir () + path[1:] : path;

		entry.changed.connect (() => {
			preview.notebook_name = entry.text;
			var file = File.new_for_path (notes_dir + "/" + entry.text);
			if (entry.text != "") {
				// If we're editing a notebook name, we can allow for that name to already exist.
				if (entry.text != original_notebook_name && file.query_exists ()) {
					notebook_name_warning.show ();
					button_create.set_sensitive (false);
				} else {
					notebook_name_warning.hide ();
					button_create.set_sensitive (true);
				}
			} else {
				notebook_name_warning.hide ();
				button_create.set_sensitive (false);
			}
		});
		icon_type_combobox.changed.connect (() => {
			preview.icon_type = NotebookIconType.from_int (icon_type_combobox.active);
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
