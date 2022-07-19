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

public class Paper.Application : Adw.Application {
	private ActionEntry[] APP_ACTIONS = {
		{ "new-note", on_new_note },
		{ "edit-note", on_edit_note },
		{ "delete-note", on_delete_note },
		{ "export-note", on_export_note },

		{ "new-notebook", on_new_notebook },
		{ "edit-notebook", on_edit_notebook },
		{ "delete-notebook", on_delete_notebook },

		{ "markdown-cheatsheet", on_markdown_cheatsheet },

		{ "empty-trash", on_empty_trash },

		{ "about", on_about_action },
		{ "preferences", on_preferences_action },
		{ "quit", on_quit_action }
	};

	public Provider notebook_provider;

	private Notebook? active_notebook = null;
    private Note? current_note = null;
    private GtkMarkdown.Buffer? current_buffer = null;

    private HashTable<string, Value?> temp_command;

    private Window? main_window = null;

    private Gtk.CssProvider? black_css_provider = null;
    private Gtk.CssProvider? black_hc_css_provider = null;

	public Application () {
		Object (
		    application_id: Config.APP_ID,
		    flags: ApplicationFlags.HANDLES_COMMAND_LINE
		);

	    {
	        var settings = new Settings (Config.APP_ID);
		    var notes_dir = settings.get_string ("notes-dir");

		    notebook_provider = new Provider (Strings.TRASH);
		    notebook_provider.set_directory (notes_dir);
		    notebook_provider.load ();
		}

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

		command_line.connect (_command_line);

        {
	        var settings = new Settings (@"$(Config.APP_ID).Theme");
	        settings.bind ("variant", style_manager, "color-scheme", SettingsBindFlags.DEFAULT);
	    }

        style_manager.notify["dark"].connect (() => update_theme ());
        style_manager.notify["high-contrast"].connect (() => update_theme ());
        update_theme ();
	}

	public override void activate () {
		base.activate ();
		var win = this.active_window;
		if (win == null) {
			main_window = new Window (this);
			main_window.init (this);
			win = main_window;

            var settings = new Settings (@"$(Config.APP_ID).WindowState");
            var note_path = settings.get_string ("note");
		    var note = try_get_note_from_path (note_path);
            if (note != null) {
                select_notebook (note.notebook);
                set_active_note (note);
            }
		}
		execute_temp_command ();
		win.present ();
	}

