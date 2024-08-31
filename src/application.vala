/* application.vala
 *
 * Copyright 2022 Zagura
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Folio.Application : Adw.Application {

	private ActionEntry[] APP_ACTIONS = {
		{ "new-note", on_new_note },
		{ "edit-note", on_edit_note },
		{ "delete-note", on_delete_note },
		{ "export-note", on_export_note },

		{ "open-external-file", on_open_external_file },

		{ "new-notebook", on_new_notebook },
		{ "edit-notebook", on_edit_notebook },
		{ "delete-notebook", on_delete_notebook },

		{ "markdown-cheatsheet", on_markdown_cheatsheet },

		{ "empty-trash", on_empty_trash },

		{ "about", on_about_action },
		{ "preferences", on_preferences_action },
		{ "quit", on_quit_action }
	};

	private HashTable<string, Value?> temp_command;

	private Window? main_window = null;

	public WindowModel window_model { get { return main_window.window_model; } }

	private Gtk.CssProvider? black_css_provider = null;
	private Gtk.CssProvider? black_hc_css_provider = null;

	public Application () {
		Object (
			application_id: Config.APP_ID,
			flags: ApplicationFlags.HANDLES_COMMAND_LINE
		);

		add_action_entries (APP_ACTIONS, this);

		set_accels_for_action ("app.quit", {"<primary>q"});
		set_accels_for_action ("app.preferences", {"<primary>comma"});

		set_accels_for_action ("app.new-note", {"<primary>n"});
		set_accels_for_action ("app.new-notebook", {"<primary><shift>n"});

		set_accels_for_action ("app.edit-note", {"<primary>e"});
		set_accels_for_action ("app.edit-notebook", {"<primary><shift>e"});

		set_accels_for_action ("win.format-bold", {"<primary>b"});
		set_accels_for_action ("win.format-italic", {"<primary>i"});
		set_accels_for_action ("win.format-strikethrough", {"<primary>t"});
		set_accels_for_action ("win.format-highlight", {"<primary>h"});

		set_accels_for_action ("win.insert-link", {"<primary>k"});
		set_accels_for_action ("win.insert-horizontal-rule", {"<primary>Return"});

		set_accels_for_action ("win.toggle-sidebar", {"F9"});
		set_accels_for_action ("win.search-notes", {"<primary>f"});

		set_accels_for_action ("win.save-note", {"<primary>s"});
		set_accels_for_action ("win.toggle-fullscreen", { "F11" });
		set_accels_for_action ("win.zoom-out", { "<primary>minus"});
		set_accels_for_action ("win.zoom-in", { "<primary>plus"});
		set_accels_for_action ("win.zoom-out", { "<primary>KP_Add"});
		set_accels_for_action ("win.zoom-in", { "<primary>KP_Subtract"});

		command_line.connect (_command_line);

		{
			var settings = new Settings (@"$(Config.APP_ID).Theme");
			settings.bind ("variant", style_manager, "color-scheme", SettingsBindFlags.DEFAULT);
		}

		style_manager.notify["dark"].connect (() => update_theme ());
		style_manager.notify["high-contrast"].connect (() => update_theme ());
	}

	public override void activate () {
		base.activate ();
		var win = this.active_window;
		if (win == null) {
			main_window = new Window (this);
			win = main_window;
		}
		update_theme ();
		execute_temp_command ();
		win.present ();

		// Watch for the window to be resized and reset the toolbar.
		main_window.notify["default-width"].connect ((window) => {
			main_window.resize_toolbar ();
		});
		// Also watch for maximize/minimize events.
		main_window.notify["maximized"].connect ((window) => {
			// We have to add a delay here as the event fires before the resize happens.
			GLib.Timeout.add_once (100, () => { main_window.resize_toolbar (); });
		});

		// Add a delay before resizeing the toolbar for the first time as the window hasn't been
		// drawn yet.
		GLib.Timeout.add_once (100, () => { main_window.resize_toolbar (); });
	}

	private void execute_temp_command () {
		if (temp_command == null) return;
		bool exists;
		var _note = temp_command.take ("open-note", out exists);
		if (exists) {
			var note = _note.get_object () as Note;
			if (note != null) {
				window_model.open_note_in_notebook (window_model.note);
			}
			temp_command.remove ("open-note");
		}
		var query = temp_command.take ("launch-search", out exists);
		if (exists) {
			main_window.search_notes (query.get_string ());
			temp_command.remove ("launch-search");
		}
		temp_command = null;
	}

	private void on_about_action () {
		var about = new Adw.AboutWindow ();
		about.application_icon = Config.APP_ID;
		about.application_name = "Folio";
		about.developers = {"Greg Ross <greg@toolstack.com>", "Zagura"};
		about.translator_credits = """
Zagura <me@zagura.one>
Jan Krings <liquidsky42@gmail.com>
Jürgen Benvenuti <gastornis@posteo.org>
Sergio Varela <sergiovg01@outlook.com>
MohammadSaleh Kamyab <mskf1383@envs.net>
Iikka Hauhio <fergusq@kaivos.org>
Irénée Thirion <irenee.thirion@e.email>
Fran Dieguez <frandieguez@gnome.org>
Musiclover382 <musiclover382@protonmail.com>
Albano Battistella <albano_battistella@hotmail.com>
TokaiTeio
Gregory <gregorydk@proton.me>
Quentin PAGÈS
Marcin Wolski <martinwolski04@gmail.com>
Juliano Dorneles dos Santos <juliano.dorneles@gmail.com>
Марко М. Костић <marko.m.kostic@gmail.com>
Sabri Ünal <libreajans@gmail.com>
Mykyta Opanasiuk <nikitaopanassiuk@outlook.com>
Guoyi Zhang <guoyizhang@malacology.net>
rene-coty
""";
		about.translator_credits = about.translator_credits.chomp ().chug ();
		about.issue_url = "https://github.com/toolstack/Folio/issues";
		about.license_type = Gtk.License.GPL_3_0;
		about.version = Config.VERSION;
		about.website = "https://github.com/toolstack/Folio";
		about.transient_for = this.active_window;
		about.set_release_notes ("""
        <p>Changes:</p>
<ul>
	<li>Added a double click action on a note to rename the note</li>
	<li>Replace multiple deprecated GTK/Adwaita widgets/functions (build warnings down from 58 to 18)</li>
	<li>Switch to display names for files/folder system calls so cloud drive providers like Google work correctly</li>
	<li>Fix incorrect template display when the trash was empty</li>
	<li>Fix headerbar styling in edit window</li>
	<li>Fix inverted sorting for notebooks</li>
	<li>Other minor fixes</li>
</ul>
"""
		);
		about.present ();
	}

	private void on_preferences_action () {
		activate ();
		var w = new PreferencesWindow (this);
		w.destroy_with_parent = true;
		w.transient_for = active_window;
		w.modal = true;
		w.present ();
	}

	private void on_quit_action () {
		active_window.close_request ();
		quit ();
	}

	private void on_markdown_cheatsheet () {
		var w = new MarkdownCheatsheet (this);
		w.destroy_with_parent = true;
		w.transient_for = active_window;
		w.modal = true;
		w.present ();
	}

	private void on_empty_trash () {
		main_window.request_empty_trash ();
	}

	private void on_open_external_file () {
		try {
			GLib.AppInfo.launch_default_for_uri ("file://" + window_model.note.path, null);
		} catch (Error e) {
			toast (Strings.UNABLE_TO_LAUNCH_EXTERNAL_APPLICATION.printf (window_model.note.file_name));
		}
	}

	private void on_new_note () {
		activate ();
		if (window_model.notebook != null) {
			var buffer = window_model.current_buffer;
			var sel_name = "";
			if (buffer != null) {
				Gtk.TextIter start, end;
				if (buffer.get_selection_bounds (out start, out end) ) {
					sel_name = buffer.get_text (start, end, true);
				}
			}
			var name = window_model.generate_new_note_name (0, sel_name);
			main_window.try_create_note (name);
		} else {
			toast (Strings.CREATE_NOTEBOOK_BEFORE_CREATING_NOTE);
		}
	}

	private void on_edit_note () {
		if (window_model.note != null) {
			main_window.request_edit_note (window_model.note);
		} else {
			toast (Strings.SELECT_NOTE_TO_EDIT);
		}
	}

	private void on_delete_note () {
		if (window_model.note != null) {
			main_window.request_delete_note (window_model.note);
		} else {
			toast (Strings.SELECT_NOTE_TO_DELETE);
		}
	}

	private void on_export_note () {
		var chooser = new Gtk.FileDialog ();
		chooser.set_modal (true);
		chooser.set_title (Strings.EXPORT_NOTE);
		//chooser.set_initial_folder (File.new_for_path (trash_dir));
		chooser.save.begin (active_window, null, (obj, res) => {
			try {
				var file = chooser.save.end(res);
				if (file != null && window_model.note != null) {
					main_window.try_export_note (window_model.note, file);
				}
			} catch (Error error) {}
		});
	}

	private void on_new_notebook () {
		activate ();
		main_window.request_new_notebook ();
	}

	private void on_edit_notebook () {
		if (window_model.notebook == null) return;
		main_window.request_edit_notebook (window_model.notebook);
	}

	private void on_delete_notebook () {
		if (window_model.notebook == null) return;
		main_window.request_delete_notebook (window_model.notebook);
	}

	public void toast (string message) {
		main_window.toast (message);
	}

	public override void shutdown () {
		window_model.save_note (main_window);
		base.shutdown ();
	}

	public void update_theme () {
		if (active_window == null)
			return;
		var dark = style_manager.dark;
		var high_contrast = style_manager.high_contrast;
		var settings = new Settings (Config.APP_ID);
		var theme_oled = settings.get_boolean ("theme-oled");
		var display = active_window.display;
		if (display == null)
			return;
		if (dark && theme_oled) {
			if (black_css_provider == null) {
				var css = new Gtk.CssProvider ();
				css.load_from_resource (@"$resource_base_path/style-black.css");
				Gtk.StyleContext.add_provider_for_display (display, css, -1);
				black_css_provider = css;
			}
		}
		else {
			if (black_css_provider != null)
				Gtk.StyleContext.remove_provider_for_display (display, black_css_provider);
			black_css_provider = null;
		}
		if (dark && theme_oled && high_contrast) {
			if (black_hc_css_provider == null) {
				var css = new Gtk.CssProvider ();
				css.load_from_resource (@"$resource_base_path/style-black-hc.css");
				Gtk.StyleContext.add_provider_for_display (display, css, -1);
				black_hc_css_provider = css;
			}
		}
		else {
			if (black_hc_css_provider != null)
				Gtk.StyleContext.remove_provider_for_display (display, black_hc_css_provider);
			black_hc_css_provider = null;
		}
	}

	private int _command_line (ApplicationCommandLine command_line) {
		string? open_note = null;
		string? launch_search = null;
		string? file = null;

		OptionEntry[] options = {
			{ "open-note", 'n', 0, OptionArg.STRING, ref open_note, "Open a note", null },
			{ "launch-search", 's', 0, OptionArg.STRING, ref launch_search, "Search notes", null },
			{ "file", 'f', 0, OptionArg.FILENAME, ref file, "Edit file", null },
		};


		// We have to make an extra copy of the array, since .parse assumes
		// that it can remove strings from the array without freeing them.
		string[] args = command_line.get_arguments ();
		string*[] _args = new string[args.length];
		for (int i = 0; i < args.length; i++) {
			_args[i] = args[i];
		}

		try {
			var opt_context = new OptionContext ();
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			unowned string[] tmp = _args;
			opt_context.parse (ref tmp);
		} catch (OptionError e) {
			command_line.print ("error: %s\n", e.message);
			command_line.print ("Run '%s --help' to see a full list of available command line options\n", args[0]);
			return 0;
		}

		if (file != null) {
			var f = File.new_for_path (file);
			if (!f.query_exists ()) {
				f = File.new_for_uri (file);
				if (!f.query_exists ()) {
					command_line.print ("File %s doesn't exist\n", file);
					return 0;
				}
			}
			var w = new FileEditorWindow (this, f);
			w.present ();
			return 0;
		}

		if (open_note != null) {
			if (temp_command == null) temp_command =
				new HashTable<string, Value?> (str_hash, str_equal);
			temp_command.insert(
				"open-note",
				window_model.try_get_note_from_path (open_note)
			);
		}

		if (launch_search != null) {
			if (temp_command == null) temp_command =
				new HashTable<string, Value?> (str_hash, str_equal);
			temp_command.insert("launch-search", launch_search);
		}

		if (active_window != null)
			execute_temp_command ();

		activate ();
		return 0;
	}

	public override int command_line (ApplicationCommandLine command_line) {
		this.hold ();
		var res = _command_line (command_line);
		this.release ();
		return res;
	}
}
