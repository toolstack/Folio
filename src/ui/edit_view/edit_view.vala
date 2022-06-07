
[GtkTemplate (ui = "/io/posidon/Paper/edit_view.ui")]
public class Paper.EditView : Gtk.Box {

	[GtkChild]
	unowned Gtk.Box toolbar;

	[GtkChild]
	unowned Gtk.ComboBox format_heading_type;

	[GtkChild]
	unowned Gtk.ComboBox format_heading_type_mobile;

	[GtkChild]
	unowned GtkMarkdown.View text_view;

	[GtkChild]
	public unowned Gtk.ScrolledWindow scrolled_window;

	public bool is_editable {
	    get { return toolbar.visible; }
	    set {
            toolbar.visible = value;
	        text_view.sensitive = value;
	    }
	}

	public bool compacted { get; set; }

	public Gdk.RGBA theme_color {
	    get { return text_view.theme_color; }
	    set {
            text_view.theme_color = value;
	    }
	}

	public Gtk.TextBuffer buffer {
	    get { return text_view.buffer; }
	    set {
            text_view.buffer = value;
            Gtk.TextIter start;
            text_view.buffer.get_start_iter (out start);
            text_view.buffer.place_cursor (start);
	    }
	}

    construct {
	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");

        {
		    var css = new Gtk.CssProvider ();
		    css.load_from_data (@"textview{font-family:'$(note_font)';}".data);
		    text_view.get_style_context ().add_provider (css, -1);
		}

        text_view.notify["buffer"].connect (() => text_view.buffer.notify["cursor-position"].connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            format_heading_type.active = (int) text_view.get_title_level (cur.get_line ());
            format_heading_type_mobile.active = (int) text_view.get_title_level (cur.get_line ());
        }));
        format_heading_type.changed.connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            text_view.set_title_level (cur.get_line (), format_heading_type.active);
        });
        format_heading_type_mobile.changed.connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            text_view.set_title_level (cur.get_line (), format_heading_type_mobile.active);
        });

        scrolled_window.get_vscrollbar ().margin_top = 48;
    }

    public void on_dark_changed (bool dark) {
        text_view.dark = dark;
    }

	public void format_selection_bold () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "**", 2);
	    b.insert_at_cursor ("**", 2);
	    b.end_user_action ();
	}

	public void format_selection_italic () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "_", 1);
	    b.insert_at_cursor ("_", 1);
	    b.end_user_action ();
	}

	public void format_selection_strikethrough () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "~~", 2);
	    b.insert_at_cursor ("~~", 2);
	    b.end_user_action ();
	}

	public void format_selection_highlight () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "==", 2);
	    b.insert_at_cursor ("==", 2);
	    b.end_user_action ();
	}

	public void insert_link () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    Gtk.TextIter iter_a, iter_b, iter;
	    {
	        var mark = b.get_selection_bound ();
	        b.get_iter_at_mark (out iter_a, mark);
	        b.get_iter_at_offset (out iter_b, b.cursor_position);
	        iter = iter_a.compare (iter_b) == -1 ? iter_a : iter_b;
	        b.insert (ref iter, "[", 1);
	    }
	    {
	        var mark = b.get_selection_bound ();
	        b.get_iter_at_mark (out iter_a, mark);
	        b.get_iter_at_offset (out iter_b, b.cursor_position);
	        iter = iter_a.compare (iter_b) == 1 ? iter_a : iter_b;
	        b.insert (ref iter, "]()", 3);
	    }
	    iter.backward_chars (3);
	    b.place_cursor (iter);
	    b.end_user_action ();
	}

	public void insert_code_span () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "`", 1);
	    b.insert_at_cursor ("`", 1);
	    b.end_user_action ();
	}

	public void insert_horizontal_rule () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "\n- - -\n", 7);
	    b.end_user_action ();
	}
}
