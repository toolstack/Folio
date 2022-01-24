using Gee;

namespace Paper {
    public interface Notebook : Object, ListModel {
        public abstract string name { get; }
        public abstract Gdk.RGBA color { get; }

        public abstract Gee.List<Note>? loaded_notes { get; }

        public abstract void load ();

        public abstract Note new_note (string name) throws ProviderError;
        public abstract void change_note (Note note, string name) throws ProviderError;
        public abstract void delete_note (Note note) throws ProviderError;
    }
}
