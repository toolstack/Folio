namespace Paper {
    public interface Note : Object {

        public abstract string name { get; }
        public abstract Notebook notebook { get; }

        public abstract GtkSource.Buffer text { get; }

        /*
         * Loads the content of [property@Notebook.Note.text]
         */
        public abstract void load ();
        public abstract void unload ();

        public abstract void save ();
    }
}
