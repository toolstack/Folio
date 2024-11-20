
public delegate void Folio.OnNotebookSelected (Notebook notebook);

[GtkTemplate (ui = "/com/toolstack/Folio/popup/notebook_selection_popup.ui")]
public class Folio.NotebookSelectionPopup : Adw.Dialog {

	[GtkChild]
	unowned Gtk.ListView notebooks_list;

	[GtkChild]
	unowned Gtk.Button button_cancel;

	[GtkChild]
	unowned Gtk.Button button_confirm;

	[GtkChild]
	unowned Adw.HeaderBar headerbar;

	[GtkChild]
	unowned Gtk.ScrolledWindow scrolled_window;

	private OnNotebookSelected callback;
	private Gtk.SingleSelection model;

	private void on_button_cancel_clicked () {
		this.close ();
	}

	private void on_factory_setup_change (Object obj) {
		var li = obj as Gtk.ListItem;
		if (li != null) {
			li.child = new NotebookListItem ();
		}
	}

	private void on_factory_bind_change (Object obj) {
		var li = obj as Gtk.ListItem;
		if (li != null) {
			var nli = li.child as NotebookListItem;
			if (nli != null) {
				nli.notebook = li.item as Notebook;
			}
		}
	}

	private void on_button_confirm_clicked () {
		close ();
		this.callback (model.selected_item as Notebook);
	}

	private void on_scrolled_window_vadjustment_changed () {
		var v = scrolled_window.vadjustment.value;
		if (v == 0) headerbar.remove_css_class ("overlaid");
		else headerbar.add_css_class ("overlaid");
	}

	public NotebookSelectionPopup (Provider provider, string title, string action_name, owned OnNotebookSelected callback) {
		Object ();
		this.title = title;
		this.button_confirm.label = action_name;
		this.callback = (owned) callback;
		button_cancel.clicked.connect (on_button_cancel_clicked);
		model = new Gtk.SingleSelection (provider);
		var factory = new Gtk.SignalListItemFactory ();
		factory.setup.connect (on_factory_setup_change);
		factory.bind.connect (on_factory_bind_change);
		notebooks_list.model = model;
		notebooks_list.factory = factory;
		button_confirm.clicked.connect (on_button_confirm_clicked);

		scrolled_window.vadjustment.notify["value"].connect (on_scrolled_window_vadjustment_changed);
	}
}
