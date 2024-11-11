
namespace FileUtils {
	public void save_to (File file, string text) {
		try {
			if (file.query_exists ()) {
				string etag_out;
				uint8[] text_data = {};
				file.load_contents (null, out text_data, out etag_out);
				if (text == (string) text_data) {
					return;
				}
				file.delete ();
			}
			// Let's make sure the directory exists we're trying to save to.
			// If it doesn't, create it.
			var path = file.get_parent ().get_parse_name ();
			var dir = File.new_for_path (path);
			if (!dir.query_exists ()) {
				dir.make_directory_with_parents ();
			}
			var data_stream = new DataOutputStream (
				file.create (FileCreateFlags.REPLACE_DESTINATION)
			);
			uint8[] data = text.data;
			var l = data.length;
			long written = 0;
			while (written < l) {
				written += data_stream.write (data[written:data.length]);
			}
		} catch (Error e) {
			error (e.message);
		}
	}

	// Recursively delete a directory and all of it's contents.
	public void recursive_delete (File path) {
		// Enumerate the children of the path we're deleting.
		GLib.FileEnumerator enumerator;
		try {
			enumerator = path.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
		} catch (Error e) {
			error (e.message);
		}

		FileInfo file_info;

		try {
			file_info = enumerator.next_file ();
		} catch (Error e) {
			file_info = null;
		}

		// Loop through the children.
		while (file_info != null) {
			// Get a handle to the child.
			var child = enumerator.get_child (file_info);

			// If the child is a directory, descend into it.
			// Otherwise just delete it.
			if (file_info.get_file_type() == FileType.DIRECTORY) {
				recursive_delete (child);
			} else {
				try {
					child.@delete ();
				} catch (Error e) {}
			}

			try {
				file_info = enumerator.next_file ();
			} catch (Error e) {
				file_info = null;
			}
		}

		// Once we're done, delete the root.
		try {
			path.@delete ();
		} catch (Error e) {}
	}

	// Expand the ~ operator in file names/paths.
	public string expand_home_directory (string path) {
		if (path[0] == '~') {
			var user_home = GLib.Environment.get_home_dir ();

			if (path[1] != '/' || path[1] != '/') {
				return user_home + "/" + path.substring (1, -1);
			} else {
				return user_home + path.substring (1, -1);
			}
		}

		return path;
	}
}
