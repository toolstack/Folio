using Gee;

public errordomain Folio.ProviderError {
    ALREADY_EXISTS,
    COULDNT_CREATE_FILE,
    NOTES_HAVENT_LOADED,
    COULDNT_DELETE,
    COULDNT_MOVE,
}

public class Folio.Provider : Object, ListModel {

    public Gee.List<Note> get_all_notes () {
        var notes = new ArrayList<Note> ();
        foreach (var notebook in notebooks) {
            notebook.load ();
            foreach (var note in notebook.loaded_notes) {
                notes.add (note);
            }
            // notebook.unload ();
        }
        return notes;
    }

    public Gee.List<Notebook> notebooks {
        get { return _notebooks; }
    }

    public Trash trash {
        get { return _trash; }
    }

    private Trash _trash;
    private ArrayList<Notebook>? _notebooks = null;

    public string notes_dir;

    public Provider (string? trash_name = null) {
        this._trash = new Trash (this, trash_name ?? "");
    }

    public void set_directory (string notes_dir) throws ProviderError {
        this.notes_dir = notes_dir;
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

        try {
            update_data ();
        } catch (Error e) {
            stderr.printf ("Error: update_data failed: %s\n", e.message);
        }
    }

    public Notebook new_notebook (NotebookInfo info) throws ProviderError {
        var path = @"$notes_dir/$(info.name)";
        var file = File.new_for_path (path);

        if (file.query_exists ()) {
            throw new ProviderError.ALREADY_EXISTS (@"Notebook at $path already exists");
        }
        try {
            file.make_directory_with_parents ();
        } catch (Error e) {
            throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't create file at $path: $(e.message)");
        }
        write_notebook_info (path, info);
        var notebook = new LocalNotebook (this, info);
        _notebooks.add (notebook);
        items_changed (_notebooks.size - 1, 0, 1);
        return notebook;
    }

    public void change_notebook (Notebook notebook, NotebookInfo info) throws ProviderError {
        var path = @"$notes_dir/$(info.name)";

        if (notebook.name != info.name) {
            var lnb = notebook as LocalNotebook;
            if (lnb != null) {
                var origina_path = lnb.path;
                var original_file = File.new_for_path (origina_path);
                var file = File.new_for_path (path);
                if (file.query_exists ()) {
                    throw new ProviderError.ALREADY_EXISTS (@"Notebook at $path already exists");
                }
                try {
                    original_file.set_display_name(info.name);
                } catch (Error e) {
                    throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't change $origina_path to $path: $(e.message)");
                }
            }
        }
        write_notebook_info (path, info);
        ((LocalNotebook) notebook).change (this, info);
        int i = _notebooks.index_of (notebook);
        items_changed (i, 1, 1);
    }

