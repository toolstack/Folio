
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

	private string _name;
	private string _extension;
	private Notebook _notebook;
	private DateTime _time_modified;

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
		uint8[] text_data = {};

		try {
			var file = File.new_for_path (path);
			if (!file.query_exists ()) {
				file.create (FileCreateFlags.REPLACE_DESTINATION);
			} else {
				string etag_out;
				file.load_contents (null, out text_data, out etag_out);
				// Make sure the last character of the file is a return, otherwise some of the regex's will break.
				if (text_data[text_data.length - 1] != 10) { text_data += 10; }
			}
			update_note_time ();
		} catch (Error e) {
			error (e.message);
		}
		if (text_data.length > 0) {
			return (string)text_data;
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

	public DateTime update_note_time () {
		var file_handle = File.new_for_path (path);
		FileInfo file_info;
		DateTime file_time = _time_modified;

		try {
			file_info = file_handle.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
			file_time = file_info.get_modification_date_time ();
		} catch (Error e) {}

		if (!file_time.equal (_time_modified)) {
			_time_modified = file_time;
		}

		return _time_modified;
	}

	public void save (string text) {
		// Lets make sure the file hasn't changed on disk before saving it.
		var file_handle = File.new_for_path (path);
		// Save the file.
		FileUtils.save_to (file_handle, text);
		// Now get the updated file time and store it in the note.
		update_note_time ();
	}

	public bool equals (Note other) {
		return this.name == other.name && this.notebook == other.notebook;
	}
}
