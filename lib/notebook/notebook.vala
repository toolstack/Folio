using Gee;

public interface Paper.Notebook : Object, ListModel, NoteContainer {

    public Gdk.RGBA color { get { return info.color; } }
    public NotebookIconType icon_type { get { return info.icon_type; } }

    public abstract NotebookInfo info { get; }

    public abstract string path { owned get; }

    public abstract Note new_note (string name, string extension = "md") throws ProviderError;
    public abstract void change_note (Note note, string name, string extension = note.extension) throws ProviderError;
    public abstract void delete_note (Note note) throws ProviderError;
    public abstract uint get_index_of(Note? note);

    public string get_available_name (int i = 0) {
        var name = i == 0 ? "Note" : @"Note $i";
        var s = loaded_notes.size;
        for (int j = 0; j < s; j++) {
            if (loaded_notes.@get (j).name == name)
                return get_available_name (++i);
        }
        return name;
    }

    public bool equals (Notebook other) {
        return this.name == other.name;
    }
}
