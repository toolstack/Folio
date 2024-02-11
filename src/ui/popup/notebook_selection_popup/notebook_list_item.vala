
[GtkTemplate (ui = "/com/toolstack/Folio/popup/notebook_list_item.ui")]
public class Folio.NotebookListItem : Gtk.Box {

	[GtkChild]
	unowned NotebookPreview icon;

	[GtkChild]
	unowned Gtk.Label label;

	public Notebook notebook {
	    get { return _notebook; }
	    set {
	        this._notebook = value;
	        label.label = value.name;
	        icon.notebook_info = value.info;
	    }
	}

	private Notebook _notebook;
}
