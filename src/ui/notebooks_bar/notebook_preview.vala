
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar/notebook_preview.ui")]
public class Paper.NotebookPreview : Gtk.Box {

	[GtkChild]
	unowned Gtk.Label label;

	public string notebook_name {
	    set {
	        label.label = value.slice (0, int.min(value.length, 2));
	        tooltip_text = value;
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
                fg_rgba.alpha = 1f;
                fg_rgba.red = rgb.r * m;
                fg_rgba.green = rgb.g * m;
                fg_rgba.blue = rgb.b * m;
            }
		    var css = new Gtk.CssProvider ();
		    css.load_from_data (@"@define-color notebook_color $(value);@define-color notebook_fg_color $fg_rgba;".data);
		    parent.get_style_context ().add_provider (css, -1);
		    get_style_context ().add_provider (css, -1);
	    }
	}
}
