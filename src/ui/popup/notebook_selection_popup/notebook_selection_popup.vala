
public delegate void Folio.OnNotebookSelected (Notebook notebook);

[GtkTemplate (ui = "/com/toolstack/Folio/popup/notebook_selection_popup.ui")]
public class Folio.NotebookSelectionPopup : Adw.Window {

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

	public NotebookSelectionPopup (Provider provider, string title, string action_name, owned OnNotebookSelected callback) {
		Object ();
		this.title = title;
		this.button_confirm.label = action_name;
		this.callback = (owned) callback;
		button_cancel.clicked.connect (close);
		var model = new Gtk.SingleSelection (provider);
		var factory = new Gtk.SignalListItemFactory ();
		factory.setup.connect (obj => {
			var li = obj as Gtk.ListItem;
			if (li != null) {
				li.child = new NotebookListItem ();
			}
		});
		factory.bind.connect (obj => {
			var li = obj as Gtk.ListItem;
			if (li != null) {
				var nli = li.child as NotebookListItem;
				if (nli != null) {
					nli.notebook = li.item as Notebook;
				}
			}
		});
		notebooks_list.model = model;
		notebooks_list.factory = factory;
		button_confirm.clicked.connect (() => {
			close ();
			this.callback (model.selected_item as Notebook);
		});

		scrolled_window.vadjustment.notify["value"].connect (() => {
			var v = scrolled_window.vadjustment.value;
			if (v == 0) headerbar.remove_css_class ("overlaid");
			else headerbar.add_css_class ("overlaid");
		});
	}
}
