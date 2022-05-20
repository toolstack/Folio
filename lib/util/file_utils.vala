
namespace FileUtils {
    public void save_to (File file, string text) {
        try {
            if (file.query_exists ()) {
                string etag_out;
                uint8[] text_data = {};
                file.load_contents (null, out text_data, out etag_out);
                if (text == (string) text_data) {
                    return;
                }
                file.delete ();
            }
            var data_stream = new DataOutputStream (
                file.create (FileCreateFlags.REPLACE_DESTINATION)
            );
            uint8[] data = text.data;
            var l = data.length;
            long written = 0;
            while (written < l) {
                written += data_stream.write (data[written:data.length]);
            }
        } catch (Error e) {
            error (e.message);
        }
    }
}
