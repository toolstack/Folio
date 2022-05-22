using Gee;

public interface Paper.NoteContainer : Object, ListModel {

    public abstract string name { get; }

    public abstract Gee.List<Note>? loaded_notes { get; }

    public abstract void load ();
    public abstract void unload ();
}

public class Paper.SimpleNoteContainer : Object, ListModel, NoteContainer {

    public string name { get { return _name; } }

    public Gee.List<Note>? loaded_notes { get { return _loaded_notes; } }

    public delegate Gee.List<Note> Loader ();

    private string _name;
    private Loader _load;
    private Gee.List<Note>? _loaded_notes;

    public SimpleNoteContainer (string name, Loader loader) {
        _name = name;
        _load = loader;
    }

    public void load () {
        if (_loaded_notes != null) return;
        _loaded_notes = _load ();
    }

    public void unload () {
        _loaded_notes = null;
    }

    public Type get_item_type () {
        return typeof (Note);
    }

    public uint get_n_items () {
        if (_loaded_notes == null)
            error (@"Container \"$name\": Notes haven't loaded yet");
        return _loaded_notes.size;
    }

    public Object? get_item (uint i) {
        if (_loaded_notes == null)
            error (@"Container \"$name\": Notes haven't loaded yet");
        return (i >= _loaded_notes.size) ? null : _loaded_notes.@get((int) i);
    }
}
