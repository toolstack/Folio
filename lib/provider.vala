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
    public abstract Notebook new_notebook (string name, Gdk.RGBA color) throws ProviderError;
    public abstract void change_notebook (Notebook notebook, string name, Gdk.RGBA color) throws ProviderError;
    public abstract void delete_notebook (Notebook notebook) throws ProviderError;
}
