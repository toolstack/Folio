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
	unowned Adw.LeafletPage edit_view;

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

	Gtk.SingleSelection notebook_notes_model;

	[GtkChild]
	unowned Gtk.Button button_edit_notebook;

	[GtkChild]
	unowned Gtk.Button button_create_note;

	[GtkChild]
	unowned Gtk.Button button_empty_trash;

	[GtkChild]
	unowned Gtk.ToggleButton button_toggle_sidebar;

	[GtkChild]
	unowned Gtk.MenuButton button_more_menu;


	[GtkChild]
	unowned Adw.WindowTitle note_title;

	[GtkChild]
	unowned Gtk.Box toolbar;

	[GtkChild]
	unowned Gtk.ComboBox format_heading_type;

	[GtkChild]
	unowned GtkMarkdown.View text_view;

	[GtkChild]
	unowned Gtk.ScrolledWindow text_view_scroll;

	[GtkChild]
	unowned Gtk.Box text_view_empty;


	[GtkChild]
	unowned Adw.ToastOverlay toast_overlay;


	public bool is_editable = false;

	private FuzzyStringSorter search_sorter;


	public Window (Application app) {
		Object (
		    application: app,
		    title: "Paper",
		    icon_name: Config.APP_ID
	    );

        Gtk.IconTheme.get_for_display (display).add_resource_path ("/io/posidon/Paper/graphics/");

	    var settings = new Settings (Config.APP_ID);
		var note_font = settings.get_string ("note-font");

        {
		    var css = new Gtk.CssProvider ();
		    css.load_from_data (@"textview{font-family:'$(note_font)';}".data);
		    text_view.get_style_context ().add_provider (css, -1);
		}

        app.style_manager.notify["dark"].connect (() => text_view.dark = app.style_manager.dark);
        text_view.dark = app.style_manager.dark;
        text_view.notify["buffer"].connect (() => text_view.buffer.notify["cursor-position"].connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            format_heading_type.active = (int) text_view.get_title_level (cur.get_line ());
        }));
        format_heading_type.changed.connect (() => {
            var ins = text_view.buffer.get_insert ();
            Gtk.TextIter cur;
            text_view.buffer.get_iter_at_mark (out cur, ins);
            text_view.set_title_level (cur.get_line (), format_heading_type.active);
        });

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

        leaflet.notify["folded"].connect (() => {
            if (leaflet.folded) {
                update_toolbar_visibility ();
                button_toggle_sidebar.icon_name = "go-previous-symbolic";
	            notebook_notes_model.unselect_item (notebook_notes_model.selected);
            } else {
                update_toolbar_visibility ();
                button_toggle_sidebar.icon_name = "sidebar-show-symbolic";
	            button_toggle_sidebar.active = sidebar.child.visible;
            }
        });

        Gtk.TextIter start;
        text_view.buffer.get_start_iter (out start);
        text_view.buffer.place_cursor (start);
	}

	private void update_toolbar_visibility () {
        toolbar.visible = current_note != null && is_editable;
	}

	public void set_notebook (Notebook? notebook) {
	    is_editable = notebook != null;
	    text_view.sensitive = is_editable;
        recolor (notebook);
        button_edit_notebook.visible = notebook != null;
        button_create_note.visible = notebook != null;
        button_empty_trash.visible = false;
	    if (notebook != null) {
	        notebook.load ();
	        notebook_title.title = notebook.name;
	        notebook_title.subtitle = null;

            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NoteCard (false);
                widget.window = this;
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NoteCard;
                var item = list_item.item as Note;
                widget.note = item;
            });
            this.notebook_notes_model = new Gtk.SingleSelection (
                new Gtk.SortListModel (notebook, search_sorter)
            );
            this.notebook_notes_model.can_unselect = true;
		    this.notebook_notes_model.selection_changed.connect (() => {
	            var i = notebook_notes_model.selected;
	            if (i < notebook.loaded_notes.size) {
		            var note = notebook.loaded_notes[(int) i];
                    var app = application as Application;
		            app.set_active_note (note);
	                if (leaflet.folded)
	                    navigate_to_edit_view ();
		        }
	            else if (leaflet.folded)
	                navigate_to_notes ();
		    });
		    notebook_notes_list.factory = factory;
		    notebook_notes_list.model = notebook_notes_model;

		    if (notebook.loaded_notes.size != 0) {
	            var i = notebook_notes_model.selected;
	            if (i < notebook.loaded_notes.size) {
	                var note = notebook.loaded_notes[(int) i];
                    var app = application as Application;
	                app.set_active_note (note);
                }
		    }
            navigate_to_notes ();
	    } else {
		    notebook_notes_list.factory = null;
		    notebook_notes_list.model = null;
	    }
	}

	public void select_notebook (uint i) {
	    notebooks_bar.select_notebook (i);
	}

    private Note? current_note = null;

    private GtkMarkdown.Buffer current_buffer;

    public void optional_save () {
	    if (is_editable && current_note != null) {
            current_note.save (current_buffer.get_all_text ());
        }
    }

	public GtkMarkdown.Buffer? set_note (Note? note) {
        optional_save ();
	    current_note = note;
	    update_toolbar_visibility ();
	    if (note != null) {
	        note_title.title = note.name;
	        text_view_scroll.show ();
	        button_more_menu.show ();
	        text_view_empty.hide ();
	        current_buffer = new GtkMarkdown.Buffer (note.load_text ());
	        text_view.buffer = current_buffer;
            select_note (note.notebook.loaded_notes.index_of (note));
	    } else {
	        note_title.title = null;
	        text_view_scroll.hide ();
	        button_more_menu.hide ();
	        text_view_empty.show ();
	        current_buffer = null;
	        text_view.buffer = null;
	        select_note (-1);
        }
        return current_buffer;
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

	public void format_selection_bold () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "**", 2);
	    b.insert_at_cursor ("**", 2);
	    b.end_user_action ();
	}

	public void format_selection_italic () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "_", 1);
	    b.insert_at_cursor ("_", 1);
	    b.end_user_action ();
	}

	public void format_selection_strikethough () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "~~", 2);
	    b.insert_at_cursor ("~~", 2);
	    b.end_user_action ();
	}

	public void format_selection_highlight () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "==", 2);
	    b.insert_at_cursor ("==", 2);
	    b.end_user_action ();
	}

	public void insert_link () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    Gtk.TextIter iter_a, iter_b, iter;
	    {
	        var mark = b.get_selection_bound ();
	        b.get_iter_at_mark (out iter_a, mark);
	        b.get_iter_at_offset (out iter_b, b.cursor_position);
	        iter = iter_a.compare (iter_b) == -1 ? iter_a : iter_b;
	        b.insert (ref iter, "[", 1);
	    }
	    {
	        var mark = b.get_selection_bound ();
	        b.get_iter_at_mark (out iter_a, mark);
	        b.get_iter_at_offset (out iter_b, b.cursor_position);
	        iter = iter_a.compare (iter_b) == 1 ? iter_a : iter_b;
	        b.insert (ref iter, "]()", 3);
	    }
	    iter.backward_chars (3);
	    b.place_cursor (iter);
	    b.end_user_action ();
	}

	public void insert_code_span () {
	    var b = text_view.buffer;
	    b.begin_user_action ();
	    var mark = b.get_selection_bound ();
	    Gtk.TextIter iter;
	    b.get_iter_at_mark (out iter, mark);
	    b.insert (ref iter, "`", 1);
	    b.insert_at_cursor ("`", 1);
	    b.end_user_action ();
	}

	public void set_trash (Trash trash) {
        trash.load ();
        notebook_title.title = "Trash";
        notebook_title.subtitle = @"$(trash.get_n_items ()) notes";
        button_empty_trash.visible = true;

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (list_item => {
            var widget = new NoteCard (true);
            widget.window = this;
            list_item.child = widget;
        });
        factory.bind.connect (list_item => {
            var widget = list_item.child as NoteCard;
            var item = list_item.item as Note;
            widget.note = item;
        });
        this.notebook_notes_model = new Gtk.SingleSelection (
            trash
        );
        this.notebook_notes_model.items_changed.connect (() => {
            notebook_title.subtitle = @"$(trash.get_n_items ()) notes";
        });
        this.notebook_notes_model.can_unselect = true;
	    this.notebook_notes_model.selection_changed.connect (() => {
	        var i = notebook_notes_model.selected;
	        if (i < trash.loaded_notes.size) {
                var app = application as Application;
                var note = trash.loaded_notes[(int) i];
                app.set_active_note (note);
                if (leaflet.folded)
                    navigate_to_edit_view ();
            }
            else if (leaflet.folded)
                navigate_to_notes ();
	    });
	    notebook_notes_list.factory = factory;
	    notebook_notes_list.model = notebook_notes_model;

	    if (trash.loaded_notes.size != 0) {
            var i = notebook_notes_model.selected;
            if (i < trash.loaded_notes.size) {
                var note = trash.loaded_notes[(int) i];
                var app = application as Application;
                app.set_active_note (note);
            }
	    }

        navigate_to_notes ();
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
        var css = new Gtk.CssProvider ();
        css.load_from_data (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;".data);
        Gtk.StyleContext.add_provider_for_display (display, css, -1);
        text_view.theme_color = rgba;
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
	    leaflet.visible_child = edit_view.child;
	}
}
