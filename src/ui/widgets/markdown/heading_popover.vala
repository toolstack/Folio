
[GtkTemplate (ui = "/com/toolstack/Folio/markdown/heading_popover.ui")]
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

	private View view;
	private uint line;

	public HeadingPopover (View view, uint line) {
		this.view = view;
		this.line = line;

		button_heading_1.clicked.connect (on_button_heading_1_clicked);
		button_heading_2.clicked.connect (on_button_heading_2_clicked);
		button_heading_3.clicked.connect (on_button_heading_3_clicked);
		button_heading_4.clicked.connect (on_button_heading_4_clicked);
		button_heading_5.clicked.connect (on_button_heading_5_clicked);
		button_heading_6.clicked.connect (on_button_heading_6_clicked);
		button_plain_text.clicked.connect (on_button_heading_0_clicked);
	}

	private void set_heading_level (int level) {
		popdown ();
		view.set_title_level (line, level);
	}

	private void on_button_heading_1_clicked () {
		set_heading_level (1);
	}

	private void on_button_heading_2_clicked () {
		set_heading_level (2);
	}

	private void on_button_heading_3_clicked () {
		set_heading_level (3);
	}

	private void on_button_heading_4_clicked () {
		set_heading_level (4);
	}

	private void on_button_heading_5_clicked () {
		set_heading_level (5);
	}

	private void on_button_heading_6_clicked () {
		set_heading_level (6);
	}

	private void on_button_heading_0_clicked () {
		set_heading_level (0);
	}
}
