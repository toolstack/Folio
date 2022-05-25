
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/notebook_preview.ui")]
public class Paper.NotebookPreview : Gtk.Box {

	[GtkChild]
	unowned Gtk.Label label;

	[GtkChild]
	unowned Gtk.Image icon;

	public NotebookInfo? notebook_info {
	    get { return _notebook_info; }
	    set {
	        _notebook_info = value;
	        update_color ();
	        update_text ();
	    }
	}

	public string notebook_name {
	    set {
	        if (_notebook_info == null)
	            _notebook_info = new NotebookInfo (value);
	        else
	            _notebook_info.name = value;
	        update_text ();
	    }
	}

	public Gdk.RGBA color {
	    set {
	        _notebook_info.color = value;
	        update_color ();
	    }
	}

	public NotebookIconType icon_type {
	    set {
	        _notebook_info.icon_type = value;
	        update_text ();
	    }
	}

	public string icon_name {
	    set {
	        _notebook_info.icon_name = value;
	        update_text ();
	    }
	}


	private NotebookInfo? _notebook_info;

	private void update_color () {
	    var info = _notebook_info;
	    if (info == null)
	        return;
        var fg_rgba = Gdk.RGBA ();
        {
            var rgb = Color.RGBA_to_rgb (info.color);
            var hsl = Color.rgb_to_hsl (rgb);
            var l = Color.get_luminance(rgb.r, rgb.g, rgb.b);
            var is_notebook_light = l > 0.7f;
            hsl.l = is_notebook_light ? 0.1f : 0.645f;
            hsl.s = 1.0f;
            var m = is_notebook_light ? 1.0f : 3.0f;
            Color.hsl_to_rgb (hsl, out rgb);
            Color.rgb_to_RGBA (rgb.multiply (m), out fg_rgba);
        }
	    var css = new Gtk.CssProvider ();
	    css.load_from_data (@"@define-color notebook_color $(info.color);@define-color notebook_fg_color $fg_rgba;".data);
	    parent.get_style_context ().add_provider (css, -1);
	    get_style_context ().add_provider (css, -1);
	}

	private void update_text () {
	    var info = _notebook_info;
	    if (info == null)
	        return;
        tooltip_text = info.name;
	    if (info.icon_type == NotebookIconType.PREDEFINED_ICON) {
            label.visible = false;
            icon.visible = true;
            icon.icon_name = info.icon_name ?? "icon-skull-symbolic";
            return;
        }
        icon.visible = false;
        label.visible = true;
	    switch (info.icon_type) {
	        case NotebookIconType.INITIALS:
	            label.label = initials_split (info.name, " ");
                break;
	        case NotebookIconType.INITIALS_SNAKE_CASE:
	            label.label = initials_split (info.name, "_");
                break;
	        case NotebookIconType.INITIALS_CAMEL_CASE:
                var regex = new Regex ("[A-Z]");
                MatchInfo matches;
                var matchable = info.name.substring (int.min(info.name.length, 1));
                if (regex.match_full (matchable, matchable.length, 0, 0, out matches)) {
                    var _1 = matches.fetch (0);
                    var result = info.name.slice (0, int.min(info.name.length, 1));
                    if (_1 != null) {
                        result += _1;
                    }
                    label.label = result;
                }
                else label.label = first_chars (info.name);
                break;
	        case NotebookIconType.FIRST:
                label.label = first_chars (info.name);
                break;
            default:
                assert_not_reached();
	    }
	}

	private string initials_split (string original, string delimiter) {
        var words = original.split (delimiter);
        char[] initials = {};
        foreach (string word in words) {
            if (word.length == 0) continue;
            initials += word[0];
        }
		switch (initials.length) {
			case 0:
				return first_chars (original);
			case 1:
				return initials[0].to_string();
			default:
				var str = (string) initials;
				return str.slice (0, int.min(str.length, 2));
		}
	}

	private string first_chars (string original) {
        return original.slice (0, int.min(original.length, 2));
	}
}

