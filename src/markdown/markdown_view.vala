
public class GtkMarkdown.View : GtkSource.View {

    public bool dark { get; set; default = false; }

    construct {
        notify["dark"].connect ((s, p) => update_color_scheme ());
        update_color_scheme ();
    }

    public new Gtk.TextBuffer? buffer {
        get { return base.buffer; }
        set {
            base.buffer = value;
            update_color_scheme ();
        }
    }

	private void update_color_scheme () {
        if (buffer is GtkSource.Buffer) {
            var buffer = buffer as GtkSource.Buffer;
            buffer.style_scheme = GtkSource.StyleSchemeManager.get_default ().get_scheme (dark ? "paper-dark" : "paper");
        }
	}
}
