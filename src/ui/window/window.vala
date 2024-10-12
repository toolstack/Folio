/* window.vala
 *
 * Copyright 2022 Zagura
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[GtkTemplate (ui = "/com/toolstack/Folio/window.ui")]
public class Folio.Window : Adw.ApplicationWindow {

	public bool cheatsheet_enabled { get; set; }
	public bool show_line_numbers { get; set; }
	public bool show_all_notes { get; set; }
	public int note_sort_order { get; set; }
	public int notebook_sort_order { get; set; }

	public WindowModel window_model = new WindowModel ();

	[GtkChild] unowned Adw.Leaflet leaflet;
	[GtkChild] unowned Adw.LeafletPage sidebar;
	[GtkChild] unowned Adw.LeafletPage edit_view_page;
	[GtkChild] unowned NotebooksBar notebooks_bar;

	[GtkChild] unowned Gtk.Revealer sidebar_revealer;
	[GtkChild] unowned Adw.WindowTitle notebook_title;
	[GtkChild] unowned Gtk.ListView notebook_notes_list;
	[GtkChild] unowned Gtk.ScrolledWindow notebook_notes_list_scroller;
	[GtkChild] unowned Gtk.SearchBar notes_search_bar;
	[GtkChild] unowned Gtk.SearchEntry notes_search_entry;
	[GtkChild] unowned Adw.HeaderBar headerbar_sidebar;

	[GtkChild] unowned Gtk.Button button_create_note;
	[GtkChild] unowned Gtk.Button button_empty_trash;
	[GtkChild] unowned Gtk.Button button_back;
	[GtkChild] unowned Gtk.MenuButton button_more_menu;
	[GtkChild] unowned Gtk.Button button_open_in_notebook;
	[GtkChild] unowned Gtk.Button button_md_cheatsheet_headerbar;

	[GtkChild] unowned Gtk.Label note_title;
	[GtkChild] unowned Gtk.Label note_subtitle;
	[GtkChild] unowned Gtk.Label save_indicator;

	[GtkChild] unowned Adw.HeaderBar headerbar_edit_view;
	[GtkChild] unowned Gtk.Revealer headerbar_edit_view_revealer;

	[GtkChild] unowned EditView edit_view;
	[GtkChild] unowned Gtk.Box text_view_empty_notebook;
	[GtkChild] unowned Gtk.Box external_file_type_notebook;
	[GtkChild] unowned Gtk.Box text_view_empty_trash;
	[GtkChild] unowned Gtk.Box text_view_no_notebook;
	[GtkChild] unowned Gtk.PopoverMenu more_popover;

	[GtkChild] unowned Adw.ToastOverlay toast_overlay;

	private Gtk.CssProvider? last_css_provider = null;

	private ActionEntry[] ACTIONS = {
		{ "format-bold", on_format_bold },
		{ "format-italic", on_format_italic },
		{ "format-strikethrough", on_format_strikethrough },
		{ "format-highlight", on_format_highlight },

		{ "insert-link", on_insert_link },
		{ "insert-code-span", on_insert_code_span },
		{ "insert-horizontal-rule", on_insert_horizontal_rule },

		{ "toggle-sidebar", toggle_sidebar_visibility },
		{ "search-notes", toggle_search },
		{ "save-note", save_current_note },
		{ "toggle-fullscreen", toggle_fullscreen },
		{ "zoom-in", zoom_in },
		{ "zoom-out", zoom_out },
	};

	construct {
		window_model.note_changed.connect (on_update_note);
		window_model.state_changed.connect (on_update_state);
		window_model.notify["notes-model"].connect (() => {
			notebook_notes_list.model = window_model.notes_model;
			if (window_model.state == WindowModel.State.TRASH) {
				window_model.notes_model.items_changed.connect (() => {
					notebook_title.subtitle = Strings.X_NOTES.printf (window_model.note_container.get_n_items ());
				});
			}
		});
		window_model.set_notebook (null);

		add_action_entries (ACTIONS, this);

		var window_state = new Settings (@"$(Config.APP_ID).WindowState");
		set_default_size (window_state.get_int ("width"), window_state.get_int ("height"));
		maximized = window_state.get_boolean ("maximized");

		close_request.connect (() => {
			window_state.set_int ("width", default_width);
			window_state.set_int ("height", default_height);
			window_state.set_boolean ("maximized", maximized);
			return false;
		});

		Gtk.IconTheme.get_for_display (display).add_resource_path ("/com/toolstack/Folio/graphics/");

		set_text_view_state (TextViewState.NO_NOTEBOOK);

		button_back.clicked.connect (() => navigate_to_notes ());

		window_model.search_sorter.changed.connect ((change) => {
			notebook_notes_list_scroller.vadjustment.@value = 0;
		});
		notes_search_entry.search_changed.connect (() => {
			window_model.search (notes_search_entry.text);
		});
		var font_scale = new FontScale (edit_view);
		more_popover.add_child (font_scale, "font-scale");

		window_model.notify["is-unsaved"].connect (() => {
			save_indicator.visible = window_model.is_unsaved;
		});
	}

	public Window (Application app) {
		Object (
			application: app,
			title: "Folio",
			icon_name: Config.APP_ID
		);

		app.style_manager.notify["dark"].connect (() => edit_view.on_dark_changed (app.style_manager.dark));
		edit_view.on_dark_changed (app.style_manager.dark);

		leaflet.notify["folded"].connect (() => {
			update_title_buttons ();
			if (leaflet.folded) {
				update_editability ();
				navigate_to_edit_view ();
			} else {
				update_editability ();
				window_model.select_note (window_model.note);
			}
		});
		sidebar_revealer.notify["reveal-child"].connect (update_title_buttons);
		update_title_buttons ();

		edit_view.scrolled_window.vadjustment.notify["value"].connect (() => {
			var v = edit_view.scrolled_window.vadjustment.value;
			if (v == 0) headerbar_edit_view.remove_css_class ("overlaid");
			else headerbar_edit_view.add_css_class ("overlaid");
		});

		button_open_in_notebook.clicked.connect (() => window_model.open_note_in_notebook (window_model.note));

		notebook_notes_list_scroller.vadjustment.notify["value"].connect (update_sidebar_scroll);
		notes_search_bar.notify["search-mode-enabled"].connect (() => on_searchbar_mode_changed (notes_search_bar.search_mode_enabled));

		var motion_controller = new Gtk.EventControllerMotion ();
		double x = 0, y = 0;
		motion_controller.enter.connect ((_x, _y) => {
			x = _x;
			y = _y;
		});
		motion_controller.motion.connect ((_x, _y) => {
			// Only hide in desktop no sidebar mode
			if (!sidebar_revealer.reveal_child) {
				var dx = _x - x, dy = _y - y;
				if (dx != 0 || dy != 0)
					headerbar_edit_view_revealer.reveal_child = true;
			}
			x = _x;
			y = _y;
		});
		edit_view_page.child.add_controller (motion_controller);

		var settings = new Settings (Config.APP_ID);
		settings.bind ("cheatsheet-enabled", this, "cheatsheet-enabled", SettingsBindFlags.DEFAULT);
		settings.bind ("show-line-numbers", this, "show-line-numbers", SettingsBindFlags.DEFAULT);
		settings.bind ("show-all-notes", this, "show-all-notes", SettingsBindFlags.DEFAULT);
		settings.bind ("note-sort-order", this, "note-sort-order", SettingsBindFlags.DEFAULT);
		settings.bind ("notebook-sort-order", this, "notebook-sort-order", SettingsBindFlags.DEFAULT);

		notify["cheatsheet-enabled"].connect (update_cheatsheet_visibility);
		edit_view.toolbar.notify["compacted"].connect (update_cheatsheet_visibility);
		update_cheatsheet_visibility ();
		notebooks_bar.init (this);

		notify["show-line-numbers"].connect (update_show_line_numbers);
		notify["show-all-notes"].connect (update_show_all_notes);
		notify["note-sort-order"].connect (update_note_sort_order);
		notify["notebook-sort-order"].connect (update_notebook_sort_order);

		if (settings.get_boolean ("enable-autosave")) {
			GLib.Timeout.add (5000, () => {
				window_model.save_note (this);
				return true;
			}, 0 );
		}
	}

	private void toggle_fullscreen () {
		fullscreened = !fullscreened;
	}

	private void zoom_in () {
		edit_view.zoom_in ();
	}

	private void zoom_out () {
		edit_view.zoom_out ();
	}

	public void on_update_note (Note? note) {
		if (leaflet.folded) {
			if (note == null) navigate_to_notes ();
			else navigate_to_edit_view ();
		}
		update_note_title ();
		update_editability ();
		edit_view.buffer = window_model.current_buffer;
		edit_view.reset_scroll_position ();
		if (note != null) {
			var is_markdown = note.is_markdown;
			var is_text = note.is_text;

			edit_view.text_mode = !is_markdown;
			if (is_text) {
				var b = edit_view.buffer;
				if (b is GtkSource.Buffer) {
					var buf = b as GtkSource.Buffer;
					if (buf != null) {
						buf.language =
							GtkSource.LanguageManager.get_default ().guess_language (note.file_name, null);
					}
				}
			}

			note_title.label = (note.is_markdown) ? note.name : note.file_name;
			if (is_markdown || is_text) {
				set_text_view_state (TextViewState.TEXT_VIEW);
			} else {
				set_text_view_state (TextViewState.EXTERNAL_FILE);
			}
			// Zen mode
			// Autohide headerbar_edit_view when typing in desktop no sidebar mode
			window_model.current_buffer.begin_user_action.connect (() => {
				// Only hide in desktop no sidebar mode
				if (!sidebar_revealer.reveal_child)
					headerbar_edit_view_revealer.reveal_child = false;
				window_model.is_unsaved = true;
			});
		} else {
			note_title.label = null;
			set_text_view_state (window_model.state == WindowModel.State.TRASH ? TextViewState.EMPTY_TRASH : TextViewState.EMPTY_NOTEBOOK);
			window_model.select_note_at (-1);
		}
	}

	public void toast (string text) {
		var toast = new Adw.Toast (text);
		toast_overlay.add_toast (toast);
	}

	public void toggle_sidebar_visibility () {
		sidebar_revealer.reveal_child = !sidebar_revealer.reveal_child;
	}

	public void toggle_search () {
		notes_search_bar.search_mode_enabled = !notes_search_bar.search_mode_enabled;
	}

	public void search_notes (string query) {
		notes_search_bar.search_mode_enabled = true;
		notes_search_entry.text = query;
	}

	public void save_current_note () {
		message ("saving");
		window_model.save_note (this);
	}

	public void navigate_to_notes () {
		leaflet.visible_child = sidebar.child;
		if (leaflet.folded) {
			window_model.select_note (null);
		}
	}

	public void navigate_to_edit_view () { leaflet.visible_child = edit_view_page.child; }

	public void update_cheatsheet_visibility () {
		button_md_cheatsheet_headerbar.visible = cheatsheet_enabled && edit_view.toolbar.compacted;
	}

	public void update_show_line_numbers () {
		edit_view.set_line_numbers ();
	}

	public void update_show_all_notes () {
		var settings = new Settings (Config.APP_ID);
		notebooks_bar.all_button_enabled = settings.get_boolean ("show-all-notes");
	}

	public void update_note_sort_order () {
		var settings = new Settings (Config.APP_ID);
		var notebook = window_model.notebook;
		if (notebook != null) {
			notebook.sort_notes (settings.get_int ("note-sort-order"));
			notebook_notes_list.model = null;
			notebook_notes_list.model = window_model.notes_model;
			window_model.open_note_in_notebook (window_model.note);
		}
	}

	public void update_notebook_sort_order () {
		var notebook_provider = window_model.notebook_provider;
		if (notebook_provider != null) {
			var current_note = window_model.note;
			notebook_provider.unload ();
			notebook_provider.load ();
			window_model.open_note_in_notebook (current_note);
		}
	}

	private void on_format_bold () { edit_view.format_selection_bold (); }
	private void on_format_italic () { edit_view.format_selection_italic (); }
	private void on_format_strikethrough () { edit_view.format_selection_strikethrough (); }
	private void on_format_highlight () { edit_view.format_selection_highlight (); }
	private void on_insert_link () { edit_view.insert_link (); }
	private void on_insert_code_span () { edit_view.insert_code_span (); }
	private void on_insert_horizontal_rule () { edit_view.insert_horizontal_rule (); }

	private void update_sidebar_scroll () {
		var v = notebook_notes_list_scroller.vadjustment.value;
		if (v == 0 || notes_search_bar.search_mode_enabled) headerbar_sidebar.remove_css_class ("overlaid");
		else headerbar_sidebar.add_css_class ("overlaid");
		if (v == 0) notes_search_bar.remove_css_class ("overlaid");
		else notes_search_bar.add_css_class ("overlaid");
	}

	private void on_searchbar_mode_changed (bool enabled) {
		update_sidebar_scroll ();
		notebooks_bar.all_button_enabled = enabled;
		if (!enabled && window_model.state == WindowModel.State.ALL) {
			if (window_model.notebooks_model.get_n_items () != 0) {
				window_model.select_notebook_at (0);
			} else {
				window_model.set_notebook (null);
			}
		}
	}

	private void update_editability () {
		edit_view.is_editable = window_model.note != null && window_model.state == WindowModel.State.NOTEBOOK;
	}

	private void update_title_buttons () {
		var is_sidebar_hidden = leaflet.folded || !sidebar_revealer.reveal_child;
		headerbar_edit_view.show_start_title_buttons = is_sidebar_hidden;
		update_note_title ();
	}

	private void update_note_title () {
		var is_sidebar_hidden = leaflet.folded || !sidebar_revealer.reveal_child;
		var note = window_model.note;
		var show = is_sidebar_hidden && note != null;
		note_subtitle.label = show ? note.notebook.name : null;
		note_subtitle.visible = show;
	}

	private void on_update_state (WindowModel.State state, NoteContainer? container) {
		button_create_note.visible = state == WindowModel.State.NOTEBOOK;
		button_empty_trash.visible = state == WindowModel.State.TRASH;

		var notebook = (container is Notebook) ? container as Notebook : null;
		update_editability ();
		recolor (notebook);

		if (container != null) {
			set_text_view_state (state == WindowModel.State.TRASH ? TextViewState.EMPTY_TRASH : TextViewState.EMPTY_NOTEBOOK);
			notebook_title.title = container.name;
			notebook_title.subtitle = state == WindowModel.State.TRASH ? Strings.X_NOTES.printf (container.get_n_items ()) : null;
			notebook_title.update_property (Gtk.AccessibleProperty.LABEL, container.name, -1);

			var factory = new Gtk.SignalListItemFactory ();
			factory.setup.connect (obj => {
				var widget = new NoteCard ();
				widget.window = this;
				var li = obj as Gtk.ListItem;
				if (li != null ) {
			  		li.child = widget;
				}
			});
			factory.bind.connect (obj => {
				var list_item = obj as Gtk.ListItem;
				var widget = list_item.child as NoteCard;
				var item = list_item.item as Note;
				widget.note = item;
			});
			notebook_notes_list.factory = factory;

			navigate_to_notes ();
		} else {
			notebook_notes_list.factory = null;
			notebook_title.title = null;
			notebook_title.subtitle = null;
			set_text_view_state (TextViewState.NO_NOTEBOOK);
		}
	}

	private enum TextViewState {
		TEXT_VIEW,
		EMPTY_NOTEBOOK,
		EMPTY_TRASH,
		NO_NOTEBOOK,
		EXTERNAL_FILE
	}

	private void set_text_view_state (TextViewState state) {
		text_view_empty_notebook.visible = state == TextViewState.EMPTY_NOTEBOOK;
		text_view_empty_trash.visible = state == TextViewState.EMPTY_TRASH;
		text_view_no_notebook.visible = state == TextViewState.NO_NOTEBOOK;
		edit_view.visible = state == TextViewState.TEXT_VIEW;
		button_more_menu.visible = state == TextViewState.TEXT_VIEW && edit_view.is_editable;
		button_open_in_notebook.visible = state == TextViewState.TEXT_VIEW && window_model.state == WindowModel.State.ALL;
		external_file_type_notebook.visible = state == TextViewState.EXTERNAL_FILE;
	}

	private void recolor (Notebook? notebook) {
		var rgba = Gdk.RGBA ();
		var light_rgba = Gdk.RGBA ();
		var rgb = (notebook == null) ? Color.RGB () : Color.RGBA_to_rgb (notebook.color);
		var hsl = Color.rgb_to_hsl (rgb);
		{
			hsl.l = 0.5f;
			Color.hsl_to_rgb (hsl, out rgb);
			Color.rgb_to_RGBA (rgb, out rgba);
			hsl.l = 0.7f;
			Color.hsl_to_rgb (hsl, out rgb);
			Color.rgb_to_RGBA (rgb, out light_rgba);
		}
		if (last_css_provider != null)
			Gtk.StyleContext.remove_provider_for_display (display, last_css_provider);
		var css = new Gtk.CssProvider ();
		css.load_from_string (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;");
		Gtk.StyleContext.add_provider_for_display (display, css, -1);
		last_css_provider = css;
		edit_view.theme_color = rgba;
	}

	public void request_edit_note (Note note) {
		var popup = new NoteCreatePopup (this, note);
		popup.title = Strings.RENAME_NOTE;
		popup.present (this);
	}

	public void request_move_note (Note note) {
		var popup = new NotebookSelectionPopup (
			window_model.notebook_provider,
			Strings.MOVE_TO_NOTEBOOK,
			Strings.MOVE,
			(dest_notebook) => {
				if (!window_model.move_note (note, dest_notebook))
					toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, dest_notebook.name));
			}
		);
		popup.present (this);
	}

	public void request_delete_note (Note note) {
		show_confirmation_popup (
			Strings.DELETE_NOTE,
			Strings.DELETE_NOTE_CONFIRMATION.printf (note.name),
			() => try_delete_note (note)
		);
	}

	public void request_empty_trash () {
		show_confirmation_popup (
			Strings.EMPTY_TRASH,
			Strings.EMPTY_TRASH_CONFIRMATION,
			() => {
				window_model.update_note (null, this);
				window_model.empty_trash ();
			}
		);
	}

	public void request_new_notebook () {
		var popup = new NotebookCreatePopup (this);
		popup.title = Strings.NEW_NOTEBOOK;
		popup.present (this);
	}

	public void request_edit_notebook (Notebook notebook) {
		var popup = new NotebookCreatePopup (this, notebook);
		popup.title = Strings.EDIT_NOTEBOOK;
		popup.present (this);
	}

	public void request_delete_notebook (Notebook notebook) {
		show_confirmation_popup (
			Strings.DELETE_NOTEBOOK,
			Strings.DELETE_NOTEBOOK_CONFIRMATION.printf (notebook.name),
			() => try_delete_notebook (notebook)
		);
	}

	public void try_create_note (string name) {
		if (name.contains ("/")) {
			toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
			return;
		}
		if (name.replace(" ", "").length == 0) {
			toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
			return;
		}
		try {
			window_model.create_note (name);
		} catch (ProviderError e) {
			if (e is ProviderError.ALREADY_EXISTS)
				toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
			else if (e is ProviderError.COULDNT_CREATE_FILE)
				toast (Strings.COULDNT_CREATE_NOTE);
			else
				toast (Strings.UNKNOWN_ERROR);
		}
	}

	public bool try_rename_note (Note note, string file_name) {
		var dot_i = file_name.last_index_of_char ('.');
		var extension = (dot_i == -1) ? "md" : file_name.substring (dot_i + 1);
		var name = (dot_i == -1) ? file_name : file_name.substring (0, dot_i);

		if (name.contains ("/")) {
			toast (Strings.NOTE_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
			return false;
		}
		if (name.replace(" ", "").length == 0) {
			toast (Strings.NOTE_NAME_SHOULDNT_BE_BLANK);
			return false;
		}
		try {
			// Check to see if the note we're renaming is the current note displayed, if so, update
			// The note title and note display, otherwise just update the note on disk.
			if (window_model.note == note) {
				window_model.change_note (note, name, extension, true);
				note_title.label = (note.is_markdown) ? note.name : note.file_name;
			} else {
				window_model.change_note (note, name, extension, false);
			}
			return true;
		} catch (ProviderError e) {
			if (e is ProviderError.ALREADY_EXISTS)
				toast (Strings.NOTE_X_ALREADY_EXISTS.printf (name));
			else if (e is ProviderError.COULDNT_CREATE_FILE)
				toast (Strings.COULDNT_CHANGE_NOTE);
			else
				toast (Strings.UNKNOWN_ERROR);
			return false;
		}
	}

	public void try_delete_note (Note note) {
		try {
			window_model.update_note (null, this);
			//upon deletion of a note, we will select the next note DOWN the list (or none).
			var idx = note.notebook.get_index_of (note);

			note.notebook.delete_note (note);

			var item_count = note.notebook.get_n_items ();
			Note? new_active_note = null;
			if (item_count == 1 || idx == 0) { // selecting down, so first item or a list of 2 is the same.
				new_active_note = (Note) note.notebook.get_item (0);
			} else if (item_count > 1){
				new_active_note = (Note) note.notebook.get_item (idx - 1);
			}

			window_model.update_note (new_active_note, this);

			//if we are removing the last item we need to select a different index.
			//we really should be doing this somewhere else.
			if (idx == item_count)
				window_model.select_note_at (idx - 1);
			else
				window_model.select_note_at (idx);

			window_model.update_selected_note ();
		} catch (ProviderError e) {
			if (e is ProviderError.COULDNT_DELETE)
				toast (Strings.COULDNT_DELETE_NOTE);
			else
				toast (Strings.UNKNOWN_ERROR);
		}
	}

	public void try_export_note (Note note, File file) {
		FileUtils.save_to (file, window_model.current_buffer.get_all_text ());
		toast (Strings.SAVED_X_TO_X.printf (note.name, file.get_path ()));
	}

	public void try_restore_note (Note note) {
		try {
			window_model.restore_note (note);
			{
				var n = window_model.notebook_provider.notebooks;
				var i = 0;
				while (i < n.size) {
					if (n[i].name == note.notebook.name)
						break;
					i++;
				}
				if (i == n.size) {
					window_model.notebook_provider.unload ();
					window_model.notebook_provider.load ();
					window_model.update_notebooks ();
				}
			}
			window_model.select_notebook (note.notebook);
		} catch (ProviderError e) {
			if (e is ProviderError.COULDNT_MOVE) {
				toast (Strings.COULDNT_RESTORE_NOTE);
			} else if (e is ProviderError.ALREADY_EXISTS) {
				toast (Strings.NOTE_X_ALREADY_EXISTS_IN_X.printf (note.name, note.notebook.name));
			} else {
				toast (Strings.UNKNOWN_ERROR);
			}
		}
	}

	public void try_create_notebook (NotebookInfo info) {
		if (info.name.contains ("/")) {
			toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
			return;
		}
		if (info.name.replace(" ", "").length == 0) {
			toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
			return;
		}
		try {
			window_model.create_notebook (info);
		} catch (ProviderError e) {
			if (e is ProviderError.ALREADY_EXISTS)
				toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (info.name));
			else if (e is ProviderError.COULDNT_CREATE_FILE)
				toast (Strings.COULDNT_CREATE_NOTEBOOK);
			else
				toast (Strings.UNKNOWN_ERROR);
		}
	}

	public void try_change_notebook (Notebook notebook, NotebookInfo info) {
		if (info.name.contains ("/")) {
			toast (Strings.NOTEBOOK_NAME_SHOULDNT_CONTAIN_RESERVED_CHAR);
			return;
		}
		if (info.name.replace(" ", "").length == 0) {
			toast (Strings.NOTEBOOK_NAME_SHOULDNT_BE_BLANK);
			return;
		}
		try {
			window_model.change_notebook (notebook, info);
		} catch (ProviderError e) {
			if (e is ProviderError.ALREADY_EXISTS)
				toast (Strings.NOTEBOOK_X_ALREADY_EXISTS.printf (info.name));
			else if (e is ProviderError.COULDNT_CREATE_FILE)
				toast (Strings.COULDNT_CHANGE_NOTEBOOK);
			else
				toast (Strings.UNKNOWN_ERROR);
		}
	}

	public void try_delete_notebook (Notebook notebook) {
		try {
			window_model.delete_notebook (notebook);
		} catch (ProviderError e) {
			if (e is ProviderError.COULDNT_DELETE)
				toast (Strings.COULDNT_DELETE_NOTEBOOK);
			else
				toast (Strings.UNKNOWN_ERROR);
		}
	}

	public void show_confirmation_popup (
		string action_title,
		string action_description,
		owned Runnable callback
	) {
		var dialog = new Adw.AlertDialog (
			action_title,
			action_description
		);

		dialog.close_response = "cancel";
		dialog.add_response ("cancel", Strings.CANCEL);

		dialog.add_response ("do", action_title);
		dialog.set_response_appearance ("do", Adw.ResponseAppearance.DESTRUCTIVE);

		dialog.response.connect ((response_id) => {
			if (response_id == "do") {
				callback ();
			}
			dialog.close ();
		});
		dialog.present (this);
	}

	public void resize_toolbar () {
		edit_view.resize_toolbar ();
	}
}
