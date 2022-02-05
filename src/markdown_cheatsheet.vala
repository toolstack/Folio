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
	[GtkTemplate (ui = "/io/posidon/Paper/markdown_cheatsheet.ui")]
	public class MarkdownCheatsheet : Adw.Window {

        [GtkChild]
        GtkSource.View text_view;

		public MarkdownCheatsheet () {
			Object (
			    title: "Markdown cheatsheet",
			    icon_name: Config.APP_ID
		    );

            var language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
	        var scheme = new GtkSource.StyleSchemeManager ().get_scheme ("paper");

            var buffer = new GtkSource.Buffer.with_language (language);
            buffer.style_scheme = scheme;
            buffer.text = (string) resources_lookup_data (
                "/io/posidon/Paper/markdown_cheatsheet.md",
                ResourceLookupFlags.NONE
            ).get_data ();
            text_view.buffer = buffer;
		}
	}
}
