namespace Paper {
    public class LocalTrashedNote : Object, Note {

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

        public LocalTrashedNotebook _notebook;

        string _name;
        GtkSource.Buffer? _text = null;

        public LocalTrashedNote (string name, LocalTrashedNotebook notebook) {
            this._name = name;
            this._notebook = notebook;
        }

        public void change (string name, LocalTrashedNotebook notebook) {
            this._name = name;
            this._notebook = notebook;
        }

        public void load () {
            var language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
            _text = new GtkSource.Buffer.with_language (language);
	        {
	            var manager = new GtkSource.StyleSchemeManager ();
	            var scheme = manager.get_scheme ("paper");
	            _text.style_scheme = scheme;
	        }
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
            error ("Can't edit trashed notes");
        }
    }
}
