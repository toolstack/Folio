

namespace Util {

	public int search_distance (string item, string query) {
		var words = item.split_set (" _-");
		var query_words = query.split_set (" _-");
		var base_distance = 0;
		var min_word = int.MAX;
		foreach (var i in words) {
			if (i.length == 0) continue;
			var min = int.MAX;
			foreach (var q in query_words) {
				if (q.length == 0) continue;
				min = int.min (min, damerau_levenshtein_distance (i, q, 5, 3, 2, 1));
			}
			base_distance += min;
			min_word = int.min (min_word, min);
		}
		return (base_distance + min_word) / words.length / 2;
	}

	/**
	 * This implementation is an adaptation based on Kevin L. Stern's work
	 * https://github.com/KevinStern/software-and-algorithms
	 *
	 * The running time of the Damerau-Levenshtein algorithm is O(n*m) where n is
	 * the length of the source string and m is the length of the target string.
	 * This implementation consumes O(n*m) space.
	 */
	public int damerau_levenshtein_distance (
		string source,
		string target,
		int insert_cost,
		int delete_cost,
		int replace_cost,
		int swap_cost
	) {
		int delete_distance = 0;
		int insert_distance = 0;
		int match_distance = 0;
		int jSwap = 0;
		int maxSourceLetterMatchIndex = 0;
		int? candidateSwapIndex = 0;
		int swap_distance = 0;

		if (source.length == 0)
			return target.length * insert_cost;

		if (target.length == 0)
			return source.length * delete_cost;

		var table = new int[source.length, target.length];
		var sourceIndexByCharacter = new Gee.HashMap<unichar, int> ();

		if (source.get_char (0) != target.get_char (0))
			table[0, 0] = int.min (replace_cost, delete_cost + insert_cost);

		sourceIndexByCharacter.@set (source.get_char (0), 0);

		for (int i = 1; i < source.length; i++) {
			delete_distance = table[i - 1, 0] + delete_cost;
			insert_distance = (i + 1) * delete_cost + insert_cost;
			match_distance = i * delete_cost + (source.get_char (i) == target.get_char (0) ? 0 : replace_cost);
			table[i, 0] = int.min (int.min (delete_distance, insert_distance), match_distance);
		}

		for (int j = 1; j < target.length; j++) {
			delete_distance = (j + 1) * insert_cost + delete_cost;
			insert_distance = table[0, j - 1] + insert_cost;
			match_distance = j * insert_cost + (source.get_char (0) == target.get_char (j) ? 0 : replace_cost);
			table[0, j] = int.min (int.min (delete_distance, insert_distance), match_distance);
		}

		for (int i = 1; i < source.length; i++) {
			maxSourceLetterMatchIndex = source.get_char (i) == target.get_char (0) ? 0 : -1;
			for (int j = 1; j < target.length; j++) {
				candidateSwapIndex = sourceIndexByCharacter.@get (target.get_char (j));
				jSwap = maxSourceLetterMatchIndex;
				delete_distance = table[i - 1, j] + delete_cost;
				insert_distance = table[i, j - 1] + insert_cost;
				match_distance = table[i - 1, j - 1];

				if (source.get_char (i) != target.get_char (j))
					match_distance += replace_cost;
				else
					maxSourceLetterMatchIndex = j;

				if (candidateSwapIndex != null && jSwap != -1) {
					int iSwap = candidateSwapIndex;
					int preswap_cost;
					if (iSwap == 0 && jSwap == 0)
					  preswap_cost = 0;
					else
					  preswap_cost = table[int.max (0, iSwap - 1), int.max (0, jSwap - 1)];
					swap_distance = preswap_cost + (i - iSwap - 1) * delete_cost + (j - jSwap - 1) * insert_cost + swap_cost;
				}
				else swap_distance = int.MAX;
				table[i, j] = int.min (int.min (int.min (delete_distance, insert_distance), match_distance), swap_distance);
			}
			sourceIndexByCharacter.@set (source.get_char (i), i);
		}
		return table[source.length - 1, target.length - 1];
	}
}
