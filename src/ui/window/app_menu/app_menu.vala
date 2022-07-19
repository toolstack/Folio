
[GtkTemplate (ui = "/io/posidon/Paper/app_menu.ui")]
public class Paper.AppMenu : Gtk.Box {

    [GtkChild] unowned Gtk.PopoverMenu popover;

    construct {
	    popover.add_child (new ThemeSelector (), "theme");
    }
}
