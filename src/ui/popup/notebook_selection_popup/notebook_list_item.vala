
[GtkTemplate (ui = "/io/posidon/Paper/popup/notebook_list_item.ui")]
public class Paper.NotebookListItem : Gtk.Box {

	[GtkChild]
	unowned NotebookPreview icon;

	[GtkChild]
	unowned Gtk.Label label;

	public Notebook notebook {
	    set {
	        this._notebook = value;
	        label.label = value.name;
	        icon.notebook_name = value.name;
	        icon.color = value.color;
	    }
	}

	private Notebook _notebook;
}
