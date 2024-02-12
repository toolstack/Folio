
[GtkTemplate (ui = "/com/toolstack/Folio/preferences.ui")]
public class Folio.PreferencesWindow : Adw.PreferencesWindow {

	[GtkChild] unowned Gtk.FontButton font_button;
	[GtkChild] unowned Gtk.FontButton font_button_monospace;
	[GtkChild] unowned Gtk.Switch oled_mode;
	[GtkChild] unowned Gtk.Switch enable_toolbar;
	[GtkChild] unowned Gtk.Switch enable_cheatsheet;
	[GtkChild] unowned Gtk.Switch enable_3_pane;
	[GtkChild] unowned Gtk.Button notes_dir_button;
	[GtkChild] unowned Gtk.Button notes_dir_button_reset;
	[GtkChild] unowned Gtk.Label notes_dir_label;
	[GtkChild] unowned Gtk.Switch limit_note_width;

	public PreferencesWindow (Application app) {
		Object ();

	    var settings = new Settings (Config.APP_ID);

        font_button.font = settings.get_string ("note-font");
        font_button.font_set.connect (() => {
            var font = font_button.get_font_family ().get_name ();
            settings.set_string ("note-font", font);
        });

        font_button_monospace.font = settings.get_string ("note-font-monospace");
        font_button_monospace.set_filter_func ((family) => {
            return family.is_monospace ();
        });
        font_button_monospace.font_set.connect (() => {
            var font = font_button_monospace.get_font_family ().get_name ();
            settings.set_string ("note-font-monospace", font);
        });

        oled_mode.active = settings.get_boolean ("theme-oled");
        oled_mode.state_set.connect ((state) => {
            settings.set_boolean ("theme-oled", state);
            app.update_theme ();
            return false;
        });

        enable_toolbar.active = settings.get_boolean ("toolbar-enabled");
        enable_toolbar.state_set.connect ((state) => {
            settings.set_boolean ("toolbar-enabled", state);
            return false;
        });

        enable_cheatsheet.active = settings.get_boolean ("cheatsheet-enabled");
        enable_cheatsheet.state_set.connect ((state) => {
            settings.set_boolean ("cheatsheet-enabled", state);
            return false;
        });

        enable_3_pane.active = settings.get_boolean ("enable-3-pane");
        enable_3_pane.state_set.connect ((state) => {
            settings.set_boolean ("enable-3-pane", state);
            return false;
        });

        limit_note_width.active = settings.get_int ("note-max-width") != -1;
        limit_note_width.state_set.connect ((state) => {
            settings.set_int ("note-max-width", state ? 720 : -1);
            return false;
        });

		var notes_dir = settings.get_string ("notes-dir");
        notes_dir_label.label = settings.get_string ("notes-dir");
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
