
[GtkTemplate (ui = "/io/posidon/Paper/save_indicator.ui")]
public class Paper.SaveIndicator : Gtk.Box {

	[GtkChild] unowned Gtk.Spinner saving_spinner;
	[GtkChild] unowned Gtk.Image save_status_icon;

	public SaveStatus status {
	    set {
	        switch (value) {
	            case SaveStatus.SAVED: {
                    saving_spinner.visible = false;
                    saving_spinner.spinning = false;
                    save_status_icon.icon_name = "saved-symbolic";
	            } break;
	            case SaveStatus.UNSAVED: {
                    saving_spinner.visible = false;
                    saving_spinner.spinning = false;
                    save_status_icon.icon_name = "unsaved-symbolic";
	            } break;
	            case SaveStatus.SAVING: {
                    saving_spinner.visible = true;
                    saving_spinner.spinning = true;
	            } break;
	        }
	    }
	}
}
