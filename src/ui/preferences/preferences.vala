
[GtkTemplate (ui = "/com/toolstack/Folio/preferences.ui")]
public class Folio.PreferencesWindow : Adw.PreferencesDialog {
	public signal void three_pane_changed (bool is_three_pane);

	[GtkChild] unowned Gtk.FontDialogButton font_button;
	[GtkChild] unowned Gtk.FontDialogButton font_button_monospace;
	[GtkChild] unowned Gtk.Switch oled_mode;
	[GtkChild] unowned Adw.ComboRow url_detection_level;
	[GtkChild] unowned Gtk.Switch enable_toolbar;
	[GtkChild] unowned Gtk.Switch enable_cheatsheet;
	[GtkChild] unowned Gtk.Switch enable_3_pane;
	[GtkChild] unowned Gtk.Button notes_dir_button;
	[GtkChild] unowned Gtk.Button notes_dir_button_reset;
	[GtkChild] unowned Gtk.Label notes_dir_label;
	[GtkChild] unowned Gtk.Button trash_dir_button;
	[GtkChild] unowned Gtk.Button trash_dir_button_reset;
	[GtkChild] unowned Gtk.Label trash_dir_label;
	[GtkChild] unowned Gtk.Switch limit_note_width;
	[GtkChild] unowned Adw.SpinRow custom_note_width;
	[GtkChild] unowned Gtk.Switch show_line_numbers;
	[GtkChild] unowned Gtk.Switch show_all_notes;
	[GtkChild] unowned Gtk.Switch enable_autosave;
	[GtkChild] unowned Gtk.Switch disable_hidden_trash;
	[GtkChild] unowned Adw.ComboRow note_sort_order;
	[GtkChild] unowned Adw.ComboRow notebook_sort_order;
	[GtkChild] unowned Adw.ComboRow line_spacing;

