using Gee;

public interface Paper.Trash : Object, ListModel, NoteContainer {
    public abstract void delete_note (Note note) throws ProviderError;
    public abstract void delete_all () throws ProviderError;

    public abstract void restore_note (Note note) throws ProviderError;
}
