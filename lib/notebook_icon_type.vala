
public enum Folio.NotebookIconType {
	FIRST,
	INITIALS,
	INITIALS_CAMEL_CASE,
	INITIALS_SNAKE_CASE,
	PREDEFINED_ICON;

	public const NotebookIconType DEFAULT = FIRST;

	public string to_string () {
		switch (this) {
			case FIRST:
				return "first";
			case INITIALS:
				return "initials";
			case INITIALS_CAMEL_CASE:
				return "camel_case";
			case INITIALS_SNAKE_CASE:
				return "snake_case";
			case PREDEFINED_ICON:
				return "predefined_icon";
			default:
				assert_not_reached();
		}
	}

	public static NotebookIconType from_string (string text) {
		switch (text) {
			case "first":
				return FIRST;
			case "initials":
				return INITIALS;
			case "camel_case":
				return INITIALS_CAMEL_CASE;
			case "snake_case":
				return INITIALS_SNAKE_CASE;
			case "predefined_icon":
				return PREDEFINED_ICON;
			default:
				assert_not_reached();
		}
	}

	public static NotebookIconType from_int (int integer) {
		switch (integer) {
			case 0:
				return FIRST;
			case 1:
				return INITIALS;
			case 2:
				return INITIALS_CAMEL_CASE;
			case 3:
				return INITIALS_SNAKE_CASE;
			case 4:
				return PREDEFINED_ICON;
			default:
				assert_not_reached();
		}
	}
}
