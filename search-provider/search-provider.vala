
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
                notes.insert (note.name, note);
            }
            notebook.unload ();
        }
        return notes.get_keys_as_array ();
    }

    public string[] get_subsearch_result_set (string[] previous_results, string[] terms) throws Error {
        string[] result_list = {};
        foreach (var name in previous_results)
            foreach (var term in terms) {
                if (cancellable.is_cancelled ()) return result_list;
                if (match(name, term)) {
                    result_list += name;
                    break;
                }
            }
        return result_list;
    }

    public HashTable<string, Variant>[] get_result_metas (string[] ids) throws Error {
        var metas = new HashTable<string, Variant>[ids.length];
        for (var i = 0; i < ids.length; i++) {
            var id = ids[i];
            metas[i] = new HashTable<string, Variant> (str_hash, str_equal);
            metas[i].insert ("id", id);
            metas[i].insert ("name", id);
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
            "io.posidon.Paper --open-note " + Shell.quote (note.notebook.name + "/" + note.name)
        );
    }

    [DBus (visible = false)]
    private bool match (string a, string b) {
        var a_tokens = a.tokenize_and_fold (null, null);
        var b_tokens = b.tokenize_and_fold (null, null);
        foreach (var at in a_tokens)
            foreach (var bt in b_tokens)
                if (at.contains (bt) || bt.contains (at))
                    return true;
        return false;
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
