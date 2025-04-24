
public class Folio.WindowModel : Object {

	public signal void state_changed (State state, NoteContainer? container, bool is_clicked = false);
	public signal void note_changed (Note? note);
	public signal void present_dialog (Adw.Dialog dialog);
	public signal void navigate_to_notes ();

	public Provider notebook_provider;

	public NoteContainer? note_container { get; private set; default = null; }
	public Note? note { get; private set; default = null; }

	public Notebook? notebook { get { return (note_container is Notebook) ? note_container as Notebook : null; } }

	public State state { get; private set; }

	public GtkMarkdown.Buffer? current_buffer { get; private set; }

	public bool is_unsaved { get; set; }

	public enum State {
		NOTEBOOK,
		NO_NOTEBOOK,
		ALL,
		TRASH
	}

	public Gtk.SingleSelection? notes_model { get; private set; default = null; }
	public Gtk.SingleSelection notebooks_model { get; private set; }

	public FuzzyStringSorter search_sorter { get; default = new FuzzyStringSorter (
			new Gtk.PropertyExpression (typeof (Note), null, "name")); }

	private SimpleNoteContainer all_notes;
	private Window window;
	private string search_for_notebook;
	private string search_for_note;

	construct {
		{
			var settings = new Settings (Config.APP_ID);
			var path = settings.get_string ("notes-dir");
			var notes_dir = path.has_prefix ("~/") ? Environment.get_home_dir () + path[1:] : path;

			notebook_provider = new Provider (Strings.TRASH);
			try {
				notebook_provider.set_directory (notes_dir);
				notebook_provider.load ();
			} catch (Error e) {}
		}

		all_notes = new SimpleNoteContainer (Strings.ALL_NOTES, notebook_provider.get_all_notes);
		update_notebooks ();

		{
			var settings = new Settings (@"$(Config.APP_ID).WindowState");
			var note_path = settings.get_string ("note");
			var note = try_get_note_from_path (note_path);
			if (note != null)
				open_note_in_notebook (note);
		}
	}

	private void _update_note_list_item_timestamp (Window? window = null) {
		// If we have a valid window handle, we can use the better/easier method to update the
		// timestamp (which also resorts the list), otherwise we have to do a hacky way.  The hack
		// should never be required but is left in place just in case.
		if (window != null) {
			this.window = window;
			window.update_note_sort_order();
		} else {
			// Need to force the item in the notes list to get an updated timestamp, the only way
			// to do this is apparently deselect the current item and then reselect it.  So let's do
			// this, but we need to keep track of the cursor so we put it back in the right spot, as
			// well as the currently selected not.
			Gtk.TextMark cursor;
			Gtk.TextIter cursor_iter;
			int current_pos;
			uint current_selected;
			cursor = current_buffer.get_insert ();
			current_buffer.get_iter_at_mark (out cursor_iter, cursor);
			current_pos = cursor_iter.get_offset ();
			current_selected = notes_model.selected;

			// Now deselect the note and then reselect it.
			select_note_at (-1);
			select_note_at (current_selected);

			// Time to return the cursor to the right spot.
			current_buffer.get_iter_at_offset (out cursor_iter, current_pos);
			current_buffer.place_cursor (cursor_iter);
		}
	}

	public void save_note ( Window? window = null) {
		if (window != null) {
			this.window = window;
		}

		if (note != null && is_unsaved) {
			bool result = note.validate_save ();

			if (!result) {
				var confirm = new Adw.AlertDialog (
					Strings.FILE_CHANGED_ON_DISK,
					Strings.FILE_CHANGED_DIALOG_TRIPLE);
				confirm.add_responses (
					"reload", Strings.FILE_CHANGED_RELOAD,
					"overwrite", Strings.FILE_CHANGED_OVERWRITE,
					"cancel", Strings.FILE_CHANGED_CANCEL);
				confirm.set_default_response ("reload");
				confirm.set_close_response ("cancel");
				confirm.response.connect (on_confirm_response_changed);
				present_dialog (confirm);
			} else {
				note.save (current_buffer.get_all_text ());
				is_unsaved = false;
				_update_note_list_item_timestamp (window);
			}
		}
	}

	private void on_confirm_response_changed (string response) {
		switch (response) {
			case "reload":
				note.save (note.load_text());
				is_unsaved = false;
				_update_note_list_item_timestamp (window);
				break;
			case "overwrite":
				note.save (current_buffer.get_all_text ());
				is_unsaved = false;
				_update_note_list_item_timestamp (window);
				break;
			default:
				break;
		}
	}

	public void select_note_at (uint i) requires (notes_model != null) {
		if (i == -1) notes_model.unselect_item (notes_model.selected);
		else {
			notes_model.select_item (i, true);
			navigate_to_notes ();
		}
	}

	public void select_notebook_at (uint i) requires (notebooks_model != null) {
		if (i == -1) notebooks_model.unselect_item (notebooks_model.selected);
		else notebooks_model.select_item (i, true);
	}

