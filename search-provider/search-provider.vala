
[DBus (name = "org.gnome.Shell.SearchProvider2")]
public class SearchProvider : Object {

    Settings settings = new Settings (Config.APP_ID);
	Folio.Provider notebook_provider = new Folio.Provider ();

    public SearchProvider () {
		settings.changed["notes-dir"].connect (() => {
            try {
                update_storage_dir ();
            } catch (Error e) {}
		});
        try {
            update_storage_dir ();
        } catch (Error e) {}
    }

    private HashTable<string, Folio.Note> notes;

    struct ResultWithDistance {
        string result;
        int distance;

        ResultWithDistance (string result, int distance) {
            this.result = result;
            this.distance = distance;
        }
    }

    public void update_storage_dir () throws Error {
		var path = settings.get_string ("notes-dir");
		var notes_dir = path.has_prefix ("~/") ? Environment.get_home_dir () + path[1:] : path;
        try {
            notebook_provider.set_directory (notes_dir);
            notebook_provider.load ();
            update_notes ();
        } catch (Error e) {}
    }

    public void update_notes () throws Error {
        var notebooks = notebook_provider.notebooks;
        notes = new HashTable<string, Folio.Note> (str_hash, str_equal);
        foreach (var notebook in notebooks) {
            notebook.load ();
            foreach (var note in notebook.loaded_notes) {
                notes.insert(note.id, note);
            }
            notebook.unload ();
        }
    }

    public string[] get_initial_result_set (string[] terms) throws Error {
        update_notes ();
        return get_subsearch_result_set ({}, terms);
    }

    public string[] get_subsearch_result_set (string[] _, string[] terms) throws Error {
        var results = new Gee.ArrayList<string> ();
        new Gee.ArrayList<string>.wrap (notes.get_keys_as_array ())
            .map<ResultWithDistance?> (x => {
                var name = x.split("/")[1].down ().normalize ();
                var query = string.joinv (" ", terms).down ().normalize ();
                var xd = Util.search_distance (name, query);
                return ResultWithDistance (x, xd);
            })
            .filter (x => x.distance < 5)
            .order_by ((a, b) => a.distance - b.distance)
            .foreach (x => results.add (x.result));
        return results.to_array ();
    }

    public HashTable<string, Variant>[] get_result_metas (string[] ids) throws Error {
        var metas = new HashTable<string, Variant>[ids.length];
        for (var i = 0; i < ids.length; i++) {
            var id = ids[i];
            metas[i] = new HashTable<string, Variant> (str_hash, str_equal);
            metas[i].insert ("id", id);
            metas[i].insert ("name", notes[id].name);
        }
        return metas;
    }

    public void launch_search (string[] terms, uint32 timestamp) throws Error {
        Process.spawn_command_line_async (
            "com.toolstack.Folio --launch-search " + Shell.quote (string.joinv (" ", terms))
        );
    }

    public void activate_result (string result_id, string[] terms, uint32 timestamp) throws Error {
        var note = notes[result_id];
        Process.spawn_command_line_async (
            "com.toolstack.Folio --open-note " + Shell.quote (note.id)
        );
    }
}

public class SearchProviderApp : Application {
    public SearchProviderApp () {
        Object (
            application_id: "com.toolstack.Folio.SearchProvider",
            flags: ApplicationFlags.IS_SERVICE
        );
    }

    private uint registration_id;

    public override bool dbus_register (DBusConnection connection, string object_path) {
        SearchProvider search_provider = new SearchProvider ();

        try {
            registration_id = connection.register_object (object_path, search_provider);
        }
        catch (IOError e) {
            error (@"Could not register service: $(e.message)");
        }

        return true;
    }

    public override void dbus_unregister (DBusConnection connection, string object_path) {
        connection.unregister_object (registration_id);
    }
}

int main (string[] args) {
    Gtk.init();
    Intl.setlocale (LocaleCategory.ALL, "");
    return new SearchProviderApp ().run (args);
}
