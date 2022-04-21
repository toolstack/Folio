
public class Paper.Note : Object {

    public string name {
        get { return _name; }
    }

    public inline string file_name {
        owned get { return @"$_name.md"; }
    }

    public GtkMarkdown.Buffer text {
        get { return (!) _text; }
    }

    public string path {
        owned get { return @"$(_notebook.path)/$file_name"; }
    }

    public DateTime time_modified {
        get { return _time_modified; }
    }

    public Notebook notebook {
        get { return _notebook; }
    }

    string _name;
    Notebook _notebook;
    DateTime _time_modified;
    GtkMarkdown.Buffer? _text = null;

    public Note (string name, Notebook notebook, DateTime time_modified) {
        this._name = name;
        this._notebook = notebook;
        this._time_modified = time_modified;
    }

    public void change (string name, Notebook notebook, DateTime time_modified) {
        this._name = name;
        this._notebook = notebook;
        this._time_modified = time_modified;
    }

    public void load () {
        _text = new GtkMarkdown.Buffer();
        try {
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } else {
                string etag_out;
                uint8[] text_data = {};
                file.load_contents (null, out text_data, out etag_out);
                _text.text = (string) text_data;
            }
        } catch (Error e) {
            error (e.message);
        }
    }

    public void unload () {
        _text = null;
    }

    public void save () {
        save_to (File.new_for_path (path));
    }

    public void save_to (File file) {
        try {
            Gtk.TextIter start, end;
            _text.get_start_iter (out start);
            _text.get_end_iter (out end);
            var save_text = _text.get_text(start, end, true);
            if (file.query_exists ()) {
                string etag_out;
                uint8[] text_data = {};
                file.load_contents (null, out text_data, out etag_out);
                if (save_text == (string) text_data) {
                    return;
                }
                file.delete ();
            }
            var data_stream = new DataOutputStream (
                file.create (FileCreateFlags.REPLACE_DESTINATION)
            );
            uint8[] data = save_text.data;
            var l = data.length;
            long written = 0;
            while (written < l) {
                written += data_stream.write (data[written:data.length]);
            }
        } catch (Error e) {
            error (e.message);
        }
    }
}
