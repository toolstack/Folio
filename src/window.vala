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
		unowned Gtk.ListView notebooks_list;

		Gtk.SingleSelection notebooks_model;


		[GtkChild]
		unowned Adw.WindowTitle notebook_title;

		[GtkChild]
		unowned Gtk.ListView notebook_notes_list;

		Gtk.SingleSelection notebook_notes_model;


		[GtkChild]
		unowned Adw.WindowTitle note_title;

		[GtkChild]
		unowned GtkSource.View text_view;


		[GtkChild]
		unowned Adw.ToastOverlay toast_overlay;


		public Window (Application app) {
			Object (
			    application: app,
			    title: "Paper",
			    icon_name: Config.APP_ID
		    );

		    var settings = new Settings (Config.APP_ID);
			var note_font = settings.get_string ("note-font");

            {
			    var css = new Gtk.CssProvider ();
			    css.load_from_data (@"textview{font-family:'$(note_font)';}".data);
			    text_view.get_style_context ().add_provider (css, -1);
			}

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
			this.notebooks_model.selection_changed.connect ((i, n) => {
			    var notebook = app.notebook_provider.notebooks[(int) notebooks_model.selected];
			    app.set_active_notebook (notebook);
			});
			notebooks_list.factory = factory;
			notebooks_list.model = notebooks_model;

			if (app.notebook_provider.notebooks.size != 0) {
			    notebooks_model.selection_changed (0, 1);
			}
		}

		public void set_notebook (Notebook? notebook) {
		    if (notebook != null) {
		        notebook.load ();
		        notebook_title.title = notebook.name;
		        //notebook_title.subtitle = @"$(notebook.get_n_items ()) notes";

                {
		            var rgba = Gdk.RGBA ();
		            var light_rgba = Gdk.RGBA ();
		            {
                        var rgb = new Color.RGB ().from_RGBA (notebook.color);
		                var hsl = new Color.HSL ().from_rgb (rgb);
		                hsl.l = 0.5f;
		                rgb.from_hsl (hsl);
		                rgba.alpha = 1f;
		                rgba.red = rgb.r;
		                rgba.green = rgb.g;
		                rgba.blue = rgb.b;
                        hsl.l = 0.7f;
		                rgb.from_hsl (hsl);
                        light_rgba.alpha = 1f;
                        light_rgba.red = rgb.r;
                        light_rgba.green = rgb.g;
                        light_rgba.blue = rgb.b;
		            }
		            {
			            var css = new Gtk.CssProvider ();
			            css.load_from_data (@"@define-color theme_color $rgba;".data);
			            Gtk.StyleContext.add_provider_for_display (display, css, -1);
			        }
			        {
		                var css = new Gtk.CssProvider ();
		                css.load_from_data (@"@define-color notebook_light_color $light_rgba;".data);
		                Gtk.StyleContext.add_provider_for_display (display, css, -1);
			        }
			    }

                var factory = new Gtk.SignalListItemFactory ();
                factory.setup.connect (list_item => {
                    var widget = new NoteCard ();
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
			    this.notebook_notes_model.selection_changed.connect ((i, n) => {
			        var note = notebook.loaded_notes[(int) notebook_notes_model.selected];
                    var app = application as Application;
			        app.set_active_note (note);
			    });
			    notebook_notes_list.factory = factory;
			    notebook_notes_list.model = notebook_notes_model;

			    if (notebook.loaded_notes.size != 0) {
			        notebook_notes_model.selection_changed (0, 1);
			    }
		    }
		}

		public void select_notebook (uint i) {
		    notebooks_model.selected = i;
		}

		public void set_note (Note? note) {
		    if (note != null) {
		        note_title.title = note.name;
		        text_view.show ();
		        text_view.buffer = note.text;
		    } else {
		        text_view.hide ();
	        }
		}

		public void select_note (uint i) {
		    notebook_notes_model.selected = i;
		}

		public void toast (string text) {
            var toast = new Adw.Toast (text);
            toast_overlay.add_toast (toast);
		}
	}
}
