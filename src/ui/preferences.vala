
[GtkTemplate (ui = "/io/posidon/Paper/preferences.ui")]
public class Paper.PreferencesWindow : Adw.PreferencesWindow {

	[GtkChild]
	unowned Gtk.FontButton font_button;


	public PreferencesWindow () {
		Object ();

	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");

        font_button.level = Gtk.FontChooserLevel.FEATURES;
        font_button.font = note_font;
        font_button.font_set.connect (
            () => settings.set_string ("note-font", font_button.get_font_family ().get_name ())
        );
	}
}
