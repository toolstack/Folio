using Gee;

namespace Paper {
    public class LocalNotebook : Object, ListModel, Notebook {

        public string name {
            get { return _name; }
        }

        public Gdk.RGBA color {
            get { return _color; }
        }

        public Gee.List<Note>? loaded_notes {
            get { return _loaded_notes; }
        }

        public string path {
            owned get { return @"$(provider.notes_dir)/$name"; }
        }

        ArrayList<Note>? _loaded_notes = null;

        string _name;
        Gdk.RGBA _color;
        LocalProvider provider;

        public LocalNotebook (LocalProvider provider, string name, Gdk.RGBA color) {
            this.provider = provider;
            this._name = name;
            this._color = color;
        }

        public void load () {
            if (_loaded_notes != null) return;
            _loaded_notes = new ArrayList<Note> ();
            var dir = File.new_for_path (path);
            try {
                var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();
                    if (name[0] == '.') continue;
                    _loaded_notes.add (new LocalNote (
                        name,
                        this
                    ));
                }
            } catch (Error e) {
                error (@"Notebook loading failed: $(e.message)\n");
            }
        }

        public void unload () {
            _loaded_notes = null;
        }

        public void change (LocalProvider provider, string name, Gdk.RGBA color) {
            this.provider = provider;
            this._name = name;
            this._color = color;
        }

        public Note new_note (string name) throws ProviderError {
            load ();
            var path = @"$path/$name";
            var file = File.new_for_path (path);
            if (file.query_exists ()) {
                throw new ProviderError.ALREADY_EXISTS (@"Note \"$name\" already exists in $(this.name)");
            }
            try {
                file.create (FileCreateFlags.NONE);
            } catch (Error e) {
                 throw new ProviderError.COULDNT_CREATE_FILE("Couldn't create note at \"$path\"");
            }
            var note = new LocalNote (name, this);
            _loaded_notes.insert (0, note);
            items_changed (0, 0, 1);
            return note;
        }

        public void change_note (Note note, string name) throws ProviderError {
            load ();
            if (note.name != name) {
                var n = (LocalNote) note;
                var original_path = n.path;
                var original_file = File.new_for_path (original_path);
                var path = @"$path/$name";
                var file = File.new_for_path (path);
                if (file.query_exists ()) {
                    throw new ProviderError.ALREADY_EXISTS (@"Note at $path already exists");
                }
                try {
                    original_file.set_display_name(name);
                } catch (Error e) {
                    throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't change $original_path to $path: $(e.message)");
                }

                n.change (name, this);
	            int i = _loaded_notes.index_of (note);
                items_changed (i, 1, 1);
            }
        }

        public void delete_note (Note note) throws ProviderError {
            load ();
            var n = (LocalNote) note;
            var path = n.path;
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                throw new ProviderError.COULDNT_DELETE (@"Couldn't delete note at $path");
            }
            var trashed_dir_path = @"$(provider.notes_dir)/.trash/$(n.notebook.name)";
            var trashed_path = @"$trashed_dir_path/$(n.name)";
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
            return typeof (LocalNote);
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
}
