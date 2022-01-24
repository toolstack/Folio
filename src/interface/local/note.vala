namespace Paper {
    public class LocalNote : Object, Note {

        public string name {
            get { return _name; }
        }

        public GtkSource.Buffer text {
            get { return (!) _text; }
        }

        public string path {
            owned get { return @"$(_notebook.path)/$name"; }
        }

        public Notebook notebook {
            get { return _notebook; }
        }

        public LocalNotebook _notebook;

        string _name;
        GtkSource.Buffer? _text = null;

        public LocalNote (string name, LocalNotebook notebook) {
            this._name = name;
            this._notebook = notebook;
        }

        public void change (string name, LocalNotebook notebook) {
            this._name = name;
            this._notebook = notebook;
        }

        public void load () {
            var language_manager = GtkSource.LanguageManager.get_default ();
            var language = language_manager.get_language ("markdown");
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
}
