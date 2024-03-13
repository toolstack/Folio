
public class Folio.Note : Object {

	public string name {
		get { return _name; }
	}

	public string extension {
		get { return _extension; }
	}

	public inline string file_name {
		owned get { return @"$_name.$_extension"; }
	}

	public inline bool is_markdown {
		get { return _extension == "md"; }
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
	string _extension;
	Notebook _notebook;
	DateTime _time_modified;

	public Note (string name, string extension, Notebook notebook, DateTime time_modified) {
		this._name = name;
		this._extension = extension;
		this._notebook = notebook;
		this._time_modified = time_modified;
	}

	public void change (string name, string extension, Notebook notebook, DateTime time_modified) {
		this._name = name;
		this._extension = extension;
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
				// Make sure the last character of the file is a return, otherwise some of the regex's will break.
				if (text_data[text_data.length - 1] != 10) { text_data += 10; }
				return (string) text_data;
			}
		} catch (Error e) {
			error (e.message);
		}
		return null;
	}

	public bool validate_save () {
		// Lets make sure the file hasn't changed on disk before saving it.
		var file_handle = File.new_for_path (path);
		FileInfo file_info;
		DateTime file_time;

		try {
			file_info = file_handle.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
			file_time = file_info.get_modification_date_time ();
		} catch (Error e) {
			file_time = this._time_modified;
		}

		if ( !file_time.to_local ().equal (this._time_modified)) {
			return false;
		}

		return true;
	}

	public void save (string text) {
		// Lets make sure the file hasn't changed on disk before saving it.
		var file_handle = File.new_for_path (path);
		FileInfo file_info;
		DateTime file_time;

		// Save the file.
		FileUtils.save_to (file_handle, text);
		// Now get the updated file time and store it in the note.
		try {
			file_info = file_handle.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
			file_time = file_info.get_modification_date_time ();
			this._time_modified = file_time;
		} catch (Error e) {}
	}

	public bool equals (Note other) {
		return this.name == other.name && this.notebook == other.notebook;
	}
}
