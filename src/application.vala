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

public delegate void Runnable ();

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
		{ "format-strikethrough", on_format_strikethrough },
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
		set_accels_for_action ("app.format-strikethrough", {"<primary>s"});
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
		                      "logo-icon-name", Config.APP_ID,
			                  "program-name", "Paper",
			                  "authors", authors,
			                  "version", Config.VERSION,
			                  "license-type", Gtk.License.GPL_3_0,
			                  "website", "https://posidon.io/paper");
	}

	private void on_preferences_action () {
	    activate ();
        var w = new PreferencesWindow ();
        w.destroy_with_parent = true;
		w.transient_for = active_window;
        w.modal = true;
        w.present ();
	}

	private void on_format_bold () { window.format_selection_bold (); }

	private void on_format_italic () { window.format_selection_italic (); }

	private void on_format_strikethrough () { window.format_selection_strikethrough (); }

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
		if (active_notebook != null) {
		    var popup = new NoteCreatePopup (this);
		    popup.transient_for = active_window;
		    popup.title = Strings.NEW_NOTE;
		    popup.present ();
		} else {
            window.toast (Strings.CREATE_NOTEBOOK_BEFORE_CREATING_NOTE);
		}
	}

	private void on_edit_note () {
		if (current_note != null) {
		    request_edit_note (current_note);
		} else {
            window.toast (Strings.SELECT_NOTE_TO_EDIT);
		}
	}

	private void on_delete_note () {
	    if (current_note != null) {
		    request_delete_note (current_note);
		} else {
            window.toast (Strings.SELECT_NOTE_TO_DELETE);
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
	        (dest_notebook) => {
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
	                window.toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, dest_notebook.name));
	                return;
	            }
	            file.move (dest, FileCopyFlags.NONE);
	            select_notebook (dest_notebook);
	        }
	    );
	    popup.transient_for = active_window;
	    popup.present ();
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
            window.toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
		    active_notebook.new_note (name);
	        window.select_note (0);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast (Strings.COULDNT_CREATE_NOTE);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	public void try_change_note (Note note, string name) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
	        note.notebook.change_note (note, name);
            current_buffer = window.set_note (note);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast (Strings.COULDNT_CHANGE_NOTE);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
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
	            window.toast (Strings.COULDNT_DELETE_NOTE);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	private void try_export_note (Note note, File file) {
	    note.save_to (file, current_buffer.get_all_text ());
        window.toast (Strings.SAVED_X_TO_X.printf (note.name, file.get_path ()));
	}

	public void try_restore_note (Note note) {
		try {
	        notebook_provider.trash.restore_note (note);
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_MOVE) {
	            window.toast (Strings.COULDNT_RESTORE_NOTE);
	        } else if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, note.notebook.name));
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	public void try_create_notebook (string name, Gdk.RGBA color, NotebookIconType icon_type) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
	        var notebook = notebook_provider.new_notebook (name, color, icon_type);
	        select_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (name));
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast (Strings.COULDNT_CREATE_NOTEBOOK);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	public void try_change_notebook (Notebook notebook, string name, Gdk.RGBA color, NotebookIconType icon_type) {
	    if (name.contains (".") || name.contains ("/")) {
            window.toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
            return;
	    }
	    if (name.replace(" ", "").length == 0) {
            window.toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
            return;
	    }
		try {
	        notebook_provider.change_notebook (notebook, name, color, icon_type);
            window.set_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.ALREADY_EXISTS) {
	            window.toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (name));
	        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
	            window.toast (Strings.COULDNT_CHANGE_NOTEBOOK);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
	        }
	    }
	}

	public void try_delete_notebook (Notebook notebook) {
		try {
	        notebook_provider.delete_notebook (notebook);
	    } catch (ProviderError e) {
	        if (e is ProviderError.COULDNT_DELETE) {
	            window.toast (Strings.COULDNT_DELETE_NOTEBOOK);
	        } else {
	            window.toast (Strings.UNKNOWN_ERROR);
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
			var opt_context = new OptionContext ();
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

	private void show_confirmation_popup (string action_title, string action_description, owned Runnable callback) {
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

