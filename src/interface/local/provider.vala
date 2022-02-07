using Gee;

namespace Paper {
    public class LocalProvider : Object, ListModel, Provider {

        public override Gee.List<Notebook> notebooks {
            get { return _notebooks; }
        }

        public override Trash trash {
            get { return _trash; }
        }

        Trash _trash;
        ArrayList<Notebook> _notebooks = new ArrayList<Notebook> ();

        public string notes_dir;

        public LocalProvider.from_directory (string notes_dir) throws ProviderError {
            this.notes_dir = notes_dir;
            this._trash = new LocalTrash (this);

            var file = File.new_for_path (notes_dir);

            if (file.query_exists ()) {
                if (file.query_file_type (0) != FileType.DIRECTORY) {
                    error (@"File $(file.get_path ()) isn't a directory");
                }
            } else try {
                file.make_directory_with_parents ();
            } catch (Error err) {
                throw new ProviderError.COULDNT_CREATE_FILE (@"File $(file.get_path ()) couldn't be created");
            }

            list_directory(notes_dir);
        }

        public Notebook new_notebook (string name, Gdk.RGBA color) throws ProviderError {
            var path = @"$notes_dir/$name";
            var file = File.new_for_path (path);

            if (file.query_exists ()) {
                throw new ProviderError.ALREADY_EXISTS (@"Notebook at $path already exists");
            }
            try {
                file.make_directory_with_parents ();
            } catch (Error e) {
                throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't create file at $path: $(e.message)");
            }
            try {
                write_color (path, color);
            } catch (Error e) {
                throw new ProviderError.COULDNT_CREATE_FILE ("Couldn't write color");
            }
            var notebook = new LocalNotebook (this, name, color);
            _notebooks.add (notebook);
            items_changed (_notebooks.size - 1, 0, 1);
            return notebook;
        }

        public void change_notebook (Notebook notebook, string name, Gdk.RGBA color) throws ProviderError {
            var path = @"$notes_dir/$name";

            if (notebook.name != name) {
                var origina_path = (notebook as LocalNotebook).path;
                var original_file = File.new_for_path (origina_path);
                var file = File.new_for_path (path);
                if (file.query_exists ()) {
                    throw new ProviderError.ALREADY_EXISTS (@"Notebook at $path already exists");
                }
                try {
                    original_file.set_display_name(name);
                } catch (Error e) {
                    throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't change $origina_path to $path: $(e.message)");
                }
            }
            try {
                write_color (path, color);
            } catch (Error e) {
                throw new ProviderError.COULDNT_CREATE_FILE ("Couldn't write color");
            }
            ((LocalNotebook) notebook).change (this, name, color);
	        int i = _notebooks.index_of (notebook);
            items_changed (i, 1, 1);
        }

        public void delete_notebook (Notebook notebook) throws ProviderError {
            var path = (notebook as LocalNotebook).path;
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                throw new ProviderError.COULDNT_DELETE (@"Couldn't delete notebook at $path");
            }
            var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            bool can_delete = false;
            var file_info = enumerator.next_file ();
            if (file_info != null) {
                if (file_info.get_name () == ".color") {
                    if (enumerator.next_file () == null) {
                        enumerator.get_child (file_info).@delete ();
                        can_delete = true;
                    }
                }
            } else can_delete = true;
            if (can_delete) try {
                message (@"$(enumerator.has_pending ()) $can_delete aaa");
                file.@delete ();
            } catch (Error e) {
                message (e.message);
                throw new ProviderError.COULDNT_DELETE (@"Couldn't delete notebook at $path");
            }
            else {
                var trashed_path = @"$(notes_dir)/.trash/$(notebook.name)";
                try {
                    var trashed_file = File.new_for_path (trashed_path);
                    file.move (trashed_file, FileCopyFlags.OVERWRITE);
                    trash.unload ();
                } catch (Error e) {
                    throw new ProviderError.COULDNT_DELETE (@"Couldn't move notebook from $path, to $trashed_path");
                }
            }
	        int i = _notebooks.index_of (notebook);
	        _notebooks.remove_at (i);
            items_changed (i, 1, 0);
        }

        public Type get_item_type () {
            return typeof (LocalNotebook);
        }

        public uint get_n_items () {
            return _notebooks.size;
        }

        public Object? get_item (uint i) {
            return (i >= _notebooks.size) ? null : _notebooks.@get((int) i);
        }

        private void list_directory (string notes_dir) {
            var dir = File.new_for_path (notes_dir);
            try {
                var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();
                    if (name[0] == '.') continue;
                    var path = @"$notes_dir/$name";
                    _notebooks.add (new LocalNotebook (
                        this,
                        name,
                        read_color (path)
                    ));
                }
            } catch (Error err) {
                stderr.printf ("Error: list_directory failed: %s\n", err.message);
            }
        }

        private Gdk.RGBA default_color = Gdk.RGBA ();

        construct {
            default_color.parse ("#2ec27eff");
        }

        private Gdk.RGBA read_color (string notebook_path) throws Error {
            var path = @"$notebook_path/.color";
            var f = File.new_for_path (path);
            if (!f.query_exists ()) {
                write_color (notebook_path, default_color);
                return default_color;
            }
            string etag_out;
            uint8[] text_data = {};
            f.load_contents (null, out text_data, out etag_out);
            var rgba = Gdk.RGBA ();
            if (!rgba.parse (((string) text_data).strip ())) {
                write_color (notebook_path, default_color);
                return default_color;
            }
            return rgba;
        }

        private void write_color (string notebook_path, Gdk.RGBA color) throws Error {
            var path = @"$notebook_path/.color";
            var f = File.new_for_path (path);
            if (f.query_exists ()) {
                f.@delete ();
            }
            var fs = f.create (FileCreateFlags.REPLACE_DESTINATION);
		    var stream = new DataOutputStream (fs);
		    stream.put_string (color.to_string ());
        }
    }
}
