using Gee;

public interface Paper.Notebook : Object, ListModel {

    public abstract NotebookInfo info { get; }

    public string name { get { return info.name; } }
    public Gdk.RGBA color { get { return info.color; } }
    public NotebookIconType icon_type { get { return info.icon_type; } }

    public abstract string path { owned get; }

    public abstract Gee.List<Note>? loaded_notes { get; }

    public abstract void load ();
    public abstract void unload ();

    public abstract Note new_note (string name) throws ProviderError;
    public abstract void change_note (Note note, string name) throws ProviderError;
    public abstract void delete_note (Note note) throws ProviderError;
}