	private void execute_temp_command () {
	    if (temp_command == null) return;
	    bool exists;
	    var _note = temp_command.take ("open-note", out exists);
	    if (exists) {
	        var note = _note.get_object () as Note;
            if (note != null) {
                select_notebook (note.notebook);
                set_active_note (note);
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
		string[] authors = {"Zagura"};
		Gtk.show_about_dialog(this.active_window,
		                      "logo-icon-name", Config.APP_ID,
			                  "program-name", "Paper",
			                  "authors", authors,
			                  "version", Config.VERSION,
			                  "license-type", Gtk.License.GPL_3_0,
			                  "website", "https://posidon.io/paper");
	}

	private void on_preferences_action () {
	    activate ();
        var w = new PreferencesWindow (this, main_window);
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
	    show_confirmation_popup (
            Strings.EMPTY_TRASH,
	        Strings.EMPTY_TRASH_CONFIRMATION,
	        () => {
	            set_active_note (null);
	            notebook_provider.trash.delete_all ();
	        }
	    );
	}

	private void on_new_note () {
	    activate ();
	    var a = active_notebook;
		if (a != null) {
		    var name = a.get_available_name ();
            try_create_note (name);
		} else {
            toast (Strings.CREATE_NOTEBOOK_BEFORE_CREATING_NOTE);
		}
	}

	private void on_edit_note () {
		if (current_note != null) {
		    request_edit_note (current_note);
		} else {
            toast (Strings.SELECT_NOTE_TO_EDIT);
		}
	}

	private void on_delete_note () {
	    if (current_note != null) {
		    request_delete_note (current_note);
		} else {
            toast (Strings.SELECT_NOTE_TO_DELETE);
		}
	}

	private void on_export_note () {
	    var chooser = new Gtk.FileChooserNative (Strings.EXPORT_NOTE, active_window, Gtk.FileChooserAction.SAVE, Strings.EXPORT, null);
	    chooser.response.connect ((response_id) => {
	        var file = chooser.get_file ();
	        chooser.unref ();
	        if (file != null && current_note != null) {
	            try_export_note (current_note, file);
	        }
	    });
	    chooser.modal = true;
	    chooser.ref ();
	    chooser.show ();
	}

	private void on_new_notebook () {
	    activate ();
		var popup = new NotebookCreatePopup (this);
		popup.transient_for = active_window;
		popup.title = Strings.NEW_NOTEBOOK;
		popup.present ();
	}

	private void on_edit_notebook () {
	    if (active_notebook == null) return;
		request_edit_notebook (active_notebook);
	}

	private void on_delete_notebook () {
	    if (active_notebook == null) return;
		request_delete_notebook (active_notebook);
	}

	public void request_edit_note (Note note) {
	    var popup = new NoteCreatePopup (this, note);
	    popup.transient_for = active_window;
	    popup.title = Strings.RENAME_NOTE;
	    popup.present ();
	}

	public void request_move_note (Note note) {
	    var popup = new NotebookSelectionPopup (
	        notebook_provider,
	        Strings.MOVE_TO_NOTEBOOK,
	        Strings.MOVE,
	        (dest_notebook) => move_note (note, dest_notebook)
	    );
	    popup.transient_for = active_window;
	    popup.present ();
	}

	public void move_note (Note note, Notebook dest_notebook) {
        var l = note.notebook.loaded_notes;
        if (l != null) {
            var i = l.index_of (note);
            l.remove_at (i);
            note.notebook.items_changed (i, 1, 0);
        }
        set_active_notebook (null);
        set_active_note (null);
        var file = File.new_for_path (note.path);
        var dest_path = @"$(dest_notebook.path)/$(note.file_name)";
        var dest = File.new_for_path (dest_path);
        if (dest.query_exists ()) {
            toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, dest_notebook.name));
            return;
        }
        file.move (dest, FileCopyFlags.NONE);
        select_notebook (dest_notebook);
	}

	public void request_delete_note (Note note) {
	    show_confirmation_popup (
		    Strings.DELETE_NOTE,
		    Strings.DELETE_NOTE_CONFIRMATION.printf (note.name),
		    () => try_delete_note (note)
	    );
	}

	public void request_edit_notebook (Notebook notebook) {
		var popup = new NotebookCreatePopup (this, notebook);
		popup.transient_for = active_window;
		popup.title = Strings.EDIT_NOTEBOOK;
		popup.present ();
	}

	public void request_delete_notebook (Notebook notebook) {
	    show_confirmation_popup (
		    Strings.DELETE_NOTEBOOK,
		    Strings.DELETE_NOTEBOOK_CONFIRMATION.printf (notebook.name),
		    () => try_delete_notebook (notebook)
	    );
	}

