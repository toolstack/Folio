# Prints out all *.c and *.blp files in the project
# Useful for updating the POTFILES file (run from this directory)
pushd ../ > /dev/null
(find data -name app.*; find src -name *.blp; find src -name strings.vala) | sort
popd > /dev/null