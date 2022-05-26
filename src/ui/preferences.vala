
[GtkTemplate (ui = "/io/posidon/Paper/preferences.ui")]
public class Paper.PreferencesWindow : Adw.PreferencesWindow {

	[GtkChild]
	unowned Gtk.FontButton font_button;

	[GtkChild]
	unowned Gtk.Switch oled_mode;

	[GtkChild]
	unowned Gtk.Button notes_dir_button;


	public PreferencesWindow (Window window) {
		Object ();

	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");
		var theme_oled = settings.get_boolean ("theme-oled");
		var notes_dir = settings.get_string ("notes-dir");

        font_button.level = Gtk.FontChooserLevel.FEATURES;
        font_button.font = note_font;
        font_button.font_set.connect (() => {
            settings.set_string ("note-font", font_button.get_font_family ().get_name ());
        });

        oled_mode.state = theme_oled;
        oled_mode.state_set.connect ((state) => {
            settings.set_boolean ("theme-oled", state);
            var app = (window.application as Adw.Application);
            window.update_theme (app.style_manager.dark, app.style_manager.high_contrast);
            return false;
        });

        notes_dir_button.label = notes_dir;
        notes_dir_button.clicked.connect (() => {
            var chooser = new Gtk.FileChooserDialog (
                Strings.PICK_NOTES_DIR,
                this,
                Gtk.FileChooserAction.SELECT_FOLDER,
                Strings.APPLY, 1
            );
            chooser.modal = true;
            chooser.set_current_folder (File.new_for_path (notes_dir));
            var h = chooser.get_header_bar();
            h.show_title_buttons = false;
            var button_cancel = new Gtk.Button.with_label (Strings.CANCEL);
            button_cancel.clicked.connect (() => chooser.close ());
            h.pack_start (button_cancel);
            chooser.get_widget_for_response (1).get_style_context ().add_class ("suggested-action");
            chooser.response.connect ((id) => {
                if (id == 1) {
                    notes_dir = chooser.get_current_folder ().get_path ();
		            settings.set_string ("notes-dir", notes_dir);
                    notes_dir_button.label = notes_dir;
                }
                chooser.close ();
            });
            chooser.present ();
        });
	}
}
