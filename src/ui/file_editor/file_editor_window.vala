
[GtkTemplate (ui = "/com/toolstack/Folio/file_editor_window.ui")]
public class Folio.FileEditorWindow : Adw.ApplicationWindow {

	[GtkChild] unowned Gtk.Label file_title;
	[GtkChild] unowned Gtk.Label file_subtitle;
	[GtkChild] unowned Gtk.Label save_indicator;

	[GtkChild] unowned Adw.HeaderBar headerbar;

	[GtkChild] unowned EditView edit_view;
	[GtkChild] unowned Adw.ToastOverlay toast_overlay;

	private ActionEntry[] ACTIONS = {
		{ "format-bold", on_format_bold },
		{ "format-italic", on_format_italic },
		{ "format-strikethrough", on_format_strikethrough },
		{ "format-highlight", on_format_highlight },

		{ "insert-link", on_insert_link },
		{ "insert-code-span", on_insert_code_span },
		{ "insert-horizontal-rule", on_insert_horizontal_rule },

		{ "save-note", save },
		{ "toggle-fullscreen", toggle_fullscreen },
	};

	private GtkMarkdown.Buffer current_buffer;
	private File current_file;
	private Application app;

	construct {
		add_action_entries (ACTIONS, this);

		Gtk.IconTheme.get_for_display (display).add_resource_path ("/com/toolstack/Folio/graphics/");
	}

	public FileEditorWindow (Application app, File file) {
		Object (
			application: app,
			title: @"$(file.get_basename ()) ($(file.get_path ())) - $(Strings.APP_NAME)",
			icon_name: Config.APP_ID
		);

		this.app = app;

		current_file = file;
		edit_view.on_dark_changed(app.style_manager.dark);
		app.style_manager.notify["dark"].connect (on_style_manager_change);

		file_title.label = file.get_basename ();
		file_subtitle.label = file.get_path ();

		string etag_out;
		uint8[] text_data = {};
		try {
			file.load_contents (null, out text_data, out etag_out);
		} catch (Error e) {
			// Probably need to do something else here...
			return;
		}
		// Make sure the last character of the file is a return, otherwise some of the regex's will break.
		current_buffer = new GtkMarkdown.Buffer ((string) text_data);
		edit_view.buffer = current_buffer;
		edit_view.is_editable = true;

		close_request.connect (on_close_request);

		edit_view.scrolled_window.vadjustment.notify["value"].connect (on_scrolled_window_vadjustment_changed);

		recolor (Color.RGB ());

		current_buffer.begin_user_action.connect (on_begin_user_action_change);

		save_indicator.visible = false;
	}

	private void on_begin_user_action_change () {
		save_indicator.visible = true;
	}

	private void on_scrolled_window_vadjustment_changed () {
		var v = edit_view.scrolled_window.vadjustment.value;
		if (v == 0) headerbar.remove_css_class ("overlaid");
		else headerbar.add_css_class ("overlaid");
	}

	private void on_style_manager_change () {
		edit_view.on_dark_changed(app.style_manager.dark);
	}

	private bool on_close_request () {
		save_file ();
		return false;
	}

	public void save_file () {
		FileUtils.save_to (current_file, current_buffer.get_all_text ());
	}

	public void save () {
		save_file ();
		save_indicator.visible = false;
	}

	public void toast (string text) {
		var toast = new Adw.Toast (text);
		toast_overlay.add_toast (toast);
	}

	private void recolor (Color.RGB rgb) {
		var rgba = Gdk.RGBA ();
		var light_rgba = Gdk.RGBA ();
		var hsl = Color.rgb_to_hsl (rgb);
		{
			hsl.l = 0.5f;
			Color.hsl_to_rgb (hsl, out rgb);
			Color.rgb_to_RGBA (rgb, out rgba);
			hsl.l = 0.7f;
			Color.hsl_to_rgb (hsl, out rgb);
			Color.rgb_to_RGBA (rgb, out light_rgba);
		}
		var css = new Gtk.CssProvider ();
		css.load_from_string (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;");
		get_style_context ().add_provider (css, -1);
		edit_view.theme_color = rgba;
	}

	private void toggle_fullscreen () {
		fullscreened = !fullscreened;
	}

	private void on_format_bold () { edit_view.format_selection_bold (); }
	private void on_format_italic () { edit_view.format_selection_italic (); }
	private void on_format_strikethrough () { edit_view.format_selection_strikethrough (); }
	private void on_format_highlight () { edit_view.format_selection_highlight (); }
	private void on_insert_link () { edit_view.insert_link (); }
	private void on_insert_code_span () { edit_view.insert_code_span (); }
	private void on_insert_horizontal_rule () { edit_view.insert_horizontal_rule (); }
}
