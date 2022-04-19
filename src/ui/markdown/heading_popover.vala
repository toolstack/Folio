
[GtkTemplate (ui = "/io/posidon/Paper/markdown/heading_popover.ui")]
public class GtkMarkdown.HeadingPopover : Gtk.Popover {

	[GtkChild]
	unowned Gtk.SpinButton heading_level;

	public HeadingPopover (View view, uint line) {
	    heading_level.value = view.get_title_level (line);
	    heading_level.value_changed.connect (() => {
	        view.set_title_level (line, (uint) heading_level.value);
	    });
	}
}
