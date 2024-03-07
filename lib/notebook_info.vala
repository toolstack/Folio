
public class Folio.NotebookInfo {

	public string name;
	public Gdk.RGBA color;
	public NotebookIconType icon_type;
	public string? icon_name;

	public NotebookInfo (
		string name,
		Gdk.RGBA color = Gdk.RGBA (),
		NotebookIconType icon_type = NotebookIconType.DEFAULT,
		string? icon_name = null
	) {
		this.name = name;
		this.color = color;
		this.icon_type = icon_type;
		this.icon_name = icon_name;
	}
}
