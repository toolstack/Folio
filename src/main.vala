/* main.vala
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

int main (string[] args) {
    Environment.set_prgname (Config.APP_ID);
    Intl.bindtextdomain (Config.APP_ID, Config.GNOMELOCALEDIR);
    Intl.bind_textdomain_codeset (Config.APP_ID, "UTF-8");
    Intl.textdomain (Config.APP_ID);
    Environment.set_application_name (Paper.Strings.APP_NAME);
	GtkSource.init ();
	var app = new Paper.Application ();
	return app.run (args);
}
