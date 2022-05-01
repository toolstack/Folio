using Gee;

public interface Paper.Trash : Object, ListModel {
    public abstract Gee.List<Note>? loaded_notes { get; }

    public abstract void load ();
    public abstract void unload ();

    public abstract void delete_note (Note note) throws ProviderError;
    public abstract void delete_all () throws ProviderError;

    public abstract void restore_note (Note note) throws ProviderError;
}
