/**
 * NaturalCollate
 * Simple helper class for natural sorting in Vala.
 *
 * (c) Tobia Tesan <tobia.tesan@gmail.com>, 2014
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the Lesser GNU General Public License
 * as published by the Free Software Foundation; either version 2.1
 * of the License, or (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * see <http://www.gnu.org/licenses/>.
 */

namespace NaturalCollate {

private const unichar SUPERDIGIT = ':';
private const unichar NUM_SENTINEL = 0x2; // glib uses these, so do we
private const string  COLLATION_SENTINEL = "\x01\x01\x01";

private static int read_number(owned string s, ref int byte_index) {
    /*
     * Given a string in the form [numerals]*[everythingelse]*
     * returns the int value of the first block and increments index
     * by its length as a side effect.
     * Notice that "numerals" is not just 0-9 but everything else 
     * Unicode considers a numeral (see: string::isdigit())
     */
    int number = 0;

    while (s.length != 0 && s.get_char(0).isdigit()) {
        number = number*10;
        number += s.get_char(0).digit_value();
        int second_char = s.index_of_nth_char(1);
        s = s.substring(second_char);
        byte_index += second_char;
    }
    return number;
}

public static int compare(string str1, string str2) {
    return strcmp(collate_key(str1), collate_key(str2));
}

public static string collate_key(owned string str) {
    /*
     * Computes a collate key.
     * Has roughly the same effect as g_utf8_collate_key_for_file, except that it doesn't
     * handle the dot as a special char.
     */
    assert (str.validate());
    string result = "";
    bool eos = (str.length == 0);

    while (!eos) {
        assert(str.validate());
        int position = 0;
        while (!(str.get_char(position).to_string() in "0123456789")) {
            // We only care about plain old 0123456789, aping what g_utf8_collate_key_for_filename does
            position++;
        }

        // (0... position( is a bunch of non-numerical chars, so we compute and append the collate key...
        result = result + (str.substring(0, position).collate_key());

        // ...then throw them away
        str = str.substring(position);

        eos = (str.length == 0);
        position = 0;

        if (!eos) {
            // We have some numbers to handle in front of us
            int number = read_number(str, ref position);
            str = str.substring(position);
            int number_of_superdigits = number.to_string().length;
            string to_append = "";
            for (int i = 1; i < number_of_superdigits; i++) {
                // We append n - 1 superdigits where n is the number of digits
                to_append = to_append + SUPERDIGIT.to_string();
            }
            to_append = to_append + (number.to_string()); // We append the actual number
            result = result +
                     COLLATION_SENTINEL +
                     NUM_SENTINEL.to_string() +
                     to_append;
        }
        eos = (str.length == 0);
    }

    result = result + NUM_SENTINEL.to_string();
    // No specific reason except that glib does it

    return result;
}
}
