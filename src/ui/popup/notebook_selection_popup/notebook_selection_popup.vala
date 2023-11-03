
public delegate void Paper.OnNotebookSelected (Notebook notebook);

[GtkTemplate (ui = "/io/posidon/Paper/popup/notebook_selection_popup.ui")]
public class Paper.NotebookSelectionPopup : Adw.Window {

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
		factory.setup.connect (obj => (obj as Gtk.ListItem).child = new NotebookListItem ());
		factory.bind.connect (obj => ((obj as Gtk.ListItem).child as NotebookListItem).notebook = (obj as Gtk.ListItem).item as Notebook);
		notebooks_list.model = model;
		notebooks_list.factory = factory;
        button_confirm.clicked.connect (() => {
	        close ();
	        this.callback (model.selected_item as Notebook);
	    });

        scrolled_window.vadjustment.notify["value"].connect (() => {
            var v = scrolled_window.vadjustment.value;
            if (v == 0) headerbar.get_style_context ().remove_class ("overlaid");
            else headerbar.get_style_context ().add_class ("overlaid");
        });
	}
}
