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

[GtkTemplate (ui = "/io/posidon/Paper/window.ui")]
public class Paper.Window : Adw.ApplicationWindow {

	[GtkChild]
	unowned Adw.Leaflet leaflet;

	[GtkChild]
	unowned Adw.LeafletPage sidebar;

	[GtkChild]
	unowned Adw.LeafletPage edit_view_page;

	[GtkChild]
	unowned NotebooksBar notebooks_bar;


	[GtkChild]
	unowned Adw.WindowTitle notebook_title;

	[GtkChild]
	unowned Gtk.ListView notebook_notes_list;

	[GtkChild]
	unowned Gtk.ScrolledWindow notebook_notes_list_scroller;

	[GtkChild]
	unowned Gtk.SearchBar notes_search_bar;

	[GtkChild]
	unowned Gtk.SearchEntry notes_search_entry;

	[GtkChild]
	unowned Adw.HeaderBar headerbar_sidebar;

	Gtk.SingleSelection notebook_notes_model {
	    get { return (Gtk.SingleSelection) notebook_notes_list.model; }
	    set {
		    notebook_notes_list.model = value;
	    }
	}

	[GtkChild]
	unowned Gtk.Button button_create_note;

	[GtkChild]
	unowned Gtk.Button button_empty_trash;

	[GtkChild]
	unowned Gtk.ToggleButton button_toggle_sidebar;

	[GtkChild]
	unowned Gtk.MenuButton button_more_menu;

	[GtkChild]
	unowned Gtk.Button button_open_in_notebook;


	[GtkChild]
	unowned Adw.WindowTitle note_title;

	[GtkChild]
	public unowned EditView edit_view;

	[GtkChild]
	unowned Adw.HeaderBar headerbar_edit_view;

	[GtkChild]
	unowned Gtk.Box text_view_empty_notebook;

	[GtkChild]
	unowned Gtk.Box text_view_empty_trash;

	[GtkChild]
	unowned Gtk.Box text_view_no_notebook;


	[GtkChild]
	unowned Adw.ToastOverlay toast_overlay;

	private FuzzyStringSorter search_sorter;

	public State current_state {
	    public get;
	    private set;
	}

	private SimpleNoteContainer all_notes;

	public Window (Application app) {
		Object (
		    application: app,
		    title: "Paper",
		    icon_name: Config.APP_ID
	    );

        Gtk.IconTheme.get_for_display (display).add_resource_path ("/io/posidon/Paper/graphics/");

        all_notes = new SimpleNoteContainer (Strings.ALL_NOTES, app.notebook_provider.get_all_notes);

        set_notebook (null);

        search_sorter = new FuzzyStringSorter (
            new Gtk.PropertyExpression (typeof (Note), null, "name"));
        search_sorter.changed.connect ((change) => {
            notebook_notes_list_scroller.vadjustment.@value = 0;
        });
        notes_search_entry.search_changed.connect (() => {
            search_sorter.target = notes_search_entry.text;
        });

        notebooks_bar.init (this, app);

        button_toggle_sidebar.toggled.connect (() => set_sidebar_visibility (button_toggle_sidebar.active));

        app.style_manager.notify["dark"].connect (() => update_theme(app.style_manager.dark));
        update_theme(app.style_manager.dark);

        leaflet.notify["folded"].connect (() => {
            if (leaflet.folded) {
	            update_editability ();
                button_toggle_sidebar.icon_name = "go-previous-symbolic";
	            notebook_notes_model.unselect_item (notebook_notes_model.selected);
            } else {
	            update_editability ();
                button_toggle_sidebar.icon_name = "sidebar-show-symbolic";
	            button_toggle_sidebar.active = sidebar.child.visible;
            }
        });

        edit_view.scrolled_window.vadjustment.notify["value"].connect (() => {
            var v = edit_view.scrolled_window.vadjustment.value;
            if (v == 0) headerbar_edit_view.get_style_context ().remove_class ("overlaid");
            else headerbar_edit_view.get_style_context ().add_class ("overlaid");
        });

        button_open_in_notebook.clicked.connect (() => open_note_in_notebook (current_note, app));

        notebook_notes_list_scroller.vadjustment.notify["value"].connect (update_sidebar_scroll);
        notes_search_bar.notify["search-mode-enabled"].connect (() => on_searchbar_mode_changed (notes_search_bar.search_mode_enabled));
	}

