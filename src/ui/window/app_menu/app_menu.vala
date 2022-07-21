
[GtkTemplate (ui = "/io/posidon/Paper/app_menu.ui")]
public class Paper.AppMenu : Adw.Bin {

    [GtkChild] unowned Gtk.PopoverMenu popover;

    construct {
	    popover.add_child (new ThemeSelector (), "theme");
    }
}
