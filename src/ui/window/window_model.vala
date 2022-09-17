
public class Paper.WindowModel : Object {

    public signal void state_changed (State state, NoteContainer? container);
    public signal void note_changed (Note? note);

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


	construct {
	    {
            var settings = new Settings (Config.APP_ID);
	        var notes_dir = settings.get_string ("notes-dir");

	        notebook_provider = new Provider (Strings.TRASH);
	        notebook_provider.set_directory (notes_dir);
	        notebook_provider.load ();
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

    public void save_note () {
	    if (note != null) {
            note.save (current_buffer.get_all_text ());
            is_unsaved = false;
	    }
    }

	public void select_note_at (uint i) requires (notes_model != null) {
	    if (i == -1) notes_model.unselect_item (notes_model.selected);
	    else notes_model.select_item (i, true);
    }
	public void select_notebook_at (uint i) requires (notebooks_model != null) {
	    if (i == -1) notebooks_model.unselect_item (notebooks_model.selected);
	    else notebooks_model.select_item (i, true);
    }

	public void select_notebook (Notebook? notebook) requires (notebooks_model != null) {
	    if (notebook == null) {
	        select_notebook_at (-1);
	        return;
        }
	    var n = notebook_provider.notebooks
	        .first_match ((it) => it.name == notebook.name);
        int i = notebook_provider.notebooks.index_of (n);
        select_notebook_at (i);
	}

	public void select_note (Note? note)
	    requires (note_container != null)
	    requires (note_container.loaded_notes != null)
	    requires (notes_model != null) {
	    if (note == null) {
	        select_note_at (-1);
	        return;
        }
	    var n = note_container.loaded_notes
	        .first_match ((it) => it.name == note.name);
        int i = note_container.loaded_notes.index_of (n);
        select_note_at (i);
	}

	public void update_selected_note () requires (notes_model != null) {
	    select_note_at (notes_model.selected);
	}
	public void update_selected_notebook () requires (notebooks_model != null) {
	    select_notebook_at (notebooks_model.selected);
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
		    model.selection_changed.connect (() => {
	            var i = model.selected;
	            if (i < container.loaded_notes.size && i != -1) {
		            var note = model.get_item (i) as Note;
		            update_note (note);
		        }
	            else update_note (null);
		    });
	        notes_model = model;

            if (container.loaded_notes.size != 0) {
	            select_note_at (-1);
	            select_note_at (0);
            }
        } else {
            notes_model = null;
        }

	    state_changed (state, note_container);

        if (last_container != null && last_container != container && state != State.ALL)
            last_container.unload ();
    }

	public GtkMarkdown.Buffer? update_note (Note? note) {
	    if (this.note == note) return current_buffer;
        save_note ();
	    var old_note = this.note;
	    this.note = note;
        is_unsaved = false;

	    if (note != null) {
	        current_buffer = new GtkMarkdown.Buffer (note.load_text ());
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

	public Notebook create_notebook (NotebookInfo info) requires (notebooks_model != null) {
        var notebook = notebook_provider.new_notebook (info);
        select_notebook (notebook);
        return notebook;
	}

	public Note create_note (string name) requires (notes_model != null) {
	    var n = notebook.new_note (name);
        select_note_at (0);
        update_note (n);
        return n;
	}

	public void change_notebook (Notebook notebook, NotebookInfo info) {
	    notebook_provider.change_notebook (notebook, info);
	    if (note_container == notebook) {
	        set_notebook (notebook);
	    }
	}

	public void change_note (Note note, string name, string extension = note.extension)
	    requires (note.notebook != null) {
        note.notebook.change_note (note, name, extension);
        update_note (note);
	}

	public void delete_notebook (Notebook notebook) {
	    set_notebook (null);
	    notebook_provider.delete_notebook (notebook);
        update_selected_notebook ();
	}

    public void restore_note (Note note) {
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
        file.move (dest, FileCopyFlags.NONE);
        select_notebook (dest_notebook);
        return true;
	}

    public void empty_trash () {
        notebook_provider.trash.delete_all ();
    }

	public Note? try_get_note_from_path (string path) {
	    if (path.length == 0)
	        return null;
		var note_data = path.split ("/");
	    if (note_data.length != 2)
	        return null;
        var notebook_name = note_data[0];
        var notebook = notebook_provider.notebooks
            .first_match ((it) => it.name == notebook_name);
        if (notebook == null)
            return null;
        notebook.load ();
        var note_name = note_data[1];
        return notebook.loaded_notes
            .first_match ((it) => it.name == note_name);
	}

	public string? generate_new_note_name () {
		if (notebook != null) {
		    return notebook.get_available_name ();
		}
		return null;
	}

	public void search (string? query) {
        search_sorter.target = query;
	}

	public void update_notebooks () {
        var model = new Gtk.SingleSelection (notebook_provider);
        model.can_unselect = true;
	    model.selection_changed.connect (() => {
	        var i = model.selected;
	        var notebooks = notebook_provider.notebooks;
	        if (i <= notebooks.size && i != -1) {
	            set_notebook (notebooks[(int) i]);
	        }
	    });
	    notebooks_model = model;
	    update_selected_notebook ();
	}
}

