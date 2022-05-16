using Gee;

public class Paper.LocalTrashedNotebook : Object, ListModel, Notebook {

    public string name {
        get { return _name; }
    }

    public string path {
        owned get { return @"$(trash.path)/$name"; }
    }

    public Gdk.RGBA color {
        get { return _color; }
    }

    public NotebookIconType icon_type {
        get { return NotebookIconType.DEFAULT; }
    }

    public Gee.List<Note>? loaded_notes {
        get { return null; }
    }

    string _name;
    Gdk.RGBA _color;
    LocalTrash trash;

    public LocalTrashedNotebook (LocalTrash trash, string name, Gdk.RGBA color) {
        this.trash = trash;
        this._name = name;
        this._color = color;
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