	public void select_notebook (Notebook? notebook_to_select) requires (notebooks_model != null) {
		if (notebook_to_select == null) {
			select_notebook_at (-1);
			return;
		}

		this.search_for_notebook = notebook_to_select.name;

		var n = notebook_provider.notebooks
			.first_match (match_notebook_name);
		int i = notebook_provider.notebooks.index_of (n);
		select_notebook_at (i);
	}

	private bool match_notebook_name (Notebook it) {
		return it.name == this.search_for_notebook;
	}

	public void select_note (Note? note_to_select)
		requires (note_container != null)
		requires (note_container.loaded_notes != null)
		requires (notes_model != null) {
		if (note_to_select == null) {
			select_note_at (-1);
			return;
		}

		this.search_for_note = note.name;

		var n = note_container.loaded_notes
			.first_match (match_note_name);
		int i = note_container.loaded_notes.index_of (n);
		select_note_at (i);
		navigate_to_notes ();
	}

	private bool match_note_name (Note it) {
		return it.name == search_for_note;
	}

	public void update_selected_note () requires (notes_model != null) {
		select_note_at (notes_model.selected);
		if (notes_model.selected != -1)
			notes_model.selection_changed (notes_model.selected, 1);
	}
	public void update_selected_notebook () requires (notebooks_model != null) {
		select_notebook_at (notebooks_model.selected);
		if (notebooks_model.selected != -1)
			notebooks_model.selection_changed (notebooks_model.selected, 1);
	}

	public void set_notebook (Notebook? notebook) {
		update_state (notebook == null ? State.NO_NOTEBOOK : State.NOTEBOOK, notebook); }

	public void set_trash (Trash trash) { update_state (State.TRASH, trash); }

	public void set_all () { update_state (State.ALL, all_notes); }

	private void update_state (State state, NoteContainer? container = null) {
		var is_different = this.note_container != container;
		var last_container = this.note_container;

		if (is_different) {
			update_note (null);
		}

		this.note_container = container;
		this.state = state;

		if (container != null) {
			container.load ();
			var model = new Gtk.SingleSelection (
				new Gtk.SortListModel (container, search_sorter)
			);
			model.can_unselect = true;
			model.selection_changed.connect (on_model_selection_changed);
			notes_model = model;
		} else {
			notes_model = null;
		}

		state_changed (state, note_container);

		if (notes_model != null)
			update_selected_note ();

		if (last_container != null && last_container != container && state != State.ALL)
			last_container.unload ();
	}

	private void on_model_selection_changed () {
		var i = notes_model.selected;
		if (i < note_container.loaded_notes.size && i != -1) {
			var note = notes_model.get_item (i) as Note;
			update_note (note);
		}
		else update_note (null);
	}

	private FileMonitor _monitor = null;

	private void _monitor_note (Note note, Window? window) {
		if (window != null) {
			this.window = window;
		}

		File file = File.new_for_path (note.path);

		if (_monitor != null) {
			_monitor.cancel();
		}

		// Setup a monitor to watch for changes on disk.
		if (file != null) {
			try {
				_monitor = file.monitor_file (FileMonitorFlags.WATCH_HARD_LINKS);
				_monitor.changed.connect (on_monitor_changed);
			} catch (Error e) {}
		}
	}

	private void on_monitor_changed (FileMonitor monitor, File file, File? other, FileMonitorEvent event) {
		switch (event) {
			case FileMonitorEvent.CHANGES_DONE_HINT:
				FileInfo file_info;
				DateTime file_time;
				try {
					file_info = file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
					file_time = file_info.get_modification_date_time ();
				} catch (Error e) {
					file_time = new DateTime.now ();
				}

				if (!note.time_modified.equal (file_time)) {
					if (is_unsaved) {
						is_unsaved = false;
						var confirm = new Adw.AlertDialog (
							Strings.FILE_CHANGED_ON_DISK,
							Strings.FILE_CHANGED_DIALOG_DOUBLE);
						confirm.add_responses (
							"reload", Strings.FILE_CHANGED_RELOAD,
							"overwrite", Strings.FILE_CHANGED_OVERWRITE);
						confirm.close_response = "overwrite";
						confirm.default_response = "overwrite";
						confirm.response.connect (on_confirm_response);
						present_dialog (confirm);
					} else {
						current_buffer = new GtkMarkdown.Buffer (note.load_text ());
						note.update_note_time ();
						_update_note_list_item_timestamp (window);
					}
				}

				break;
			case FileMonitorEvent.CREATED:
			case FileMonitorEvent.ATTRIBUTE_CHANGED:
			case FileMonitorEvent.PRE_UNMOUNT:
			case FileMonitorEvent.UNMOUNTED:
			case FileMonitorEvent.MOVED:
			case FileMonitorEvent.RENAMED:
			case FileMonitorEvent.CHANGED:
			case FileMonitorEvent.DELETED:
			case FileMonitorEvent.MOVED_IN:
			case FileMonitorEvent.MOVED_OUT:
			default:
				break;
		}
	}

