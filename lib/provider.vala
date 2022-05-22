using Gee;

public errordomain Paper.ProviderError {
    ALREADY_EXISTS,
    COULDNT_CREATE_FILE,
    NOTES_HAVENT_LOADED,
    COULDNT_DELETE,
    COULDNT_MOVE,
}

public interface Paper.Provider : Object, ListModel {
    public abstract Gee.List<Notebook> notebooks { get; }
    public abstract Trash trash { get; }
    public abstract Notebook new_notebook (NotebookInfo info) throws ProviderError;
    public abstract void change_notebook (Notebook notebook, NotebookInfo info) throws ProviderError;
    public abstract void delete_notebook (Notebook notebook) throws ProviderError;

    public Gee.List<Note> get_all_notes () {
        var notes = new ArrayList<Note> ();
        foreach (var notebook in notebooks) {
            notebook.load ();
            foreach (var note in notebook.loaded_notes) {
                notes.add(note);
            }
            notebook.unload ();
        }
        return notes;
    }
}
