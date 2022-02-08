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

namespace Paper {
	[GtkTemplate (ui = "/io/posidon/Paper/window.ui")]
	public class Window : Adw.ApplicationWindow {

		[GtkChild]
		unowned Adw.Leaflet leaflet;

		[GtkChild]
		unowned Adw.LeafletPage sidebar;

		[GtkChild]
		unowned Adw.LeafletPage edit_view;

		[GtkChild]
		unowned Gtk.ListView notebooks_list;

		Gtk.SingleSelection notebooks_model;

		[GtkChild]
		unowned Gtk.ToggleButton trash_button;


		[GtkChild]
		unowned Adw.WindowTitle notebook_title;

		[GtkChild]
		unowned Gtk.ListView notebook_notes_list;

		Gtk.SingleSelection notebook_notes_model;

		[GtkChild]
		unowned Gtk.Button button_edit_notebook;

		[GtkChild]
		unowned Gtk.Button button_create_note;

		[GtkChild]
		unowned Gtk.Button button_empty_trash;

		[GtkChild]
		unowned Gtk.Button button_markdown_cheatsheet;

		[GtkChild]
		unowned Gtk.ToggleButton button_toggle_sidebar;


		[GtkChild]
		unowned Adw.WindowTitle note_title;

		[GtkChild]
		unowned Gtk.Button button_format_highlight;

		[GtkChild]
		unowned Gtk.Box format_box;

		[GtkChild]
		unowned GtkSource.View text_view;


		[GtkChild]
		unowned Adw.ToastOverlay toast_overlay;

		public bool is_editable = false;


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

            set_notebook (null);

            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NotebookIcon (app);
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NotebookIcon;
                var item = list_item.item as Notebook;
                widget.set_notebook (item);
            });
            this.notebooks_model = new Gtk.SingleSelection (
                app.notebook_provider
            );
            this.notebooks_model.can_unselect = true;
			this.notebooks_model.selection_changed.connect (() => {
			    uint i = notebooks_model.selected;
			    var notebooks = app.notebook_provider.notebooks;
			    if (i <= notebooks.size) {
			        var notebook = notebooks[(int) i];
			        app.set_active_notebook (notebook);
			        trash_button.active = false;
			    }
			});
			notebooks_list.factory = factory;
			notebooks_list.model = notebooks_model;

			if (app.notebook_provider.notebooks.size != 0) {
			    notebooks_model.selection_changed (0, 1);
			}

			trash_button.toggled.connect (() => {
		        trash_button.sensitive = !trash_button.active;
			    if (trash_button.active) {
			        notebooks_model.unselect_item (notebooks_model.selected);

			        // will call set_notebook (null) as a side effect
			        app.set_active_notebook (null);

			        set_trash (app.notebook_provider.trash);
			    }
			});

            button_toggle_sidebar.toggled.connect (() => set_sidebar_visibility (button_toggle_sidebar.active));
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
                    widget.set_window (this);
                    list_item.child = widget;
                });
                factory.bind.connect (list_item => {
                    var widget = list_item.child as NoteCard;
                    var item = list_item.item as Note;
                    widget.set_note (item);
                });
                this.notebook_notes_model = new Gtk.SingleSelection (
                    notebook
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
		    notebooks_model.selected = i;
		    notebooks_model.selection_changed (i, 1);
		}

		public void set_note (Note? note) {
	        format_box.visible = note != null && is_editable;
	        button_markdown_cheatsheet.visible = note != null && is_editable;
		    if (note != null) {
		        note_title.title = note.name;
		        text_view.show ();
		        text_view.buffer = note.text;
		    } else {
		        note_title.title = null;
		        text_view.hide ();
		        text_view.buffer = null;
	        }
		}

		public void select_note (uint i) {
		    notebook_notes_model.selected = i;
		    notebook_notes_model.selection_changed (i, (int) i == -1 ? 0 : 1);
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
		    var mark = b.get_selection_bound ();
		    Gtk.TextIter iter;
		    b.get_iter_at_mark (out iter, mark);
		    b.insert (ref iter, "**", 2);
		    b.insert_at_cursor ("**", 2);
		}

		public void format_selection_italic () {
		    var b = text_view.buffer;
		    var mark = b.get_selection_bound ();
		    Gtk.TextIter iter;
		    b.get_iter_at_mark (out iter, mark);
		    b.insert (ref iter, "_", 1);
		    b.insert_at_cursor ("_", 1);
		}

		public void format_selection_strikethough () {
		    var b = text_view.buffer;
		    var mark = b.get_selection_bound ();
		    Gtk.TextIter iter;
		    b.get_iter_at_mark (out iter, mark);
		    b.insert (ref iter, "~~", 2);
		    b.insert_at_cursor ("~~", 2);
		}

		public void format_selection_highlight () {
		    var b = text_view.buffer;
		    var mark = b.get_selection_bound ();
		    Gtk.TextIter iter;
		    b.get_iter_at_mark (out iter, mark);
		    b.insert (ref iter, "==", 2);
		    b.insert_at_cursor ("==", 2);
		}

		private void set_trash (Trash trash) {
	        trash.load ();
	        notebook_title.title = "Trash";
	        notebook_title.subtitle = @"$(trash.get_n_items ()) notes";
            button_empty_trash.visible = true;

            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NoteCard (true);
                widget.set_window (this);
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NoteCard;
                var item = list_item.item as Note;
                widget.set_note (item);
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
                rgba.alpha = 1f;
                rgba.red = rgb.r;
                rgba.green = rgb.g;
                rgba.blue = rgb.b;
                hsl.l = 0.7f;
                Color.hsl_to_rgb (hsl, out rgb);
                light_rgba.alpha = 1f;
                light_rgba.red = rgb.r;
                light_rgba.green = rgb.g;
                light_rgba.blue = rgb.b;
            }
            var css = new Gtk.CssProvider ();
            css.load_from_data (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;".data);
            Gtk.StyleContext.add_provider_for_display (display, css, -1);
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
}
