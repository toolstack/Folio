
[DBus (name = "org.gnome.Shell.SearchProvider2")]
public class SearchProvider : Object {
    private Cancellable cancellable;

    public SearchProvider () {}

    ~SearchProvider () {
        cancel ();
    }

    [DBus (visible = false)]
    public void cancel () {
        if (cancellable != null)
            cancellable.cancel ();
    }

    private HashTable<string, Paper.Note> notes;

    public string[] get_initial_result_set (string[] terms) throws Error {
	    var settings = new Settings (Config.APP_ID);
		var notes_dir = settings.get_string ("notes-dir");
        var notebooks = new Paper.LocalProvider.from_directory (notes_dir).notebooks;
        notes = new HashTable<string, Paper.Note> (str_hash, str_equal);
        foreach (var notebook in notebooks) {
            notebook.load ();
            foreach (var note in notebook.loaded_notes) {
                notes.insert(note.id, note);
            }
            notebook.unload ();
        }
        return get_subsearch_result_set(notes.get_keys_as_array (), terms);
    }

    public string[] get_subsearch_result_set (string[] previous_results, string[] terms) throws Error {
        var result_list = new Gee.ArrayList<string>.wrap (previous_results);
        result_list.sort ((a, b) => {
            var a_name = a.split("/")[1].down ();
            var b_name = b.split("/")[1].down ();
            var query = string.joinv (" ", terms).down ();
            var ad = Util.damerau_levenshtein_distance (a_name, query);
            var bd = Util.damerau_levenshtein_distance (b_name, query);
            return ad - bd;
        });
        return result_list.to_array ();
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
            "io.posidon.Paper --launch-search " + Shell.quote (string.joinv (" ", terms))
        );
    }

    public void activate_result (string result_id, string[] terms, uint32 timestamp) throws Error {
        var note = notes[result_id];
        Process.spawn_command_line_async (
            "io.posidon.Paper --open-note " + Shell.quote (note.id)
        );
    }
}

public class SearchProviderApp : Application {
    public SearchProviderApp () {
        Object (
            application_id: "io.posidon.Paper.SearchProvider",
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

        shutdown.connect (() => {
            search_provider.cancel ();
        });

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
