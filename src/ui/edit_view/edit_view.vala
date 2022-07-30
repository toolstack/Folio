
[GtkTemplate (ui = "/io/posidon/Paper/edit_view.ui")]
public class Paper.EditView : Gtk.Box {

    public bool toolbar_enabled { get; set; }

	public bool is_editable { get; set; }

    public int scale { get; set; default = 100; }

    public const int MIN_SCALE = 10;
    public const int MAX_SCALE = 600;

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

	[GtkChild] public unowned Toolbar toolbar;
	[GtkChild] unowned GtkMarkdown.View text_view;
	[GtkChild] public unowned Gtk.ScrolledWindow scrolled_window;

    private Gtk.CssProvider note_font_provider = new Gtk.CssProvider ();
    private Gtk.CssProvider font_scale_provider = new Gtk.CssProvider ();

    construct {
	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");

        set_note_font (note_font);

        text_view.notify["buffer"].connect (() => text_view.buffer.notify["cursor-position"].connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            toolbar.heading_i = (int) text_view.get_title_level (cur.get_line ());
        }));
        toolbar.heading_i_changed.connect ((i) => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            text_view.set_title_level (cur.get_line (), i);
        });

        scrolled_window.get_vscrollbar ().margin_top = 48;

	    settings.bind ("toolbar-enabled", this, "toolbar-enabled", SettingsBindFlags.DEFAULT);
	    settings.bind ("note-font-monospace", text_view, "font-monospace", SettingsBindFlags.DEFAULT);
	    settings.changed["note-font"].connect(() => set_note_font (settings.get_string ("note-font")));

        notify["toolbar-enabled"].connect (update_toolbar_visibility);
        notify["is-editable"].connect (() => {
            update_toolbar_visibility ();
	        text_view.sensitive = is_editable;
        });
        update_toolbar_visibility ();

	    notify["scale"].connect(set_font_scale);

	    var key_controller = new Gtk.EventControllerKey ();
	    var is_ctrl = false;
	    key_controller.key_pressed.connect ((keyval, keycode, state) => {
	        if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R)
	            is_ctrl = true;
	        return false;
	    });
	    key_controller.key_released.connect ((keyval, keycode, state) => {
	        if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R)
	            is_ctrl = false;
	    });
	    var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.DISCRETE | Gtk.EventControllerScrollFlags.VERTICAL);
	    scroll_controller.scroll.connect ((dx, dy) => {
	        if (is_ctrl) {
	            if (dy < 0)
	                zoom_in ();
	            else zoom_out ();
	            return true;
	        }
	        return false;
	    });
	    add_controller (key_controller);
	    text_view.add_controller (scroll_controller);
    }

    public void zoom_in () {
        var new_scale = scale + 10;
        if (new_scale <= MAX_SCALE)
            scale = new_scale;
    }

    public void zoom_out () {
        var new_scale = scale - 10;
        if (new_scale >= MIN_SCALE)
            scale = new_scale;
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

    public void set_font_scale () {
	    font_scale_provider.load_from_data (@"textview{font-size:$(scale / 100f)em;}".data);
	    text_view.get_style_context ().add_provider (font_scale_provider, -1);
    }

    private void set_note_font (string font) {
	    note_font_provider.load_from_data (@"textview{font-family:'$font';}".data);
	    text_view.get_style_context ().add_provider (note_font_provider, -1);
    }

	private void update_toolbar_visibility () {
	    toolbar.visible = is_editable && toolbar_enabled;
	}
}

