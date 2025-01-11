
VERSION := 1.5.1-ms36
API_URL := https://griffschrift-notation.de/nn2gs

.PHONY: publish
publish: build package
	$(info Publish at: https://musescore.org/en/project/nn2gs-normalnoten-zu-griffschrift-fur-steirische-harmonika)
	$(info make -C ~/projects/nn2gs deploy-static-files)

.PHONY: package
package: doc nn2gs-v$(VERSION).zip beispiele.zip

.PHONY: doc
doc: manual.pdf manual.html

.PHONY: build
build: nn2gs.qml nn2gs-v$(VERSION).qml

.PHONY: devbuild
devbuild: nn2gs.qml

nn2gs-v$(VERSION).zip: nn2gs-v$(VERSION).qml
	zip $@ $^

nn2gs.qml: nn2gs.qml.template pure_functions.js impure_functions.js
	./make-qml-file.sh $(VERSION) "" $^ "" > $@

nn2gs-v$(VERSION).qml: nn2gs.qml.template pure_functions.js.functions.compiled impure_functions.js.functions.compiled pure_functions.js.polyfills.compiled impure_functions.js.polyfills.compiled
	./make-qml-file.sh $(VERSION) $(API_URL) $^ > $@

pure_functions.js.functions.compiled: pure_functions.js.compiled
	awk '/^function / { p=1 };p' < $^ > $@

pure_functions.js.polyfills.compiled: pure_functions.js.compiled
	awk '/^function / { exit };NR>1' < $^ > $@

pure_functions.js.compiled: pure_functions.js
	# pretty-print because semicolon is not allowed after QML function definition.
	# Without language_out ES5, JS with let and lambdas is generated which is incompatible with MuseScore 3.6.2 and Qt 5.9.9!
	closure-compiler --rewrite_polyfills false --language_out ECMASCRIPT5 --formatting pretty_print $^ | sed '$$s/;$$//' > $@

impure_functions.js.functions.compiled: impure_functions.js.compiled
	awk '/^function / { p=1 };p' < $^ > $@

impure_functions.js.polyfills.compiled: impure_functions.js.compiled
	awk '/^function / { exit };NR>1' < $^ > $@

impure_functions.js.compiled: impure_functions.js
	# pretty-print because semicolon is not allowed after QML function definition.
	# Without language_out ES5, JS with let and lambdas is generated which is incompatible with MuseScore 3.6.2 and Qt 5.9.9!
	closure-compiler --rewrite_polyfills false --language_out ECMASCRIPT5 --formatting pretty_print $^ | sed '$$s/;$$//' > $@

beispiele.zip: beispiele/D-Dur.mscz beispiele/Griffschrift-Varianten.mscz beispiele/Weinschuetz_Landler_Teil_C.mscz beispiele/Terztonleiter.mscz
	zip $@ $^

manual.pdf: manual.org
	emacs $^ --batch -f org-latex-export-to-pdf --kill

manual.html: manual.org
	emacs $^ --batch -f org-html-export-to-html --kill

.PHONY: clean
clean:
	rm -f nn2gs.qml *.compiled manual.pdf
