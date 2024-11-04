
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

			var settings = new Settings (Config.APP_ID);
			if (settings.get_boolean ("long-notebook-names") == true) {
				label.set_ellipsize (Pango.EllipsizeMode.NONE);
			} else {
				label.set_ellipsize (Pango.EllipsizeMode.END);
			}
		}
	}

	private Notebook _notebook;
}
