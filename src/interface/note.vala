
public class Paper.Note : Object {

    public string name {
        get { return _name; }
    }

    public GtkSource.Buffer text {
        get { return (!) _text; }
    }

    public string path {
        owned get { return @"$(_notebook.path)/$name.md"; }
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
    GtkSource.Buffer? _text = null;

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
        var language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
        _text = new GtkSource.Buffer.with_language (language);
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
        try {
            var file = File.new_for_path (path);
            if (file.query_exists ()) {
                string etag_out;
                uint8[] text_data = {};
                file.load_contents (null, out text_data, out etag_out);
                if (_text.text == (string) text_data) {
                    return;
                }
                file.delete ();
            }
            var data_stream = new DataOutputStream (
                file.create (FileCreateFlags.REPLACE_DESTINATION)
            );
            uint8[] data = _text.text.data;
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
