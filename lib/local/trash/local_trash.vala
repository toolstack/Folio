using Gee;

public class Paper.LocalTrash : Object, ListModel, NoteContainer, Trash {

    public string name {
        get { return _name; }
    }

    public Gee.List<Note>? loaded_notes {
        get { return _loaded_notes; }
    }

    public string path {
        owned get { return @"$(provider.notes_dir)/.trash"; }
    }

    private ArrayList<Note>? _loaded_notes = null;
    private LocalProvider provider;
    private string _name;

    public LocalTrash (LocalProvider provider, string name) {
        this.provider = provider;
        this._name = name;
    }

    public void load () {
        if (_loaded_notes != null) return;
        _loaded_notes = new ArrayList<Note> ();
        var dir = File.new_for_path (path);
        if (dir.query_exists ()) {
            if (dir.query_file_type (0) != FileType.DIRECTORY) {
                error (@"Trash directory $(dir.get_path ()) isn't a directory");
            }
        } else try {
            dir.make_directory_with_parents ();
        } catch (Error err) {
            throw new ProviderError.COULDNT_CREATE_FILE (@"Trash directory $(dir.get_path ()) couldn't be created");
        }
        try {
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                var name = file_info.get_name ();
                if (name[0] == '.') continue;
                var notebook = new LocalTrashedNotebook (this, new NotebookInfo (name));
                load_notebook (notebook);
            }
        } catch (Error e) {
            error (@"Notebook loading failed: $(e.message)\n");
        }
    }

    public void unload () {
        _loaded_notes = null;
    }

    private void load_notebook (LocalTrashedNotebook notebook) {
        var dir = File.new_for_path (notebook.path);
        var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.TIME_MODIFIED, 0);
        FileInfo file_info;
        while ((file_info = enumerator.next_file ()) != null) {
            var name = file_info.get_name ();
            if (name[0] == '.') continue;
            if (name.has_suffix (".md"))
                name = name.substring (0, name.length - 3);
            else continue;
            var mod_time = (!) file_info.get_modification_date_time ();
            _loaded_notes.add (new Note (
                name,
                notebook,
                mod_time
            ));
        }
        _loaded_notes.sort ((a, b) => b.time_modified.compare(a.time_modified));
    }

    public void delete_note (Note note) throws ProviderError {
        load ();
        var path = note.path;
        var file = File.new_for_path (path);
        if (!file.query_exists ()) {
            throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
        }
        try {
            file.@delete ();
        } catch (Error e) {
            throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
        }
        int i = _loaded_notes.index_of (note);
        _loaded_notes.remove_at (i);
        items_changed (i, 1, 0);
    }

    public void delete_all () throws ProviderError {
        load ();
        foreach (var note in _loaded_notes) {
            var path = note.path;
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
            }
            try {
                file.@delete ();
            } catch (Error e) {
                throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
            }
        }
        var l = _loaded_notes.size;
        _loaded_notes = new ArrayList<Note> ();
        items_changed (0, l, 0);
    }

    public void restore_note (Note note) throws ProviderError {
        load ();
        var path = note.path;
        var file = File.new_for_path (path);
        if (!file.query_exists ()) {
            throw new ProviderError.COULDNT_MOVE (@"Couldn't restore note at $path");
        }
        var restore_dir_path = @"$(provider.notes_dir)/$(note.notebook.name)";
        var restore_path = @"$restore_dir_path/$(note.file_name)";
        var restore_file = File.new_for_path (restore_path);
        if (restore_file.query_exists ()) {
            throw new ProviderError.ALREADY_EXISTS (@"Couldn't move from $path, to $restore_path, file already axists");
        }
        try {
            var restore_dir = File.new_for_path (restore_dir_path);
            if (!restore_dir.query_exists ()) {
                restore_dir.make_directory_with_parents ();
            }
            file.move (restore_file, 0);
        } catch (Error e) {
            message (e.message);
            throw new ProviderError.COULDNT_MOVE (@"Couldn't restore note at $path");
        }
        int i = _loaded_notes.index_of (note);
        _loaded_notes.remove_at (i);
        items_changed (i, 1, 0);
    }

    public Type get_item_type () {
        return typeof (Note);
    }

    public uint get_n_items () {
        check_notes_loaded ();
        return _loaded_notes.size;
    }

    public Object? get_item (uint i) {
        check_notes_loaded ();
        return (i >= _loaded_notes.size) ? null : _loaded_notes.@get((int) i);
    }

    private inline void check_notes_loaded () {
        if (_loaded_notes == null) {
            error ("Notes haven't loaded yet");
        }
    }
}
