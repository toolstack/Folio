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

[GtkTemplate (ui = "/com/toolstack/Folio/markdown_cheatsheet.ui")]
public class Folio.MarkdownCheatsheet : Adw.Dialog {

	[GtkChild]
	unowned GtkMarkdown.View text_view;

	private Application app;

	public MarkdownCheatsheet (Application app) {
		Object (
			title: Strings.MARKDOWN_CHEATSHEET
		);

		this.app = app;

		try {
			var buffer = new GtkMarkdown.Buffer ();
			buffer.text = (string) resources_lookup_data (
				"/com/toolstack/Folio/markdown_cheatsheet.md",
				ResourceLookupFlags.NONE
			).get_data ();
			text_view.buffer = buffer;
		} catch (Error e) {}

		app.style_manager.notify["dark"].connect (on_dark_mode_enabled);
		text_view.dark = app.style_manager.dark;
	}

	private void on_dark_mode_enabled () {
		text_view.dark = app.style_manager.dark;
	}
}
