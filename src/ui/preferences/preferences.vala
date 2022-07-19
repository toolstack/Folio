
[GtkTemplate (ui = "/io/posidon/Paper/preferences.ui")]
public class Paper.PreferencesWindow : Adw.PreferencesWindow {

	[GtkChild]
	unowned Gtk.FontButton font_button;

	[GtkChild]
	unowned Gtk.Switch oled_mode;

	[GtkChild]
	unowned Gtk.Switch enable_toolbar;

	[GtkChild]
	unowned Gtk.Switch enable_3_pane;

	[GtkChild]
	unowned Gtk.Button notes_dir_button;

	[GtkChild]
	unowned Gtk.Button notes_dir_button_reset;

	[GtkChild]
	unowned Gtk.Label notes_dir_label;


	public PreferencesWindow (Application app, Window? window) {
		Object ();

	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");
		var theme_oled = settings.get_boolean ("theme-oled");
		var toolbar_enabled = settings.get_boolean ("toolbar-enabled");
		var is_3_pane_enabled = settings.get_boolean ("enable-3-pane");
		var notes_dir = settings.get_string ("notes-dir");

        font_button.level = Gtk.FontChooserLevel.FAMILY;
        font_button.font = note_font;
        font_button.font_set.connect (() => {
            var font = font_button.get_font_family ().get_name ();
            settings.set_string ("note-font", font);
            if (window != null)
                window.set_note_font (font);
        });

        oled_mode.state = theme_oled;
        oled_mode.state_set.connect ((state) => {
            settings.set_boolean ("theme-oled", state);
            app.update_theme ();
            return false;
        });

        enable_toolbar.state = toolbar_enabled;
        enable_toolbar.state_set.connect ((state) => {
            settings.set_boolean ("toolbar-enabled", state);
            return false;
        });

        enable_3_pane.state = is_3_pane_enabled;
        enable_3_pane.state_set.connect ((state) => {
            settings.set_boolean ("enable-3-pane", state);
            return false;
        });

        notes_dir_label.label = notes_dir;
        notes_dir_label.tooltip_text = notes_dir;
        notes_dir_button.clicked.connect (() => {
            var chooser = new Gtk.FileChooserNative (
                Strings.PICK_NOTES_DIR,
                this,
                Gtk.FileChooserAction.SELECT_FOLDER,
                Strings.APPLY,
                Strings.CANCEL
            );
            chooser.modal = true;
            chooser.set_file (File.new_for_path (notes_dir));
            chooser.response.connect ((id) => {
                if (id == Gtk.ResponseType.ACCEPT) {
                    notes_dir = chooser.get_file ().get_path ();
		            settings.set_string ("notes-dir", notes_dir);
                    notes_dir_label.label = notes_dir;
                    notes_dir_label.tooltip_text = notes_dir;
                }
            });
            chooser.show ();
        });
        notes_dir_button_reset.clicked.connect (() => {
            settings.reset ("notes-dir");
		    notes_dir = settings.get_string ("notes-dir");
            notes_dir_label.label = notes_dir;
            notes_dir_label.tooltip_text = notes_dir;
        });
	}
}