    public void delete_notebook (Notebook notebook) throws ProviderError {
        var lnb = notebook as LocalNotebook;
        var path = "";
        if (lnb != null) {
            path = lnb.path;
        } else {
            throw new ProviderError.COULDNT_DELETE (@"Notebook doesn't exist");
        }
        var file = File.new_for_path (path);
        if (!file.query_exists ()) {
            throw new ProviderError.COULDNT_DELETE (@"Notebook at '$path' doesn't exist");
        }
        {
            var trashed_path = @"$(notes_dir)/.trash/$(notebook.name)";
            FileInfo file_info;
            var trash_dir = File.new_for_path (trashed_path);
            if (!trash_dir.query_exists ()) {
                try {
                    trash_dir.make_directory_with_parents ();
                } catch (Error e) {
                    throw new ProviderError.COULDNT_CREATE_FILE (@"Couldn't create trash folder at '$path'");
                }
            }
            try {
                var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();
                    var orig_file = enumerator.get_child (file_info);
                    var trashed_file = File.new_for_path (@"$trashed_path/$name");
                    orig_file.move (trashed_file, FileCopyFlags.OVERWRITE);
                }
            } catch (Error e) {
                throw new ProviderError.COULDNT_DELETE (@"Couldn't move notebook from $path, to $trashed_path");
            }
            trash.unload ();
        }
        try {
            file.@delete ();
        } catch (Error e) {
            message (e.message);
            throw new ProviderError.COULDNT_DELETE (@"Couldn't delete notebook at $path");
        }
        int i = _notebooks.index_of (notebook);
        _notebooks.remove_at (i);
        items_changed (i, 1, 0);
    }

    public void load () {
        _notebooks = list_directory (notes_dir);
        items_changed (0, 0, _notebooks.size);
    }

    public void unload () {
        var s = _notebooks.size;
        _notebooks = null;
        items_changed (0, s, 0);

    }

    public Type get_item_type () {
        return typeof (LocalNotebook);
    }

    public uint get_n_items () {
        if (_notebooks == null) return 0;
        return _notebooks.size;
    }

    public Object? get_item (uint i) {
        if (_notebooks == null) return null;
        return (i >= _notebooks.size) ? null : _notebooks.@get((int) i);
    }

    private ArrayList<Notebook> list_directory (string notes_dir) {
        var notebooks = new ArrayList<Notebook> ();
        var dir = File.new_for_path (notes_dir);
        try {
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                if (file_info.get_file_type () != FileType.DIRECTORY) continue;
                var name = file_info.get_name ();
                if (name[0] == '.') continue;
                var path = @"$notes_dir/$name";
                notebooks.add (new LocalNotebook (
                    this,
                    read_notebook_info (name, path)
                ));
            }
        } catch (Error err) {
            stderr.printf ("Error: list_directory failed: %s\n", err.message);
        }
        return notebooks;
    }

    private void update_data () throws Error {
        var version_file = File.new_for_path (@"$notes_dir/.version");
        if (version_file.query_exists ()) {
            string etag_out;
            uint8[] text_data = {};
            version_file.load_contents (null, out text_data, out etag_out);
            var last_version = (string) text_data;
            if (last_version == Config.VERSION)
                return;
            version_file.@delete ();
        }
        var data_stream = new DataOutputStream (version_file.create (FileCreateFlags.REPLACE_DESTINATION));
        uint8[] data = Config.VERSION.data;
        var l = data.length;
        long written = 0;
        while (written < l) {
            written += data_stream.write (data[written:data.length]);
        }
        var notebooks_enumerator = File.new_for_path (notes_dir).enumerate_children (FileAttribute.STANDARD_NAME, 0);
        FileInfo notebook_file_info;
        while ((notebook_file_info = notebooks_enumerator.next_file ()) != null) {
            var notebook_path = @"$notes_dir/$(notebook_file_info.get_name ())";
            var dir = File.new_for_path (notebook_path);
            if (dir.query_file_type (0) != FileType.DIRECTORY)
                continue;
            try {
                var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();
                    if (name != ".color") continue;
                    File.new_for_path (@"$notebook_path/.config/").make_directory ();
                    var dest = File.new_for_path (@"$notebook_path/.config/color");
                    File.new_for_path (@"$notebook_path/.color").move (dest, 0);
                    break;
                }
            } catch (Error e) {
                error (@"update_data failed: $(e.message)\n");
            }
        }
    }

    private Gdk.RGBA default_color = Gdk.RGBA ();

    construct {
        default_color.parse ("#2ec27eff");
    }

    private void write_notebook_info (string notebook_path, NotebookInfo info) {
        try {
	        write_data_file (notebook_path, "color", info.color.to_string ());
        } catch (Error e) {
            stderr.printf ("Couldn't write color: %s\n", e.message);
        }
        try {
	        write_data_file (notebook_path, "icon_type", info.icon_type.to_string ());
        } catch (Error e) {
            stderr.printf ("Couldn't write icon type: %s\n", e.message);
        }
        try {
            write_data_file (notebook_path, "icon_name", info.icon_name);
        } catch (Error e) {
            stderr.printf ("Couldn't write icon name: %s\n", e.message);
        }
    }

    private NotebookInfo read_notebook_info (string name, string notebook_path) throws Error {
        return new NotebookInfo (
            name,
            read_color (notebook_path),
            read_icon_type (notebook_path),
            read_data_file (notebook_path, "icon_name")
        );
    }

    private Gdk.RGBA read_color (string notebook_path) throws Error {
        var data = read_data_file (notebook_path, "color");
        if (data == null) {
            return default_color;
        }
        var rgba = Gdk.RGBA ();
        if (!rgba.parse (data.strip ())) {
            return default_color;
        }
        return rgba;
    }

    private NotebookIconType read_icon_type (string notebook_path) throws Error {
        var data = read_data_file (notebook_path, "icon_type");
        if (data == null) {
            return NotebookIconType.DEFAULT;
        }
        return NotebookIconType.from_string (data);
    }

    private void write_data_file (string notebook_path, string data_name, string? data) throws Error {
        var path = @"$notebook_path/.config/$data_name";
        var f = File.new_for_path (path);
        if (f.query_exists ())
            f.@delete ();
        if (data == null) return;
        var d = f.get_parent ();
        if (!d.query_exists ())
            d.make_directory_with_parents ();
        var fs = f.create (FileCreateFlags.REPLACE_DESTINATION);
	    var stream = new DataOutputStream (fs);
	    stream.put_string (data);
    }

    private string? read_data_file (string notebook_path, string data_name) throws Error {
        var path = @"$notebook_path/.config/$data_name";
        var f = File.new_for_path (path);
        if (!f.query_exists ())
            return null;
        string etag_out;
        uint8[] text_data = {};
        f.load_contents (null, out text_data, out etag_out);
        return (string) text_data;
    }
}
