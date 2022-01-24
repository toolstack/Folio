using Gee;

namespace Paper {
    public errordomain ProviderError {
        ALREADY_EXISTS,
        COULDNT_CREATE_FILE,
        NOTES_HAVENT_LOADED,
        COULDNT_DELETE,
    }

    public interface Provider : Object, ListModel {
        public abstract Gee.List<Notebook> notebooks { get; }
        public abstract Notebook new_notebook (string name, Gdk.RGBA color) throws ProviderError;
        public abstract void change_notebook (Notebook notebook, string name, Gdk.RGBA color) throws ProviderError;
        public abstract void delete_notebook (Notebook notebook) throws ProviderError;
    }
}
