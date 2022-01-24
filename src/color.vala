
namespace Color {
    class HSL {
        public float h;
        public float s;
        public float l;

        public HSL from_rgb (RGB rgb) {
            float s, v;
            Gtk.rgb_to_hsv(rgb.r, rgb.g, rgb.b, out h, out s, out v);
            this.l = v - v * s / 2;
            float m = float.min (l, 1 - l);
            this.s = (m != 0) ? (v-l)/m : 0;
            return this;
        }

        public inline HSL from_oklab (Oklab oklab) {
            return from_rgb (new RGB ().from_oklab (oklab));
        }
    }

    class RGB {
        public float r;
        public float g;
        public float b;

        public RGB from_hsl (HSL hsl) {
            float v = hsl.s * float.min (hsl.l, 1 - hsl.l) + hsl.l;
            float s = (v != 0) ? 2-2*hsl.l/v : 0;
            Gtk.hsv_to_rgb(hsl.h, s, v, out r, out g, out b);
            return this;
        }

        public RGB from_oklab (Oklab oklab) {
            return this;
        }

        public RGB from_RGBA (Gdk.RGBA rgba) {
            this.r = rgba.red;
            this.g = rgba.green;
            this.b = rgba.blue;
            return this;
        }
    }

    class Oklab {
        public double l;
        public double a;
        public double b;

        public Oklab from_rgb (RGB rgb) {
            return this;
        }

        public inline Oklab from_hsl (HSL hsl) {
            return from_rgb (new RGB ().from_hsl (hsl));
        }
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
