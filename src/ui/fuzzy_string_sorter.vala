
public class Paper.FuzzyStringSorter : Gtk.Sorter {

    public FuzzyStringSorter (Gtk.Expression expression) {
        this._expression = expression;
    }

    public string? target {
        get { return _target; }
        set {
            _target = value.down ().normalize ();
            changed (Gtk.SorterChange.DIFFERENT);
        }
    }

    private string _target;
    private Gtk.Expression _expression;

    public override Gtk.SorterOrder get_order () {
        return (_target == null || _target.length == 0)
            ? Gtk.SorterOrder.NONE
            : Gtk.SorterOrder.PARTIAL;
    }

    public override Gtk.Ordering compare (Object? item1, Object? item2) {
        if (_target == null) return Gtk.Ordering.EQUAL;
        if (item1 == null) return Gtk.Ordering.EQUAL;
        if (item2 == null) return Gtk.Ordering.EQUAL;
        var d1 = get_distance (item1);
        var d2 = get_distance (item2);
        return (d1 == d2)
            ? Gtk.Ordering.EQUAL : (d1 > d2)
                ? Gtk.Ordering.LARGER
                : Gtk.Ordering.SMALLER;
    }

    private int get_distance (Object item) {
        //var val = Value (_expression.get_value_type ());
        //_expression.evaluate (item, val);
        var str = ((Note) item).name;
        if (str == null) return 0;
        return Util.search_distance (str.down ().normalize (), _target);
    }
}
