

public class GtkMarkdown.Buffer : GtkSource.Buffer {

    public Buffer () {
        Object ();
        language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
    }
}