	public void try_create_note (string name) {
	    if (name.contains (".") || name.contains ("/")) {
            toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
		    var n = active_notebook.new_note (name);
	        main_window.select_note (0);
	        set_active_note(n);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS)
	            toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
	        else if (e is ProviderError.COULDNT_CREATE_FILE)
	            toast (Strings.COULDNT_CREATE_NOTE);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	    }
	}

	public bool try_change_note (Note note, string name) {
	    if (name.contains (".") || name.contains ("/")) {
            toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return false;
	    }
	    if (name.replace(" ", "").length == 0) {
            toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
            return false;
	    }
		try {
	        note.notebook.change_note (note, name);
            current_buffer = main_window.set_note (note);
	        return true;
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS)
	            toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
	        else if (e is ProviderError.COULDNT_CREATE_FILE)
	            toast (Strings.COULDNT_CHANGE_NOTE);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	        return false;
	    }
	}

	public void try_delete_note (Note note) {
		try {
	        set_active_note (null);
            //upon deletion of a note, we will select the next note DOWN the list (or none).
	        var idx = note.notebook.get_index_of (note);

	        note.notebook.delete_note (note);

	        var item_count = note.notebook.get_n_items ();
	        Note? new_active_note = null;
	        if (item_count == 1 || idx == 0) { // selecting down, so first item or a list of 2 is the same.
	            new_active_note = (Note) note.notebook.get_item (0);
	        } else if (item_count > 1){
	            new_active_note = (Note) note.notebook.get_item (idx - 1);
	        }

	        set_active_note (new_active_note);

            //if we are removing the last item we need to select a different index.
            //we really should be doing this somewhere else.
	        if (idx == item_count)
	            main_window.select_note (idx - 1);
	        else
	            main_window.select_note (idx);

	        main_window.update_selected_note ();
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_DELETE)
	            toast (Strings.COULDNT_DELETE_NOTE);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	    }
	}

	private void try_export_note (Note note, File file) {
	    FileUtils.save_to (file, current_buffer.get_all_text ());
        toast (Strings.SAVED_X_TO_X.printf (note.name, file.get_path ()));
	}

	public void try_restore_note (Note note) {
		try {
	        notebook_provider.trash.restore_note (note);
	        {
	            var n = notebook_provider.notebooks;
	            var i = 0;
	            while (i < n.size) {
	                if (n[i].name == note.notebook.name)
	                    break;
	                i++;
	            }
	            if (i == n.size) {
	                notebook_provider.unload ();
	                notebook_provider.load ();
	                main_window.update_notebooks (this);
	            }
	        }
	        {
	            var n = notebook_provider.notebooks;
	            var i = 0;
	            while (i < n.size) {
	                if (n[i].name == note.notebook.name)
	                    break;
	                i++;
	            }
	            select_notebook (i == n.size ? null : n[i]);
	        }
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_MOVE) {
	            toast (Strings.COULDNT_RESTORE_NOTE);
	        } else if (e is ProviderError.ALREADY_EXISTS) {
	            toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, note.notebook.name));
	        } else {
	            toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	public void try_create_notebook (NotebookInfo info) {
	    if (info.name.contains (".") || info.name.contains ("/")) {
            toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (info.name.replace(" ", "").length == 0) {
            toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
	        var notebook = notebook_provider.new_notebook (info);
	        select_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS)
	            toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (info.name));
	        else if (e is ProviderError.COULDNT_CREATE_FILE)
	            toast (Strings.COULDNT_CREATE_NOTEBOOK);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	    }
	}

	public void try_change_notebook (Notebook notebook, NotebookInfo info) {
	    if (info.name.contains (".") || info.name.contains ("/")) {
            toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (info.name.replace(" ", "").length == 0) {
            toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
	        notebook_provider.change_notebook (notebook, info);
	        if (main_window.current_container == notebook)
	            main_window.set_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS)
	            toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (info.name));
	        else if (e is ProviderError.COULDNT_CREATE_FILE)
	            toast (Strings.COULDNT_CHANGE_NOTEBOOK);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	    }
	}

	public void try_delete_notebook (Notebook notebook) {
		try {
	        set_active_notebook (null);
	        notebook_provider.delete_notebook (notebook);
	        main_window.update_selected_notebook ();
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_DELETE)
	            toast (Strings.COULDNT_DELETE_NOTEBOOK);
	        else
	            toast (Strings.UNKNOWN_ERROR);
	    }
	}

	public void set_active_notebook (Notebook? notebook) {
	    if (active_notebook == notebook) return;
	    var old_notebook = active_notebook;
	    set_active_note (null);
	    active_notebook = notebook;
        main_window.set_notebook (notebook);
        if (old_notebook != null) {
	        old_notebook.unload ();
	    }
	}

	public void select_notebook (Notebook notebook) {
	    var n = notebook_provider.notebooks
	        .first_match ((it) => it.name == notebook.name);
        int i = notebook_provider.notebooks.index_of (n);
        main_window.select_notebook (i);
	}

	public void set_active_note (Note? note) {
	    if (current_note == note) return;
        current_note = note;
        current_buffer = main_window.set_note (note);
	}

	public override void shutdown () {
	    {
            var settings = new Settings (@"$(Config.APP_ID).WindowState");
            settings.set_string ("note", current_note.id);
        }
        current_note.save (current_buffer.get_all_text ());
        current_note = null;
        current_buffer = null;
	    base.shutdown ();
	}

	public void toast (string message) {
	    main_window.toast (message);
	}

	public void update_theme () {
	    var dark = style_manager.dark;
	    var high_contrast = style_manager.high_contrast;
	    var settings = new Settings (Config.APP_ID);
		var theme_oled = settings.get_boolean ("theme-oled");
		if (dark && theme_oled) {
		    if (black_css_provider == null) {
                var css = new Gtk.CssProvider ();
                css.load_from_resource (@"$resource_base_path/style-black.css");
                Gtk.StyleContext.add_provider_for_display (active_window.display, css, -1);
                black_css_provider = css;
            }
		}
		else {
            if (black_css_provider != null)
                Gtk.StyleContext.remove_provider_for_display (active_window.display, black_css_provider);
            black_css_provider = null;
		}
		if (dark && theme_oled && high_contrast) {
	        if (black_hc_css_provider == null) {
                var css = new Gtk.CssProvider ();
                css.load_from_resource (@"$resource_base_path/style-black-hc.css");
                Gtk.StyleContext.add_provider_for_display (active_window.display, css, -1);
                black_hc_css_provider = css;
            }
		}
		else {
            if (black_hc_css_provider != null)
                Gtk.StyleContext.remove_provider_for_display (active_window.display, black_hc_css_provider);
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
			    command_line.print ("File at %s doesn't exist\n", f.get_path ());
		        return 0;
		    }
		    var w = new FileEditorWindow (this, f);
		    w.present ();
		    return 0;
		}

		if (open_note != null) {
            if (temp_command == null) temp_command =
                new HashTable<string, Value> (str_hash, str_equal);
            temp_command.insert(
                "open-note",
                try_get_note_from_path (open_note)
            );
		}

		if (launch_search != null) {
            if (temp_command == null) temp_command =
                new HashTable<string, Value> (str_hash, str_equal);
            temp_command.insert("launch-search", launch_search);
		}

        if (active_window != null)
            execute_temp_command ();

        activate ();
        return 0;
	}

	private Note? try_get_note_from_path (string path) {
	    if (path.length == 0)
	        return null;
		var note_data = path.split ("/");
	    if (note_data.length != 2)
	        return null;
        var notebook = notebook_provider.notebooks
            .first_match ((it) => it.name == note_data[0]);
        if (notebook == null)
            return null;
        notebook.load ();
        return notebook.loaded_notes
            .first_match ((it) => it.name == note_data[1]);
	}

	public override int command_line (ApplicationCommandLine command_line) {
		this.hold ();
		var res = _command_line (command_line);
		this.release ();
		return res;
	}

	private void show_confirmation_popup (
	    string action_title,
	    string action_description,
	    owned Runnable callback
	) {
        var dialog = new Gtk.MessageDialog (
            active_window,
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
            Gtk.MessageType.QUESTION,
            Gtk.ButtonsType.CANCEL,
            action_title
        );

        dialog.secondary_text = action_description;

        dialog.add_button (action_title, 1)
            .get_style_context ()
            .add_class ("destructive-action");

        dialog.response.connect ((response_id) => {
            if (response_id == 1) {
	            callback ();
	        }
            dialog.close ();
        });
		dialog.present ();
	}
}

