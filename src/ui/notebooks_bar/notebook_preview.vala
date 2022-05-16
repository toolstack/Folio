
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/notebook_preview.ui")]
public class Paper.NotebookPreview : Gtk.Box {

	[GtkChild]
	unowned Gtk.Label label;

	public string notebook_name {
	    set {
	        _notebook_name = value;
	        tooltip_text = value;
	        update_text ();
	    }
	}

	public NotebookIconType icon_type {
	    set {
	        _icon_type = value;
	        update_text ();
	    }
	}

	public Gdk.RGBA color {
	    set {
            var fg_rgba = Gdk.RGBA ();
            {
                var rgb = Color.RGBA_to_rgb (value);
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
		    css.load_from_data (@"@define-color notebook_color $(value);@define-color notebook_fg_color $fg_rgba;".data);
		    parent.get_style_context ().add_provider (css, -1);
		    get_style_context ().add_provider (css, -1);
	    }
	}


	private NotebookIconType? _icon_type;
	private string? _notebook_name;

	private void update_text () {
	    if (_notebook_name == null)
	        return;
	    if (_icon_type == null)
	        return;
	    switch (_icon_type) {
	        case NotebookIconType.INITIALS:
	            var words = _notebook_name.split (" ");
	            char[] initials = {};
	            foreach (string word in words) {
	                if (word.length == 0) continue;
	                initials += word[0];
	            }
                label.label = ((string) initials).slice (0, int.min(initials.length, 2));
                break;
	        case NotebookIconType.INITIALS_SNAKE_CASE:
	            var words = _notebook_name.split ("_");
	            char[] initials = {};
	            foreach (string word in words) {
	                if (word.length == 0) continue;
	                initials += word[0];
	            }
                label.label = ((string) initials).slice (0, int.min(initials.length, 2));
                break;
	        case NotebookIconType.INITIALS_CAMEL_CASE:
                var regex = new Regex ("[A-Z]");
                MatchInfo matches;
                var matchable = _notebook_name.substring (int.min(_notebook_name.length, 1));
                if (regex.match_full (matchable, matchable.length, 0, 0, out matches)) {
                    var _1 = matches.fetch (0);
                    var result = _notebook_name.slice (0, int.min(_notebook_name.length, 1));
                    if (_1 != null) {
                        result += _1;
                    }
                    label.label = result;
                }
                else label.label = _notebook_name.slice (0, int.min(_notebook_name.length, 2));
                break;
	        case NotebookIconType.FIRST:
                label.label = _notebook_name.slice (0, int.min(_notebook_name.length, 2));
                break;
	    }
	}
}
