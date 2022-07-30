
public class Paper.Note : Object {

    public string name {
        get { return _name; }
    }

    public inline string file_name {
        owned get { return @"$_name.md"; }
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

    public string id {
        owned get { return @"$(_notebook.name)/$name"; }
    }

    string _name;
    Notebook _notebook;
    DateTime _time_modified;

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

    public string? load_text () {
        try {
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } else {
                string etag_out;
                uint8[] text_data = {};
                file.load_contents (null, out text_data, out etag_out);
                return (string) text_data;
            }
        } catch (Error e) {
            error (e.message);
        }
        return null;
    }

    public void save (string text) {
        FileUtils.save_to (File.new_for_path (path), text);
    }

    public bool equals (Note other) {
        return this.name == other.name && this.notebook == other.notebook;
    }
}
