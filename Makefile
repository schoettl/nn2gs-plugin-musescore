
VERSION := 1.3.3
API_URL := https://ziach.intensovet.de/nn2gs

.PHONY: package
package: doc nn2gs-v$(VERSION).zip beispiele.zip

.PHONY: doc
doc: manual.pdf

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
	# pretty-print because semicolon is not allowed after QML function definition
	closure-compiler --rewrite_polyfills false --formatting pretty_print $^ | sed '$$s/;$$//' > $@

impure_functions.js.functions.compiled: impure_functions.js.compiled
	awk '/^function / { p=1 };p' < $^ > $@

impure_functions.js.polyfills.compiled: impure_functions.js.compiled
	awk '/^function / { exit };NR>1' < $^ > $@

impure_functions.js.compiled: impure_functions.js
	@# pretty-print because semicolon is not allowed after QML function definition
	closure-compiler --rewrite_polyfills false --formatting pretty_print $^ | sed '$$s/;$$//' > $@

beispiele.zip: beispiele/D-Dur.mscz beispiele/Griffschrift-Varianten.mscz beispiele/Weinschuetz_Landler_Teil_C.mscz beispiele/Terztonleiter.mscz
	zip $@ $^

manual.pdf: manual.org
	emacs $^ --batch -f org-latex-export-to-pdf --kill

.PHONY: clean
clean:
	rm -f nn2gs.qml *.compiled manual.pdf
