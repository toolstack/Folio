
namespace Paper {
    public delegate void Runnable ();
	[GtkTemplate (ui = "/io/posidon/Paper/popup/confirmation_popup.ui")]
	public class ConfirmationPopup : Adw.Window {

		[GtkChild]
		unowned Gtk.Label question;

		[GtkChild]
		unowned Gtk.Button button_cancel;

		[GtkChild]
		unowned Gtk.Button button_confirm;

		private Runnable action;

		public ConfirmationPopup (string question, string action_name, owned Runnable action) {
			Object ();
			this.question.label = question;
			this.button_confirm.label = action_name;
			this.action = (owned) action;
			button_cancel.clicked.connect (close);
            button_confirm.clicked.connect (() => {
		        close ();
		        this.action ();
		    });
		}
	}
}
