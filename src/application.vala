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
		{ "format-bold", on_format_bold },
		{ "format-italic", on_format_italic },
		{ "format-strikethough", on_format_strikethough },
		{ "format-highlight", on_format_highlight },
		{ "insert-link", on_insert_link },
		{ "insert-code-span", on_insert_code_span },
		{ "markdown-cheatsheet", on_markdown_cheatsheet },
		{ "toggle-sidebar", on_toggle_sidebar },
		{ "search-notes", on_search_notes },
		{ "empty-trash", on_empty_trash },
		{ "about", on_about_action },
		{ "preferences", on_preferences_action },
		{ "quit", quit }
	};

	public Provider notebook_provider;

	private Notebook? active_notebook = null;
    private Note? current_note = null;
    private GtkMarkdown.Buffer? current_buffer = null;

    private HashTable<string, Value?> temp_command;

	public Application () {
		Object (application_id: Config.APP_ID, flags: ApplicationFlags.HANDLES_COMMAND_LINE);

	    var settings = new Settings (Config.APP_ID);
		var notes_dir = settings.get_string ("notes-dir");

		notebook_provider = new LocalProvider.from_directory (notes_dir);

		add_action_entries (APP_ACTIONS, this);

		set_accels_for_action ("app.quit", {"<primary>q"});
		set_accels_for_action ("app.preferences", {"<primary>comma"});

		set_accels_for_action ("app.new-note", {"<primary>n"});
		set_accels_for_action ("app.new-notebook", {"<primary><shift>n"});

		set_accels_for_action ("app.edit-note", {"<primary>e"});
		set_accels_for_action ("app.edit-notebook", {"<primary><shift>e"});

		set_accels_for_action ("app.format-bold", {"<primary>b"});
		set_accels_for_action ("app.format-italic", {"<primary>i"});
		set_accels_for_action ("app.format-strikethough", {"<primary>s"});
		set_accels_for_action ("app.format-highlight", {"<primary>h"});
		set_accels_for_action ("app.insert-link", {"<primary>k"});

		set_accels_for_action ("app.toggle-sidebar", {"F9"});
		set_accels_for_action ("app.search-notes", {"<primary>f"});

		command_line.connect (_command_line);
	}

	public override void activate () {
		base.activate ();
		var win = this.active_window;
		if (win == null) {
			win = new Window (this);
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
            set_active_notebook (note.notebook);
            set_active_note (note);
            temp_command.remove ("open-note");
	    }
	    var query = temp_command.take ("launch-search", out exists);
	    if (exists) {
            window.search_notes (query.get_string ());
            temp_command.remove ("launch-search");
	    }
	    temp_command = null;
	}

	private void on_about_action () {
		string[] authors = {"Zagura"};
		Gtk.show_about_dialog(this.active_window,
		                      "logo-icon-name", "io.posidon.Paper",
			                  "program-name", "Paper",
			                  "authors", authors,
			                  "version", Config.VERSION,
			                  "license-type", Gtk.License.GPL_3_0,
			                  "website", "https://posidon.io/paper");
	}

	private void on_preferences_action () {
	    activate ();
        var w = new PreferencesWindow (this);
        w.destroy_with_parent = true;
		w.transient_for = active_window;
        w.modal = true;
        w.present ();
	}

	private void on_format_bold () { window.format_selection_bold (); }

	private void on_format_italic () { window.format_selection_italic (); }

	private void on_format_strikethough () { window.format_selection_strikethough (); }

	private void on_format_highlight () { window.format_selection_highlight (); }

	private void on_insert_link () { window.insert_link (); }

	private void on_insert_code_span () { window.insert_code_span (); }

	private void on_markdown_cheatsheet () {
        var w = new MarkdownCheatsheet (this);
        w.destroy_with_parent = true;
		w.transient_for = active_window;
        w.modal = true;
        w.present ();
	}

	private void on_toggle_sidebar () {
	    window.toggle_sidebar_visibility ();
	}

	private void on_search_notes () {
	    window.toggle_search ();
	}

	private void on_empty_trash () {
		var popup = new ConfirmationPopup (
		    @"Are you sure you want to delete everything in the trash?",
		    "Empty trash",
		    () => {
		        set_active_note (null);
		        notebook_provider.trash.delete_all ();
	        }
	    );
		popup.transient_for = active_window;
		popup.present ();
	}

	private void on_new_note () {
	    activate ();
		if (active_notebook != null) {
		    var popup = new NoteCreatePopup (this);
		    popup.transient_for = active_window;
		    popup.title = "New note";
		    popup.present ();
		} else {
            window.toast ("Create/choose a notebook before creating a note");
		}
	}

	private void on_edit_note () {
		if (current_note != null) {
		    request_edit_note (current_note);
		} else {
            window.toast ("Select a note to edit it");
		}
	}

	private void on_delete_note () {
	    if (current_note != null) {
		    request_delete_note (current_note);
		} else {
            window.toast ("Select a note to delete it");
		}
	}

	private void on_export_note () {
	    var chooser = new Gtk.FileChooserNative ("Export Note", active_window, Gtk.FileChooserAction.SAVE, "Export", null);
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
		var popup = new CreatePopup (this);
		popup.transient_for = active_window;
		popup.title = "New notebook";
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
	    popup.title = "Rename note";
	    popup.present ();
	}

	public void request_delete_note (Note note) {
		var popup = new ConfirmationPopup (
		    @"Are you sure you want to delete the note $(note.name)?",
		    "Delete Note",
		    () => try_delete_note (note)
	    );
		popup.transient_for = active_window;
		popup.present ();
	}

	public void request_edit_notebook (Notebook notebook) {
		var popup = new CreatePopup (this, notebook);
		popup.transient_for = active_window;
		popup.title = "Edit notebook";
		popup.present ();
	}

	public void request_delete_notebook (Notebook notebook) {
		var popup = new ConfirmationPopup (
		    @"Are you sure you want to delete the notebook $(notebook.name)?",
		    "Delete Notebook",
		    () => try_delete_notebook (notebook)
	    );
		popup.transient_for = active_window;
		popup.present ();
	}

	public void try_create_note (string name) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (@"Note name shouldn't contain '.' or '/'");
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (@"Note name shouldn't be blank");
            return;
	    }
		try {
		    active_notebook.new_note (name);
	        window.select_note (0);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (@"Note '$(name)' already exists");
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast ("Couldn't create note");
	        } else {
	            window.toast ("Unknown error");
	        }
	    }
	}

	public void try_change_note (Note note, string name) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (@"Note name shouldn't contain '.' or '/'");
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (@"Note name shouldn't be blank");
            return;
	    }
		try {
	        note.notebook.change_note (note, name);
            current_buffer = window.set_note (note);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (@"Note '$(name)' already exists");
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast ("Couldn't change note");
	        } else {
	            window.toast ("Unknown error");
	        }
	    }
	}

	public void try_delete_note (Note note) {
		try {
	        if (current_note == note) set_active_note (null);
	        note.notebook.delete_note (note);
	        window.update_selected_note ();
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_DELETE) {
	            window.toast (@"Couldn't delete note");
	        } else {
	            window.toast ("Unknown error");
	        }
	    }
	}

	private void try_export_note (Note note, File file) {
	    note.save_to (file, current_buffer.get_all_text ());
        window.toast (@"Saved '$(note.name)' to $(file.get_path ())");
	}

	public void try_restore_note (Note note) {
		try {
	        notebook_provider.trash.restore_note (note);
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_MOVE) {
	            window.toast (@"Couldn't restore note");
	        } else if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (@"Note called '$(note.name)' already exists in notebook '$(note.notebook.name)'");
	        } else {
	            window.toast ("Unknown error");
	        }
	    }
	}

	public void try_create_notebook (string name, Gdk.RGBA color) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (@"Notebook name shouldn't contain '.' or '/'");
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (@"Notebook name shouldn't be blank");
            return;
	    }
		try {
	        var notebook = notebook_provider.new_notebook (name, color);
	        select_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (@"Notebook '$(name)' already exists");
	        }
	        if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast ("Couldn't create notebook");
                stderr.printf ("Couldn't create notebook: %s\n", e.message);
	        }
	    }
	}

	public void try_change_notebook (Notebook notebook, string name, Gdk.RGBA color) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (@"Notebook name shouldn't contain '.' or '/'");
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (@"Notebook name shouldn't be blank");
            return;
	    }
		try {
	        notebook_provider.change_notebook (notebook, name, color);
            window.set_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (@"Notebook '$(name)' already exists");
	        }
	        if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast ("Couldn't change notebook");
                stderr.printf ("Couldn't change notebook: %s\n", e.message);
	        }
	    }
	}

	public void try_delete_notebook (Notebook notebook) {
		try {
	        notebook_provider.delete_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_DELETE) {
	            window.toast (@"Couldn't delete notebook");
	        } else {
	            window.toast ("Unknown error");
	        }
	    }
	}

	public void set_active_notebook (Notebook? notebook) {
	    if (active_notebook == notebook) return;
	    var old_notebook = active_notebook;
	    set_active_note (null);
	    active_notebook = notebook;
        window.set_notebook (notebook);
        if (old_notebook != null) {
	        old_notebook.unload ();
	    }
	}

	public void select_notebook (Notebook notebook) {
        int i = notebook_provider.notebooks.index_of (notebook);
        window.select_notebook (i);
	}

	public void set_active_note (Note? note) {
	    if (current_note == note) return;
        current_note = note;
        current_buffer = window.set_note (note);
	}

	public Window window {
	    get { return ((!) this.active_window) as Window; }
	}

	public override void shutdown () {
	    if (current_note != null) {
            current_note.save (current_buffer.get_all_text ());
            current_note = null;
            current_buffer = null;
	    }
	    base.shutdown ();
	}

	private int _command_line (ApplicationCommandLine command_line) {
		string? open_note = null;
		string? launch_search = null;

		OptionEntry[] options = new OptionEntry[2];
		options[0] = { "open-note", 0, 0, OptionArg.STRING, ref open_note, "Open a note", null };
		options[1] = { "launch-search", 0, 0, OptionArg.STRING, ref launch_search, "Search notes", null };


		// We have to make an extra copy of the array, since .parse assumes
		// that it can remove strings from the array without freeing them.
		string[] args = command_line.get_arguments ();
		string*[] _args = new string[args.length];
		for (int i = 0; i < args.length; i++) {
			_args[i] = args[i];
		}

		try {
			var opt_context = new OptionContext ("- OptionContext example");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			unowned string[] tmp = _args;
			opt_context.parse (ref tmp);
		} catch (OptionError e) {
			command_line.print ("error: %s\n", e.message);
			command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 0;
		}

		if (open_note != null) {
            if (temp_command == null) temp_command = new HashTable<string, Value> (str_hash, str_equal);
			var note_data = open_note.split ("/");
            var notebook = notebook_provider.notebooks.first_match ((it) => it.name == note_data[0]);
            notebook.load ();
            var note = notebook.loaded_notes.first_match ((it) => it.name == note_data[1]);
            temp_command.insert("open-note", note);
		}

		if (launch_search != null) {
            if (temp_command == null) temp_command = new HashTable<string, Value> (str_hash, str_equal);
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
