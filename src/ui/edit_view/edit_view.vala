
[GtkTemplate (ui = "/io/posidon/Paper/edit_view.ui")]
public class Paper.EditView : Gtk.Box {

    public bool toolbar_enabled { get; set; }

	public bool is_editable { get; set; }

    public int scale { get; set; default = 100; }

    public bool text_mode { set { markdown_view.text_mode = value; } }

    public const int MIN_SCALE = 10;
    public const int MAX_SCALE = 600;

	public Gdk.RGBA theme_color {
	    get { return markdown_view.theme_color; }
	    set {
            markdown_view.theme_color = value;
	    }
	}

	public Gtk.TextBuffer buffer {
	    get { return markdown_view.buffer; }
	    set {
            markdown_view.buffer = value;
            Gtk.TextIter start;
            markdown_view.buffer.get_start_iter (out start);
            markdown_view.buffer.place_cursor (start);
	    }
	}

	[GtkChild] public unowned Toolbar toolbar;
	[GtkChild] unowned GtkMarkdown.View markdown_view;
	[GtkChild] public unowned Gtk.ScrolledWindow scrolled_window;

    private Gtk.CssProvider note_font_provider = new Gtk.CssProvider ();
    private Gtk.CssProvider font_scale_provider = new Gtk.CssProvider ();

    construct {
	    var settings = new Settings (Config.APP_ID);

        set_note_font (settings.get_string ("note-font"));
 		set_max_width (settings.get_int ("note-max-width"));

        markdown_view.notify["text-mode"].connect (update_toolbar_visibility);

        markdown_view.notify["buffer"].connect (() => markdown_view.buffer.notify["cursor-position"].connect (() => {
            var ins = markdown_view.buffer.get_insert ();
            Gtk.TextIter cur;
            markdown_view.buffer.get_iter_at_mark (out cur, ins);
            toolbar.heading_i = (int) markdown_view.get_title_level (cur.get_line ());
        }));
        toolbar.heading_i_changed.connect ((i) => {
            var ins = markdown_view.buffer.get_insert ();
            Gtk.TextIter cur;
            markdown_view.buffer.get_iter_at_mark (out cur, ins);
            markdown_view.set_title_level (cur.get_line (), i);
        });

        scrolled_window.get_vscrollbar ().margin_top = 48;

	    settings.bind ("toolbar-enabled", this, "toolbar-enabled", SettingsBindFlags.DEFAULT);
	    settings.bind ("note-font-monospace", markdown_view, "font-monospace", SettingsBindFlags.DEFAULT);
	    settings.changed["note-font"].connect(() => set_note_font (settings.get_string ("note-font")));
	    settings.changed["note-max-width"].connect(() => set_max_width (settings.get_int ("note-max-width")));

	    var window_state = new Settings (@"$(Config.APP_ID).WindowState");
	    window_state.bind ("text-scale", this, "scale", SettingsBindFlags.DEFAULT);

        notify["toolbar-enabled"].connect (update_toolbar_visibility);
        notify["is-editable"].connect (() => {
            update_toolbar_visibility ();
	        markdown_view.sensitive = is_editable;
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
	    markdown_view.add_controller (scroll_controller);
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
        markdown_view.dark = dark;
    }

    private void format_selection (string affix) {
	    var b = markdown_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter, cursor;
	    b.get_iter_at_mark (out iter, mark);

	    b.insert (ref iter, affix, affix.length);
	    b.insert_at_cursor (affix, affix.length);

	    b.get_iter_at_mark (out iter, mark);
        b.get_iter_at_mark (out cursor, b.get_insert());

        if(iter.equal(cursor)) {
            cursor.backward_cursor_positions (affix.length);
            b.place_cursor (cursor);
        }

	    b.end_user_action ();
    }

	public void format_selection_bold () {
        format_selection("**");
	}

	public void format_selection_italic () {
        format_selection("_");
	}

	public void format_selection_strikethrough () {
        format_selection("~~");
	}

	public void format_selection_highlight () {
        format_selection("==");
	}

	public void insert_link () {
	    var b = markdown_view.buffer;
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
        format_selection("`");
	}

	public void insert_horizontal_rule () {
	    var b = markdown_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "\n- - -\n", 7);
	    b.end_user_action ();
	}

    public void set_font_scale () {
	    font_scale_provider.load_from_data (@"textview{font-size:$(scale / 100f)em;}".data);
	    markdown_view.get_style_context ().add_provider (font_scale_provider, -1);
    }

    private void set_note_font (string font) {
	    note_font_provider.load_from_data (@"textview{font-family:'$font';}".data);
	    markdown_view.get_style_context ().add_provider (note_font_provider, -1);
    }

    private void set_max_width (int w) {
	    markdown_view.width_request = w;
    	markdown_view.halign = w == -1 ? Gtk.Align.FILL : Gtk.Align.CENTER;
    }

	private void update_toolbar_visibility () {
	    toolbar.visible = is_editable && toolbar_enabled && !markdown_view.text_mode;
	}
}

