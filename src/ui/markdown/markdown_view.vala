
public class GtkMarkdown.View : GtkSource.View {

    public bool dark { get; set; default = false; }
    public Gdk.RGBA theme_color { get; set; }

    public Gdk.RGBA url_color {
        get {
            var hsl = Color.rgb_to_hsl (Color.RGBA_to_rgb (theme_color));
            hsl.l = 0.42f;
            return Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
        }
    }

    public Gdk.RGBA escape_color {
        get {
            var hsl = Color.rgb_to_hsl (Color.RGBA_to_rgb (theme_color));
            hsl.l = 0.5f;
            hsl.s *= 0.64f;
            return Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
        }
    }

    public bool show_gutter { get; set; default = true; }

    private GtkSource.GutterRendererText renderer;

	private Regex is_link;
	private Regex is_escape;

    construct {
	    is_link = new Regex ("\\[([^\\[]+?)\\](\\([^\\)\\n]+?\\))", RegexCompileFlags.CASELESS, 0);
	    is_escape = new Regex ("\\\\[\\\\`*_{}\\[\\]()#+-.!]", RegexCompileFlags.CASELESS, 0);

        notify["dark"].connect ((s, p) => update_color_scheme ());
        update_color_scheme ();

        {
            var gutter = get_gutter (Gtk.TextWindowType.LEFT);
            renderer = new GtkSource.GutterRendererText ();
            renderer.xalign = 0.5f;
            renderer.yalign = 0.5f;
            renderer.query_data.connect ((lines, line) => {
                var title_level = get_title_level (line);
                if (title_level != 0 && show_gutter) {
                    renderer.text = @"H$title_level";
                } else {
                    renderer.text = null;
                }
            });
            renderer.query_activatable.connect ((iter, area) => true);
            renderer.activate.connect ((iter, area, button, state, n_presses) => {
                if (button != 1) return;
                var line = iter.get_line ();
                var title_level = get_title_level (line);
                if (title_level == 0) return;
                var popover = new HeadingPopover(this, line);
                popover.autohide = true;
                popover.has_arrow = true;
                popover.position = Gtk.PositionType.LEFT;
                popover.set_parent (this);
                popover.pointing_to = area;
                popover.popup ();
            });
            gutter.insert (renderer, 0);
        }
    }

    public new Gtk.TextBuffer? buffer {
        get { return base.buffer; }
        set {
            base.buffer = value;
            update_color_scheme ();
        }
    }

	internal uint get_title_level (uint line) {
        Gtk.TextIter start;
        Gtk.TextIter end;
        buffer.get_iter_at_line (out start, (int) line);
        buffer.get_iter_at_line (out end, (int) line + 1);
        var str = start.get_text (end);
        var i = 0;
        while (i < 6 && i < str.length) {
            if (str[i] != '#') break;
            i++;
        }
        if (str[i] != ' ') return 0;
        return i;
	}

	internal void set_title_level (uint line, uint level) {
        var old_title_level = get_title_level (line);
        if (old_title_level == level) return;
        Gtk.TextIter start;
        buffer.get_iter_at_line (out start, (int) line);
        if (level > old_title_level) {
            var str = string.nfill(level - old_title_level, '#');
            buffer.insert (ref start, str, str.length);
        } else {
            var end = start.copy ();
            end.forward_chars ((int) (old_title_level - level));
            buffer.@delete (ref start, ref end);
        }
	}

    private Gtk.TextTag text_tag_url;
    private Gtk.TextTag text_tag_escaped;
    private Gtk.TextTag hidden;
	private void update_color_scheme () {
        if (buffer is GtkSource.Buffer) {
            var buffer = buffer as GtkSource.Buffer;
            buffer.style_scheme = GtkSource.StyleSchemeManager.get_default ().get_scheme (dark ? "paper-dark" : "paper");
            hidden = buffer.create_tag ("hidden-character");
            hidden.invisible = true;
            text_tag_url = buffer.create_tag ("markdown-link");
            text_tag_url.foreground_rgba = url_color;
            text_tag_url.underline = Pango.Underline.SINGLE;
            text_tag_escaped = buffer.create_tag ("markdown-escaped-char");
            text_tag_escaped.foreground_rgba = escape_color;
            buffer.changed.connect (restyle_text);
            buffer.notify["cursor-position"].connect (restyle_text);
            restyle_text();
        }
	}

