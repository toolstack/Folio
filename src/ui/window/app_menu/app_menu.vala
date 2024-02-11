
[GtkTemplate (ui = "/com/toolstack/Folio/app_menu.ui")]
public class Folio.AppMenu : Adw.Bin {

    [GtkChild] unowned Gtk.PopoverMenu popover;

    construct {
	    popover.add_child (new ThemeSelector (), "theme");
    }
}