	public PreferencesWindow (Application app, Gtk.Window window) {
		Object ();

		var settings = new Settings (Config.APP_ID);
		var font_dialog = new Gtk.FontDialog ();
		var font_desc = Pango.FontDescription.from_string (settings.get_string ("note-font"));

		font_dialog.set_title (Strings.PICK_NOTE_FONT);
		font_button.set_font_desc (font_desc);
		font_button.notify["font-desc"].connect (() => {
			var font = font_button.get_font_desc ().to_string ();
			settings.set_string ("note-font", font);
		});

		font_button.set_dialog (font_dialog);

		var font_dialog_monospace = new Gtk.FontDialog ();
		var font_desc_monospace = Pango.FontDescription.from_string (settings.get_string ("note-font-monospace"));
		var monospace_filter = new Folio.MonospaceFilter ();
		font_dialog_monospace.set_filter (monospace_filter);
		font_dialog_monospace.set_title (Strings.PICK_CODE_FONT);
		font_button_monospace.set_font_desc (font_desc_monospace);
		font_button_monospace.notify["font-desc"].connect (() => {
			var font = font_button_monospace.get_font_desc ().to_string ();
			settings.set_string ("note-font-monospace", font);
		});

		font_button_monospace.set_dialog (font_dialog_monospace);

		oled_mode.active = settings.get_boolean ("theme-oled");
		oled_mode.state_set.connect ((state) => {
			settings.set_boolean ("theme-oled", state);
			app.update_theme ();
			return false;
		});

		url_detection_level.model = new Gtk.StringList ({
			Strings.URL_DETECTION_AGGRESSIVE,
			Strings.URL_DETECTION_STRICT,
			Strings.URL_DETECTION_DISABLED
			});
		var selected_url_detection_level = settings.get_int ("url-detection-level");
		url_detection_level.set_selected ((int)selected_url_detection_level);
        url_detection_level.notify["selected-item"].connect (() => {
            settings.set_int ("url-detection-level", (int)url_detection_level.get_selected ());
        });

		line_spacing.model = new Gtk.StringList ({
			"1.0",
			"1.5",
			"2.0"
			});
		line_spacing.set_selected (0);
		var line_spacing_setting = settings.get_string ("line-spacing");
		for (var i = 0; i < line_spacing.model.get_n_items (); i++) {
			if( ((Gtk.StringList)line_spacing.model).get_string (i) == line_spacing_setting ) {
					line_spacing.set_selected (i);
			}
		}
        line_spacing.notify["selected-item"].connect (() => {
			for (var i = 0; i < line_spacing.model.get_n_items (); i++) {
				if( (int)line_spacing.get_selected () == i ) {
			        	settings.set_string ("line-spacing", ((Gtk.StringList)line_spacing.model).get_string (i));
				}
			}
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
			three_pane_changed (state);
			return false;
		});

		show_line_numbers.active = settings.get_boolean ("show-line-numbers");
		show_line_numbers.state_set.connect ((state) => {
			settings.set_boolean ("show-line-numbers", state);
			return false;
		});

		show_all_notes.active = settings.get_boolean ("show-all-notes");
		show_all_notes.state_set.connect ((state) => {
			settings.set_boolean ("show-all-notes", state);
			return false;
		});

		enable_autosave.active = settings.get_boolean ("enable-autosave");
		enable_autosave.state_set.connect ((state) => {
			settings.set_boolean ("enable-autosave", state);
			return false;
		});

		disable_hidden_trash.active = settings.get_boolean ("disable-hidden-trash");
		disable_hidden_trash.state_set.connect ((state) => {
			settings.set_boolean ("disable-hidden-trash", state);
			return false;
		});

		limit_note_width.active = settings.get_int ("note-max-width") != -1;
		limit_note_width.state_set.connect ((state) => {
			settings.set_int ("note-max-width", state ? 720 : -1);
			custom_note_width.set_sensitive (state);
			return false;
		});

		int note_width = settings.get_int ("note-max-width");
		if (note_width == -1 ) {
			custom_note_width.set_sensitive (false);
			note_width = 720;
		}

		var width_adjustment = new Gtk.Adjustment (note_width, 100, 2000, 1.0, 100.0, 1.0);
		custom_note_width.set_adjustment (width_adjustment);
        custom_note_width.notify["value"].connect (() => {
			if (limit_note_width.active) {
                settings.set_int ("note-max-width", (int) custom_note_width.value);
			}
        });

		var notes_dir = settings.get_string ("notes-dir");
		notes_dir_label.label = settings.get_string ("notes-dir");
		notes_dir_label.tooltip_text = notes_dir;
		notes_dir_button.clicked.connect (() => {
			var chooser = new Gtk.FileDialog ();
			chooser.set_modal (true);
			chooser.set_title (Strings.PICK_NOTES_DIR);
			chooser.set_initial_folder (File.new_for_path (notes_dir));
			chooser.select_folder.begin (window, null, (obj, res) => {
                try {
                    var folder = chooser.select_folder.end(res);
					if (folder.query_exists ()) {
						notes_dir = folder.get_path ();
						settings.set_string ("notes-dir", notes_dir);
						notes_dir_label.label = notes_dir;
						notes_dir_label.tooltip_text = notes_dir;
					}
                } catch (Error error) {}
            });
		});
		notes_dir_button_reset.clicked.connect (() => {
			settings.reset ("notes-dir");
			notes_dir = settings.get_string ("notes-dir");
			notes_dir_label.label = notes_dir;
			notes_dir_label.tooltip_text = notes_dir;
		});

		var trash_dir = settings.get_string ("trash-dir");
		trash_dir_label.label = settings.get_string ("trash-dir");
		trash_dir_label.tooltip_text = notes_dir;
		trash_dir_button.clicked.connect (() => {
			var chooser = new Gtk.FileDialog ();
			chooser.set_modal (true);
			chooser.set_title (Strings.PICK_TRASH_DIR);
			chooser.set_initial_folder (File.new_for_path (trash_dir));
			chooser.select_folder.begin (window, null, (obj, res) => {
                try {
                    var folder = chooser.select_folder.end(res);
					if (folder.query_exists ()) {
						trash_dir = folder.get_path ();
						settings.set_string ("trash-dir", trash_dir);
						trash_dir_label.label = trash_dir;
						trash_dir_label.tooltip_text = trash_dir;
					}
                } catch (Error error) {}
            });
		});
		trash_dir_button_reset.clicked.connect (() => {
			settings.reset ("trash-dir");
			trash_dir = settings.get_string ("trash-dir");
			trash_dir_label.label = trash_dir;
			trash_dir_label.tooltip_text = trash_dir;
		});

		note_sort_order.model = new Gtk.StringList ({
			Strings.NOTE_SORT_ORDER_TIME_DSC,
			Strings.NOTE_SORT_ORDER_TIME_ASC,
			Strings.NOTE_SORT_ORDER_ALPHA_ASC,
			Strings.NOTE_SORT_ORDER_ALPHA_DSC,
			Strings.NOTE_SORT_ORDER_NATURAL_ASC,
			Strings.NOTE_SORT_ORDER_NATURAL_DSC
			});
		var selected_sort_order = settings.get_int ("note-sort-order");
		note_sort_order.set_selected ((int)selected_sort_order);
        note_sort_order.notify["selected-item"].connect (() => {
            settings.set_int ("note-sort-order", (int)note_sort_order.get_selected ());
        });

		notebook_sort_order.model = note_sort_order.model;
		selected_sort_order = settings.get_int ("notebook-sort-order");
		notebook_sort_order.set_selected ((int)selected_sort_order);
        notebook_sort_order.notify["selected-item"].connect (() => {
            settings.set_int ("notebook-sort-order", (int)notebook_sort_order.get_selected ());
        });

 		this.three_pane_changed.connect (((Folio.Window) window).on_3_pane_change);
	}
}

public class Folio.MonospaceFilter : Gtk.Filter {
	public override bool match (GLib.Object? item) {
		var font = item as Pango.FontFace;
		var family = font.get_family ();
		return family.is_monospace ();
	}
 }