	private void restyle_text () {
        renderer.queue_draw ();
        Gtk.TextIter buffer_start, buffer_end, cursor_location;
        buffer.get_bounds (out buffer_start, out buffer_end);
        buffer.remove_tag (hidden, buffer_start, buffer_end);
        buffer.remove_tag (text_tag_url, buffer_start, buffer_end);
        var cursor = buffer.get_insert ();
        buffer.get_iter_at_mark (out cursor_location, cursor);
        string buffer_text = buffer.get_text (buffer_start, buffer_end, true);

        {
            var lines = buffer.get_line_count ();
            for (var line = 0; line < lines; line++) {
                var title_level = get_title_level (line);
                if (title_level != 0) {
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_line (out start, line);
                    end = start.copy ();
                    end.forward_chars ((int) title_level + 1);
                    buffer.apply_tag (hidden, start, end);
                }
            }
        }

        // Check for links
        MatchInfo matches;
        if (is_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
            do {
                int start_text_pos, end_text_pos;
                int start_url_pos, end_url_pos;
                bool have_text = matches.fetch_pos (1, out start_text_pos, out end_text_pos);
                bool have_url = matches.fetch_pos (2, out start_url_pos, out end_url_pos);

                if (have_text && have_url) {
                    start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
                    end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);
                    start_url_pos = buffer_text.char_count ((ssize_t) start_url_pos);
                    end_url_pos = buffer_text.char_count ((ssize_t) end_url_pos);

                    // Convert the character offsets to TextIter's
                    Gtk.TextIter start_text_iter, end_text_iter, start_url_iter, end_url_iter;
                    buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
                    buffer.get_iter_at_offset (out end_text_iter, end_text_pos);
                    buffer.get_iter_at_offset (out start_url_iter, start_url_pos);
                    buffer.get_iter_at_offset (out end_url_iter, end_url_pos);

                    // Skip if our cursor is inside the URL text
                    if (cursor_location.in_range (start_text_iter, end_url_iter)) {
                        continue;
                    }

                    var start_bracket_iter = start_text_iter.copy ();
                    start_bracket_iter.backward_char ();
                    var end_bracket_iter = end_text_iter.copy ();
                    end_bracket_iter.forward_char ();


                    // Apply our styling
                    buffer.apply_tag (text_tag_url, start_text_iter, end_text_iter);
                    buffer.apply_tag (hidden, start_url_iter, end_url_iter);
                    buffer.apply_tag (hidden, start_bracket_iter, start_text_iter);
                    buffer.apply_tag (hidden, end_text_iter, end_bracket_iter);
                }
            } while (matches.next ());
        }

        // Check for escapes
        if (is_escape.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
            do {
                int start_text_pos, end_text_pos;
                bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

                if (have_text) {
                    start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
                    end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

                    // Convert the character offsets to TextIter's
                    Gtk.TextIter start_text_iter, end_text_iter;
                    buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
                    buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

                    // Skip if our cursor is inside the URL text
                    if (cursor_location.in_range (start_text_iter, end_text_iter)) {
                        continue;
                    }

                    var start_escaped_char_iter = start_text_iter.copy ();
                    start_escaped_char_iter.forward_char ();


                    // Apply our styling
                    buffer.apply_tag (text_tag_escaped, start_escaped_char_iter, end_text_iter);
                    buffer.apply_tag (hidden, start_text_iter, start_escaped_char_iter);
                }
            } while (matches.next ());
        }
    }
}
