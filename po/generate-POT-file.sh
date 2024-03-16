# Generates a new POT file for Folio
./print-source-files.sh > POTFILES
cd ../build
meson compile com.toolstack.Folio-pot
