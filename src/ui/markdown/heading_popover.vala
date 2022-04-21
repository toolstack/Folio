
[GtkTemplate (ui = "/io/posidon/Paper/markdown/heading_popover.ui")]
public class GtkMarkdown.HeadingPopover : Gtk.Popover {

	[GtkChild]
	unowned Gtk.Button button_heading_1;

	[GtkChild]
	unowned Gtk.Button button_heading_2;

	[GtkChild]
	unowned Gtk.Button button_heading_3;

	[GtkChild]
	unowned Gtk.Button button_heading_4;

	[GtkChild]
	unowned Gtk.Button button_heading_5;

	[GtkChild]
	unowned Gtk.Button button_heading_6;

	[GtkChild]
	unowned Gtk.Button button_plain_text;

	public HeadingPopover (View view, uint line) {
	    button_heading_1.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 1);
	    });
	    button_heading_2.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 2);
	    });
	    button_heading_3.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 3);
	    });
	    button_heading_4.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 4);
	    });
	    button_heading_5.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 5);
	    });
	    button_heading_6.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 6);
	    });
	    button_plain_text.clicked.connect (() => {
	        popdown ();
	        view.set_title_level (line, 0);
	    });
	}
}
