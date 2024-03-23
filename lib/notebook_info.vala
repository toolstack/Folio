
public class Folio.NotebookInfo {

	public string name;
	public Gdk.RGBA color;
	public NotebookIconType icon_type;
	public string? icon_name;
	public DateTime time_modified;

	public NotebookInfo (
		string name,
		Gdk.RGBA color = Gdk.RGBA (),
		NotebookIconType icon_type = NotebookIconType.DEFAULT,
		string? icon_name = null,
		DateTime? time_modified = null
	) {
		this.name = name;
		this.color = color;
		this.icon_type = icon_type;
		this.icon_name = icon_name;
		this.time_modified = time_modified == null ? new DateTime.now () : time_modified;
	}
}