	public void set_notebook (Notebook? notebook) {
	    set_state (notebook == null ? State.NO_NOTEBOOK : State.NOTEBOOK, notebook);
	}

	public void set_trash (Trash trash) {
	    set_state (State.TRASH, trash);
	}

	public void set_all () {
	    set_state (State.ALL, all_notes);
	}

	public GtkMarkdown.Buffer? set_note (Note? note) {
        optional_save ();
	    current_note = note;
	    update_editability ();
	    if (note != null) {
	        note_title.title = note.name;
	        set_text_view_state (TextViewState.TEXT_VIEW);
	        current_buffer = new GtkMarkdown.Buffer (note.load_text ());
	        edit_view.buffer = current_buffer;
	        var n = note.notebook.loaded_notes;
	        if (n != null)
                select_note (n.index_of (note));
	    } else {
	        note_title.title = null;
	        set_text_view_state (TextViewState.EMPTY_NOTEBOOK);
	        current_buffer = null;
	        edit_view.buffer = null;
	        select_note (-1);
        }
        return current_buffer;
	}

	public void select_notebook (uint i) {
	    notebooks_bar.select_notebook (i);
	}

    public void optional_save () {
	    if (edit_view.is_editable && current_note != null) {
            current_note.save (current_buffer.get_all_text ());
        }
    }

	public void select_note (uint i) {
	    notebook_notes_model.select_item (i, true);
	}

	public void update_selected_note () {
	    select_note (notebook_notes_model.selected);
	}

	public void toast (string text) {
        var toast = new Adw.Toast (text);
        toast_overlay.add_toast (toast);
	}

	public void set_sidebar_visibility (bool visibility) {
        if (visibility) {
            navigate_to_notes ();
        } else {
            navigate_to_edit_view ();
        }
	    if (!leaflet.folded) {
	        sidebar.child.visible = visibility;
	    }
	}

	public void toggle_sidebar_visibility () {
        button_toggle_sidebar.active = !button_toggle_sidebar.active;
	}

	public void toggle_search () {
	    notes_search_bar.search_mode_enabled = !notes_search_bar.search_mode_enabled;
	}

	public void search_notes (string query) {
	    notes_search_bar.search_mode_enabled = true;
	    notes_search_entry.text = query;
	}

	public void navigate_to_notes () {
        button_toggle_sidebar.active = true;
	    leaflet.visible_child = sidebar.child;
	    if (leaflet.folded) {
	        notebook_notes_model.unselect_item (notebook_notes_model.selected);
	    }
	}

	public void navigate_to_edit_view () {
        button_toggle_sidebar.active = false;
	    leaflet.visible_child = edit_view_page.child;
	}

	public void update_theme (bool dark) {
	    edit_view.on_dark_changed(dark);
	    var settings = new Settings (Config.APP_ID);
		var theme_oled = settings.get_boolean ("theme-oled");
		if (dark && theme_oled) {
		    if (black_css_provider == null) {
                var css = new Gtk.CssProvider ();
                css.load_from_resource (@"$(application.resource_base_path)/style-black.css");
                Gtk.StyleContext.add_provider_for_display (display, css, -1);
                black_css_provider = css;
            }
		}
		else {
            if (black_css_provider != null)
                Gtk.StyleContext.remove_provider_for_display (display, black_css_provider);
            black_css_provider = null;
		}
	}

    private Note? current_note = null;

    private GtkMarkdown.Buffer current_buffer;

    private NoteContainer? current_container = null;

    private Gtk.CssProvider? last_css_provider = null;

    private Gtk.CssProvider? black_css_provider = null;

	private void update_sidebar_scroll () {
        var v = notebook_notes_list_scroller.vadjustment.value;
        if (v == 0 || notes_search_bar.search_mode_enabled) headerbar_sidebar.get_style_context ().remove_class ("overlaid");
        else headerbar_sidebar.get_style_context ().add_class ("overlaid");
        if (v == 0) notes_search_bar.get_style_context ().remove_class ("overlaid");
        else notes_search_bar.get_style_context ().add_class ("overlaid");
	}

