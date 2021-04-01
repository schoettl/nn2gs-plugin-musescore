#!/bin/bash
# Merge .qml.template with compiled .js files.

set -o errexit -o pipefail -o nounset

main() {
    declare version=$1
    declare apiUrl=$2
    declare templateFile=$3
    declare pureFile=$4
    declare impureFile=$5
    declare polyfillFile=$6
    sed -r \
        -e "/\/\/ PURE FUNCTIONS HERE:/r $pureFile" \
        -e "/\/\/ IMPURE FUNCTIONS HERE:/r $impureFile" \
        -e "s/^ +version: +\"[^\"]*\" .*/version: \"$version\"/" \
        "$templateFile" \
        | awk -vpolyfillFile="$polyfillFile" '1; /\/\/ POLYFILL IMPLEMENTATION HERE:/ {if(polyfillFile) system("cat \"" polyfillFile "\"")}' \
        | awk -vapiUrl="$apiUrl" '{if(apiUrl) sub(/http:\/\/localhost:[0-9]+\/nn2gs/, apiUrl)};1'

	# Alternatives:
	# awk '/\/\/ PURE FUNCTIONS HERE:/ { system("cat pure_functions.js"); skip }; 1' $< > $@
	# sed '/\/\/ PURE FUNCTIONS HERE:/e cat pure_functions.js' $< > $@
	# sed "/\/\/ PURE FUNCTIONS HERE:/a $$(<pure_functions.js)" $< > $@
}

main "$@"
