
public class Folio.Strings {
	public static string APP_NAME { get { return _("Folio"); } }
	public static string TRASH { get { return _("Trash"); } }
	public static string X_NOTES { get { return _("%d Notes"); } }
	public static string EMPTY_TRASH_CONFIRMATION { get { return _("Are you sure you want to delete everything in the trash?"); } }
	public abstract const string EMPTY_TRASH = _("Empty Trash");
	public abstract const string NEW_NOTE = _("New Note");
	public abstract const string CREATE_NOTEBOOK_BEFORE_CREATING_NOTE = _("Create/choose a notebook before creating a note");
	public abstract const string SELECT_NOTE_TO_EDIT = _("Please, select a note to edit");
	public abstract const string SELECT_NOTE_TO_DELETE = _("Please, select a note to delete");
	public abstract const string EXPORT_NOTE = _("Export Note");
	public abstract const string EXPORT = _("Export");
	public abstract const string NEW_NOTEBOOK = _("New Notebook");
	public abstract const string RENAME_NOTE = _("Rename Note");
	public abstract const string MOVE_TO_NOTEBOOK = _("Move to Notebook");
	public abstract const string MOVE = _("Move");
	public abstract const string NOTE_X_ALREADY_EXISTS_IN_X = _("Note “%s” already exists in notebook “%s”");
	public abstract const string DELETE_NOTE_CONFIRMATION = _("Are you sure you want to delete the note “%s”?");
	public abstract const string DELETE_NOTE = _("Delete Note");
	public abstract const string DELETE_NOTEBOOK_CONFIRMATION = _("Are you sure you want to delete the notebook “%s”?");
	public abstract const string DELETE_NOTEBOOK = _("Delete Notebook");
	public abstract const string EDIT_NOTEBOOK = _("Edit Notebook");
	public abstract const string NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR = _("Note names cannot contain a “/”");
	public abstract const string NOTE_NAME_SHOULDNT_BE_BLANK = _("Note names cannot be blank");
	public abstract const string NOTE_X_ALREADY_EXISTS = _("Note “%s” already exists");
	public abstract const string COULDNT_CREATE_NOTE = _("Could not create note");
	public abstract const string COULDNT_CHANGE_NOTE = _("Could not change note");
	public abstract const string COULDNT_DELETE_NOTE = _("Could not delete note");
	public abstract const string COULDNT_RESTORE_NOTE = _("Could not restore note");
	public abstract const string SAVED_X_TO_X = _("Saved “%s” to “%s”");
	public abstract const string UNKNOWN_ERROR = _("Unknown error");
	public abstract const string NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR = _("Notebook names cannot contain a “/”");
	public abstract const string NOTEBOOK_NAME_SHOULDNT_BE_BLANK = _("Notebook names cannot be blank");
	public abstract const string NOTEBOOK_X_ALREADY_EXISTS = _("Notebook “%s” already exists");
	public abstract const string COULDNT_CREATE_NOTEBOOK = _("Could not create notebook");
	public abstract const string COULDNT_CHANGE_NOTEBOOK = _("Could not change notebook");
	public abstract const string COULDNT_DELETE_NOTEBOOK = _("Could not delete notebook");
	public abstract const string MARKDOWN_CHEATSHEET = _("Markdown Cheatsheet");
	public abstract const string SEARCH = _("Search");
	public abstract const string RENAME = _("Rename");
	public abstract const string COULDNT_FIND_APP_TO_HANDLE_URIS = _("Could not find an app to handle file URIs");
	public abstract const string APPLY = _("Apply");
	public abstract const string CANCEL = _("Cancel");
	public abstract const string PICK_NOTES_DIR = _("Pick where the notebooks will be stored");
	public abstract const string PICK_TRASH_DIR = _("Pick where the trash can will be stored");
	public abstract const string ALL_NOTES = _("All Notes");
	public abstract const string NOTEBOOK = _("Notebook");
	public abstract const string LAST_MODIFIED = _("Last Modified");
	public abstract const string EXTENSION = _("Extension");
	public abstract const string UNRECOGNIZED_URI = _("Unable to recognize URI");
	public abstract const string PICK_NOTE_FONT = _("Pick primary font for notes");
	public abstract const string PICK_CODE_FONT = _("Pick monospace font for code");
	public abstract const string FILE_CHANGED_ON_DISK = _("File Changed On Disk");
	public abstract const string FILE_CHANGED_DIALOG_TRIPLE = _("The file has changed on disk since it was last saved/loaded by Folio.\n\nYou may do one of the following:\n\n • Reload the file (discarding any changes you have made in Folio)\n • Overwrite the file (discarding any changes made outside of Folio)\n • Cancel the operation and manually resolve the issue\n\nNote: Canceling the save if you have already moved to a new note/notebook will discard your changes.");
	public abstract const string FILE_CHANGED_RELOAD = _("Reload");
	public abstract const string FILE_CHANGED_OVERWRITE = _("Overwrite");
	public abstract const string FILE_CHANGED_CANCEL = _("Cancel");
	public abstract const string FILE_CHANGED_DIALOG_DOUBLE = _("The file has changed on disk by another application.\n\nYou may do one of the following:\n\n • Reload the file (discarding any changes you have made in Folio)\n • Overwrite the file (discarding any changes made outside of Folio)");
	public abstract const string NEW_NOTE_NAME = _("Note");
	public abstract const string NEW_NOTE_NAME_X = _("Note %i");
	public abstract const string NOTE_SORT_ORDER_TIME_ASC = _("Modified Time - Ascending");
	public abstract const string NOTE_SORT_ORDER_TIME_DSC = _("Modified Time - Descending");
	public abstract const string NOTE_SORT_ORDER_ALPHA_ASC = _("Alphabetical - Ascending");
	public abstract const string NOTE_SORT_ORDER_ALPHA_DSC = _("Alphabetical - Descending");
	public abstract const string NOTE_SORT_ORDER_NATURAL_ASC = _("Natural - Ascending");
	public abstract const string NOTE_SORT_ORDER_NATURAL_DSC = _("Natural - Descending");
	public abstract const string UNABLE_TO_LAUNCH_EXTERNAL_APPLICATION = _("Unable to launch external application for file %s.");
	public abstract const string URL_DETECTION_AGGRESSIVE = _("Aggressive");
	public abstract const string URL_DETECTION_STRICT = _("Strict");
	public abstract const string URL_DETECTION_DISABLED = _("Disabled");
	public abstract const string NOTE_TRASHED = _("“%s” moved to trash");
	public abstract const string NOTE_RESTORED = _("“%s” restored");
}