	private void on_searchbar_mode_changed (bool enabled) {
	    update_sidebar_scroll ();
	    notebooks_bar.all_button_enabled = enabled;
	}

	private void update_editability () {
	    edit_view.is_editable = current_note != null && current_state == State.NOTEBOOK;
	}

	public enum State {
	    NOTEBOOK,
	    NO_NOTEBOOK,
	    ALL,
	    TRASH
	}

	private void set_state (State state, NoteContainer? container = null) {
	    this.current_state = state;
        button_create_note.visible = state == State.NOTEBOOK;
        button_empty_trash.visible = state == State.TRASH;

        var last_container = current_container;
        current_container = container;

        var notebook = (container is Notebook) ? container as Notebook : null;
	    update_editability ();
        recolor (notebook);

        if (container != null) {
            container.load ();
            notebook_title.title = container.name;
            notebook_title.subtitle = state == State.TRASH ? Strings.X_NOTES.printf (container.get_n_items ()) : null;

            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NoteCard ();
                widget.window = this;
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NoteCard;
                var item = list_item.item as Note;
                widget.note = item;
            });
	        notebook_notes_list.factory = factory;

            var model = new Gtk.SingleSelection (
                new Gtk.SortListModel (container, search_sorter)
            );
            model.can_unselect = true;
		    model.selection_changed.connect (() => {
	            var i = model.selected;
	            if (i < container.loaded_notes.size) {
		            var note = model.get_item (i) as Note;
                    var app = application as Application;
		            app.set_active_note (note);
	                if (leaflet.folded)
	                    navigate_to_edit_view ();
		        }
	            else if (leaflet.folded)
	                navigate_to_notes ();
		    });

            if (state == State.TRASH) model.items_changed.connect (() => {
                notebook_title.subtitle = Strings.X_NOTES.printf (container.get_n_items ());
            });

            if (notebook_notes_model != null && notebook_notes_model != model)
                notebook_notes_model.model = null;
	        notebook_notes_model = model;

		    if (container.loaded_notes.size != 0) {
	            var i = model.selected;
	            if (i < container.loaded_notes.size) {
	                var note = container.loaded_notes[(int) i];
                    var app = application as Application;
	                app.set_active_note (note);
                }
		    } else {
		        set_text_view_state (state == State.TRASH ? TextViewState.EMPTY_TRASH : TextViewState.EMPTY_NOTEBOOK);
		    }

            navigate_to_notes ();
        } else {
            if (notebook_notes_model != null)
                notebook_notes_model.model = null;
		    notebook_notes_model = null;
	        notebook_notes_list.factory = null;
            notebook_title.title = null;
            notebook_title.subtitle = null;
		    set_text_view_state (TextViewState.NO_NOTEBOOK);
	    }

        if (last_container != null && last_container != container)
            last_container.unload ();
    }

	private enum TextViewState {
	    TEXT_VIEW,
	    EMPTY_NOTEBOOK,
	    EMPTY_TRASH,
	    NO_NOTEBOOK
	}

	private void set_text_view_state (TextViewState state) {
	    text_view_empty_notebook.visible = state == TextViewState.EMPTY_NOTEBOOK;
	    text_view_empty_trash.visible = state == TextViewState.EMPTY_TRASH;
	    text_view_no_notebook.visible = state == TextViewState.NO_NOTEBOOK;
        edit_view.visible = state == TextViewState.TEXT_VIEW;
        button_more_menu.visible = state == TextViewState.TEXT_VIEW && edit_view.is_editable;
        button_open_in_notebook.visible = state == TextViewState.TEXT_VIEW && current_state == State.ALL;
    }

    private void open_note_in_notebook (Note note, Application app) {
        var name = note.name;
        notes_search_bar.search_mode_enabled = false;
        app.select_notebook (note.notebook);
        Note? new_note_instance = null;
        foreach (var n in current_container.loaded_notes) {
            message (n.name);
            if (n.name == name) {
                new_note_instance = n;
                break;
            }
        }
        select_note (current_container.loaded_notes.index_of (new_note_instance));
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
        css.load_from_data (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;".data);
        Gtk.StyleContext.add_provider_for_display (display, css, -1);
        last_css_provider = css;
        edit_view.theme_color = rgba;
	}
}
