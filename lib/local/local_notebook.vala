using Gee;

public class Paper.LocalNotebook : Object, ListModel, NoteContainer, Notebook {

    public string name { get { return info.name; } }

    public string path {
        owned get { return @"$(provider.notes_dir)/$name"; }
    }

    public NotebookInfo info {
        get { return _info; }
    }

    public Gee.List<Note>? loaded_notes {
        get { return _loaded_notes; }
    }

    ArrayList<Note>? _loaded_notes = null;

    NotebookInfo _info;
    LocalProvider provider;

    public LocalNotebook (LocalProvider provider, NotebookInfo info) {
        this.provider = provider;
        this._info = info;
    }

    public void load () {
        if (_loaded_notes != null) return;
        _loaded_notes = new ArrayList<Note> ();
        var dir = File.new_for_path (path);
        try {
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
                    this,
                    mod_time
                ));
            }
        } catch (Error e) {
            error (@"Notebook loading failed: $(e.message)\n");
        }
        _loaded_notes.sort ((a, b) => b.time_modified.compare(a.time_modified));
    }

    public void unload () {
        _loaded_notes = null;
    }

    public void change (LocalProvider provider, NotebookInfo info) {
        this.provider = provider;
        this._info = info;
    }

    public Note new_note (string name) throws ProviderError {
        load ();
        var file_name = @"$name.md";
        var path = @"$path/$file_name";
        var file = File.new_for_path (path);
        if (file.query_exists ()) {
            throw new ProviderError.ALREADY_EXISTS (@"Note \"$name\" already exists in $(this.name)");
        }
        try {
            file.create (FileCreateFlags.NONE);
        } catch (Error e) {
             throw new ProviderError.COULDNT_CREATE_FILE("Couldn't create note at \"$path\"");
        }
        var note = new Note (name, this, new DateTime.now ());
        _loaded_notes.insert (0, note);
        items_changed (0, 0, 1);
        return note;
    }

    public void change_note (Note note, string name) throws ProviderError {
        load ();
        if (note.name != name) {
            var original_path = note.path;
            var original_file = File.new_for_path (original_path);
            var file_name = @"$name.md";
            var path = @"$path/$file_name";
            var file = File.new_for_path (path);
            if (file.query_exists ()) {
                throw new ProviderError.ALREADY_EXISTS (@"Note at $path already exists");
            }
            try {
                original_file.set_display_name(file_name);
            } catch (Error e) {
                throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't change $original_path to $path: $(e.message)");
            }

            note.change (name, this, new DateTime.now ());
            int i = _loaded_notes.index_of (note);
            items_changed (i, 1, 1);
        }
    }

    public void delete_note (Note note) throws ProviderError {
        load ();
        var path = note.path;
        var file = File.new_for_path (path);
        if (!file.query_exists ()) {
            throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
        }
        var trashed_dir_path = @"$(provider.notes_dir)/.trash/$(note.notebook.name)";
        var trashed_path = @"$trashed_dir_path/$(note.file_name)";
        try {
            var trashed_dir = File.new_for_path (trashed_dir_path);
            if (!trashed_dir.query_exists ()) {
                trashed_dir.make_directory_with_parents ();
            }
            var trashed_file = File.new_for_path (trashed_path);
            file.move (trashed_file, FileCopyFlags.OVERWRITE);
            provider.trash.unload ();
        } catch (Error e) {
            throw new ProviderError.COULDNT_DELETE (@"Couldn't move note from $path, to $trashed_path");
        }
        int i = _loaded_notes.index_of (note);
        _loaded_notes.remove_at (i);
        items_changed (i, 1, 0);
    }

    public Type get_item_type () {
        return typeof (Note);
    }

    public uint get_n_items () {
        if (_loaded_notes == null)
            error (@"Notebook \"$name\": Notes haven't loaded yet");
        return _loaded_notes.size;
    }

    public Object? get_item (uint i) {
        if (_loaded_notes == null)
            error (@"Notebook \"$name\": Notes haven't loaded yet");
        return (i >= _loaded_notes.size) ? null : _loaded_notes.@get((int) i);
    }
}
