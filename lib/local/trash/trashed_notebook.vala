using Gee;

public class Paper.LocalTrashedNotebook : Object, ListModel, NoteContainer, Notebook {

    public string name { get { return info.name; } }

    public string path {
        owned get { return @"$(trash.path)/$name"; }
    }

    public NotebookInfo info {
        get { return _info; }
    }

    public Gee.List<Note>? loaded_notes {
        get { return null; }
    }

    NotebookInfo _info;
    LocalTrash trash;

    public LocalTrashedNotebook (LocalTrash trash, NotebookInfo info) {
        this.trash = trash;
        this._info = info;
    }

    public void load () {}
    public void unload () {}

    public Note new_note (string name) throws ProviderError {
        error ("Can't create notes in trash");
    }

    public void change_note (Note note, string name) throws ProviderError {
        error ("Can't edit notes in trash");
    }

    public void delete_note (Note note) throws ProviderError {
        trash.delete_note (note);
    }

    public Type get_item_type () {
        return typeof (Note);
    }

    public uint get_n_items () {
        return 0;
    }

    public Object? get_item (uint i) {
        return null;
    }
}