	private void on_confirm_response (string response) {
		switch (response) {
			case "reload":
				current_buffer = new GtkMarkdown.Buffer (note.load_text ());
				note.update_note_time ();
				_update_note_list_item_timestamp (window);
				break;
			default:
				note.save (current_buffer.get_all_text ());
				note.update_note_time ();
				_update_note_list_item_timestamp (window);
				break;
		}
	}

	public GtkMarkdown.Buffer? update_note (Note? note, Window? window = null) {
		if (window != null) {
			this.window = window;
		}

		if (this.note == note) return current_buffer;
		save_note (window);
		this.note = note;
		is_unsaved = false;
		if (note != null) {
			current_buffer = new GtkMarkdown.Buffer (note.load_text ());
			_monitor_note (note, window);
			var settings = new Settings (@"$(Config.APP_ID).WindowState");
			settings.set_string ("note", note.id);
		} else {
			current_buffer = null;
		}

		note_changed (note);

		return current_buffer;
	}

	public void open_note_in_notebook (Note note)
		requires (notebooks_model != null)
		requires (note.notebook != null) {
		select_notebook (note.notebook);
		select_note (note);
	}

	public Notebook create_notebook (NotebookInfo info) throws ProviderError requires (notebooks_model != null) {
		var notebook = notebook_provider.new_notebook (info);
		select_notebook (notebook);
		update_selected_notebook ();
		return notebook;
	}

	public Note create_note (string name) throws ProviderError requires (notes_model != null) {
		var n = notebook.new_note (name);
		select_note_at (0);
		update_note (n);
		return n;
	}

	public void change_notebook (Notebook notebook, NotebookInfo info) throws ProviderError {
		notebook_provider.change_notebook (notebook, info);
		if (note_container == notebook) {
			set_notebook (notebook);
		}
		update_notebooks ();
	}

	public void change_note (Note note, string name, string extension = note.extension, bool do_update = true)
		throws ProviderError requires (note.notebook != null) {
		note.notebook.change_note (note, name, extension);
		if (do_update) {
			update_note (note);
		}
	}

	public void delete_notebook (Notebook notebook) throws ProviderError {
		set_notebook (null);
		notebook_provider.delete_notebook (notebook);
		update_selected_notebook ();
	}

	public void restore_note (Note note) throws ProviderError {
		notebook_provider.trash.restore_note (note);
	}

	public bool move_note (Note note, Notebook dest_notebook)
		requires (notebooks_model != null)
		requires (note.notebook != null) {
		var l = note.notebook.loaded_notes;
		if (l != null) {
			var i = l.index_of (note);
			l.remove_at (i);
			note.notebook.items_changed (i, 1, 0);
		}
		set_notebook (null);
		update_note (null);
		var file = File.new_for_path (note.path);
		var dest_path = @"$(dest_notebook.path)/$(note.file_name)";
		var dest = File.new_for_path (dest_path);
		if (dest.query_exists ()) {
			return false;
		}
		try {
			file.move (dest, FileCopyFlags.NONE);
		} catch (Error e) {
			return false;
		}
		select_notebook (dest_notebook);
		return true;
	}

	public void empty_trash () {
		try {
			notebook_provider.trash.delete_all ();
		} catch (Error e) {}
	}

	public Note? try_get_note_from_path (string path) {
		if (path.length == 0)
			return null;
		var note_data = path.split ("/");
		if (note_data.length != 2)
			return null;
		search_for_notebook = note_data[0];
		var notebook = notebook_provider.notebooks
			.first_match (match_notebook_name);
		if (notebook == null)
			return null;
		notebook.load ();
		search_for_note = note_data[1];
		return notebook.loaded_notes
			.first_match (match_note_name);
	}

	public string generate_new_note_name (int i = 0, string? full_name = null) requires (notebook != null) {
		var name = "";
		var s = notebook.loaded_notes.size;
		if (full_name != null && full_name != "") {
			name = i == 0 ? full_name : @"$full_name $i";
		} else {
			name = i == 0 ? Strings.NEW_NOTE_NAME : Strings.NEW_NOTE_NAME_X.printf (i);
		}
		for (int j = 0; j < s; j++) {
			if (notebook.loaded_notes.@get (j).name == name)
				return generate_new_note_name (++i, full_name);
		}
		return name;
	}

	public void search (string? query) {
		search_sorter.target = query;
	}

	public void update_notebooks () {
		var model = new Gtk.SingleSelection (notebook_provider);
		model.can_unselect = true;
		model.autoselect = false;
		model.selection_changed.connect (on_notebook_model_selection_changed);
		notebooks_model = model;
		update_selected_notebook ();
	}

	private void on_notebook_model_selection_changed () {
		var i = notebooks_model.selected;
		var notebooks = notebook_provider.notebooks;
		if (i <= notebooks.size && i != -1) {
			set_notebook (notebooks[(int) i]);
		}
	}
}
