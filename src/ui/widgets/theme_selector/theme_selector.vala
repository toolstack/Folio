
[GtkTemplate (ui = "/com/toolstack/Folio/theme_selector.ui")]
public class Folio.ThemeSelector : Gtk.Box {

	[GtkChild] unowned Gtk.CheckButton _auto;
	[GtkChild] unowned Gtk.CheckButton light;
	[GtkChild] unowned Gtk.CheckButton dark;

	private Settings settings;
	private Adw.StyleManager style_manager;

	construct {
		settings = new Settings (@"$(Config.APP_ID).Theme");
		style_manager = Adw.StyleManager.get_default ();

		switch (settings.get_enum ("variant")) {
			case Adw.ColorScheme.DEFAULT: _auto.active = true; break;
			case Adw.ColorScheme.FORCE_LIGHT: light.active = true; break;
			case Adw.ColorScheme.FORCE_DARK: dark.active = true; break;
		}

		_auto.toggled.connect (on_auto_changed);
		light.toggled.connect (on_light_changed);
		dark.toggled.connect (on_dark_changed);
	}

	private void on_auto_changed () {
		if (_auto.active) {
			settings.set_enum ("variant", Adw.ColorScheme.DEFAULT);
			style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
		}
	}

	private void on_light_changed () {
		if (light.active) {
			settings.set_enum ("variant", Adw.ColorScheme.FORCE_LIGHT);
			style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
		}
	}

	private void on_dark_changed () {
		if (dark.active) {
			settings.set_enum ("variant", Adw.ColorScheme.FORCE_DARK);
			style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
		}
	}
}
