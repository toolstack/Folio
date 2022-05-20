
[GtkTemplate (ui = "/io/posidon/Paper/file_editor_window.ui")]
public class Paper.FileEditorWindow : Adw.Window {

	[GtkChild]
	unowned Adw.WindowTitle file_title;

	[GtkChild]
	unowned Adw.HeaderBar headerbar;

	[GtkChild]
	public unowned EditView edit_view;

	[GtkChild]
	unowned Adw.ToastOverlay toast_overlay;

	public FileEditorWindow (Application app, File file) {
		Object (
		    application: app,
		    title: @"$(file.get_basename ()) ($(file.get_path ())) - $(Strings.APP_NAME)",
		    icon_name: Config.APP_ID
	    );

        Gtk.IconTheme.get_for_display (display).add_resource_path ("/io/posidon/Paper/graphics/");

        edit_view.on_dark_changed(app.style_manager.dark);
        app.style_manager.notify["dark"].connect (() => edit_view.on_dark_changed(app.style_manager.dark));

        file_title.title = file.get_basename ();
        file_title.subtitle = file.get_path ();

        string etag_out;
        uint8[] text_data = {};
        file.load_contents (null, out text_data, out etag_out);
        current_buffer = new GtkMarkdown.Buffer ((string) text_data);
        edit_view.buffer = current_buffer;

        close_request.connect (() => {
            save (file);
            return false;
        });

        edit_view.scrolled_window.vadjustment.notify["value"].connect (() => {
            var v = edit_view.scrolled_window.vadjustment.value;
            if (v == 0) headerbar.get_style_context ().remove_class ("overlaid");
            else headerbar.get_style_context ().add_class ("overlaid");
        });

        recolor (Color.RGB ());
	}

    private GtkMarkdown.Buffer current_buffer;

    public void save (File file) {
	    FileUtils.save_to (file, current_buffer.get_all_text ());
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
        css.load_from_data (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;".data);
        get_style_context ().add_provider (css, -1);
        edit_view.theme_color = rgba;
	}
}
