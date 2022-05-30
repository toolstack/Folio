using Gee;

public interface Paper.Notebook : Object, ListModel, NoteContainer {

    public Gdk.RGBA color { get { return info.color; } }
    public NotebookIconType icon_type { get { return info.icon_type; } }

    public abstract NotebookInfo info { get; }

    public abstract string path { owned get; }

    public abstract Note new_note (string name) throws ProviderError;
    public abstract void change_note (Note note, string name) throws ProviderError;
    public abstract void delete_note (Note note) throws ProviderError;
    public abstract uint get_index_of(Note? note);
}
