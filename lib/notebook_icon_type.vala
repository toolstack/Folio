
public enum Paper.NotebookIconType {
    FIRST,
    INITIALS,
    INITIALS_CAMEL_CASE,
    INITIALS_SNAKE_CASE;

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
            default:
                assert_not_reached();
        }
    }
}
