
namespace Color {
    public struct HSL {
        public float h;
        public float s;
        public float l;
    }

    public struct RGB {
        public float r;
        public float g;
        public float b;
    }

    public struct Oklab {
        public double l;
        public double a;
        public double b;
    }

    public HSL rgb_to_hsl (RGB rgb, out HSL hsl = null) {
        float s, v;
        Gtk.rgb_to_hsv(rgb.r, rgb.g, rgb.b, out hsl.h, out s, out v);
        hsl.l = v - v * s / 2;
        float m = float.min (hsl.l, 1 - hsl.l);
        hsl.s = (m != 0) ? (v-hsl.l)/m : 0;
        return hsl;
    }

    public inline HSL oklab_to_hsl (Oklab oklab, out HSL hsl = null) {
        var rgb = RGB ();
        return rgb_to_hsl (oklab_to_rgb (oklab, out rgb), out hsl);
    }

    public RGB hsl_to_rgb (HSL hsl, out RGB rgb = null) {
        float v = hsl.s * float.min (hsl.l, 1 - hsl.l) + hsl.l;
        float s = (v != 0) ? 2-2*hsl.l/v : 0;
        Gtk.hsv_to_rgb(hsl.h, s, v, out rgb.r, out rgb.g, out rgb.b);
        return rgb;
    }

    public RGB oklab_to_rgb (Oklab oklab, out RGB rgb = null) {
        return rgb;
    }

    public RGB RGBA_to_rgb (Gdk.RGBA rgba, out RGB rgb = null) {
        rgb.r = rgba.red;
        rgb.g = rgba.green;
        rgb.b = rgba.blue;
        return rgb;
    }

    public Oklab rgb_to_oklab (RGB rgb, out Oklab oklab = null) {
        return oklab;
    }

    public inline Oklab hsl_to_oklab (HSL hsl, out Oklab oklab = null) {
        var rgb = RGB ();
        return rgb_to_oklab (hsl_to_rgb (hsl, out rgb), out oklab);
    }

    public float get_luminance (float r, float g, float b) {
        return Math.sqrtf (0.299f * r * r + 0.587f * g * g + 0.114f * b * b);
    }

    public float get_luminance_photometric (float r, float g, float b) {
        return 0.2126f * r + 0.7152f * g + 0.0722f;
    }

    public float get_luminance_digital (float r, float g, float b) {
        return 0.299f * r + 0.587f * g + 0.114f;
    }
}
