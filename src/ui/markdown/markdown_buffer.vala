

public class GtkMarkdown.Buffer : GtkSource.Buffer {

    public Buffer (string? text = null) {
        Object ();
        language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
        this.text = text;
    }

    public string get_all_text () {
        Gtk.TextIter start, end;
        get_start_iter (out start);
        get_end_iter (out end);
        return get_text(start, end, true);
    }
}
