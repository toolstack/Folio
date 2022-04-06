
[GtkTemplate (ui = "/io/posidon/Paper/notebooks_bar.ui")]
public class Paper.NotebooksBar : Gtk.Box {

	[GtkChild]
	unowned Gtk.ListView list;

	Gtk.SingleSelection model;

	[GtkChild]
	unowned Gtk.ToggleButton trash_button;

	public void init (Window window, Application app) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (list_item => {
            var widget = new NotebookIcon (app);
            list_item.child = widget;
        });
        factory.bind.connect (list_item => {
            var widget = list_item.child as NotebookIcon;
            var item = list_item.item as Notebook;
            widget.notebook = item;
        });
        this.model = new Gtk.SingleSelection (
            app.notebook_provider
        );
        this.model.can_unselect = true;
		this.model.selection_changed.connect (() => {
		    uint i = model.selected;
		    var notebooks = app.notebook_provider.notebooks;
		    if (i <= notebooks.size) {
		        var notebook = notebooks[(int) i];
		        app.set_active_notebook (notebook);
		        trash_button.active = false;
		    }
		});
		list.factory = factory;
		list.model = model;

		if (app.notebook_provider.notebooks.size != 0) {
		    model.selection_changed (0, 1);
		}

		trash_button.toggled.connect (() => {
	        trash_button.sensitive = !trash_button.active;
		    if (trash_button.active) {
		        model.unselect_item (model.selected);

		        // will call set_notebook (null) as a side effect
		        app.set_active_notebook (null);

		        window.set_trash (app.notebook_provider.trash);
		    }
		});
	}

	public void select_notebook (uint i) {
	    model.selected = i;
	    model.selection_changed (i, 1);
	}
}
