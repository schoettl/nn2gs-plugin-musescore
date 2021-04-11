
// from colornotes.qml:
// apply function to notes in selection (or all notes)
function applyToChordsInSelection(limit, func) {
      var cursor = curScore.newCursor();
      cursor.rewind(1);
      var startStaff;
      var endStaff;
      var endTick;
      var fullScore = false;
      if (!cursor.segment) { // no selection
            fullScore = true;
            startStaff = 0; // start with 1st staff
            endStaff = curScore.nstaves - 1; // and end with last
      } else {
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            if (cursor.tick === 0) {
                  // this happens when the selection includes
                  // the last measure of the score.
                  // rewind(2) goes behind the last segment (where
                  // there's none) and sets tick=0
                  endTick = curScore.lastSegment.tick + 1;
            } else {
                  endTick = cursor.tick;
            }
            endStaff = cursor.staffIdx;
      }
      console.log(`applyToChordsInSelection: ${startStaff} - ${endStaff} - ${endTick}`)
      let counter = 0
      for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                  cursor.rewind(1); // sets voice to 0
                  cursor.voice = voice; //voice has to be set after goTo
                  cursor.staffIdx = staff;

                  if (fullScore)
                        cursor.rewind(0) // if no selection, beginning of score

                  while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                      // Operator === does not work reliably
                      if (cursor.element && cursor.element.type == Element.CHORD) {
                          // The chord element includes grace notes
                          let graceChords = cursor.element.graceNotes;
                          for (let i = 0; i < graceChords.length; i++) {
                              func(graceChords[i])
                              counter++
                              if (counter >= limit) {
                                  return
                              }
                          }
                          func(cursor.element)
                          counter++
                          if (counter >= limit) {
                              return
                          }
                      }
                      cursor.next();
                  }
            }
      }
}

function populateInstrumentList() {
    let request = new XMLHttpRequest()
    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                console.log("Fetched instrument list:\n" + request.responseText)
                // request.response is not a JS object for some reason?!
                const result = JSON.parse(request.responseText)
                const model = comboModel.model
                model.clear()
                // Populate list; see also nn2gs.qml: comboModel -> ListModel
                result.map(i => model.append({ key: i.iModelId.toLowerCase(), value: i.iDescription, tonarten: JSON.stringify(i.iTonarten) }));
                comboModel.currentIndex = 0
            } else {
                console.log("Ignoring HTTP error on fetching instrument list.");
                console.log(request.status)
            }
        }
    }
    // const url = apiUrl + '/instruments?isGoodForGriffschrift'
    const url = apiUrl + '/instruments' // <-- for now, allow all instruments; see https://musescore.org/en/node/318711
    console.log('GET ' + url)
    request.open('GET', url, true)
    request.send()
}

// Adapted from abc import plugin
function callApi(chords, reverse, successCallback) {
    let content = JSON.stringify(chordsAsApiInput(chords, reverse))
    //console.log("content : " + content)
    let queryString = '?' +
        // queryStringArg('tonart', spinnerTonart.displayText, true) +
        queryStringArg('tonart', tonarten[spinnerTonart.value][1], true) +
        queryStringArg('model', comboModel.currentKey()) +
        (reverse ? queryStringArg('reverse', 'yes') : '') +
        (txtLicenseKey.text ? queryStringArg('license', txtLicenseKey.text) : '')

    console.log(queryString)

    let request = new XMLHttpRequest()
    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            console.log("HTTP status: " + request.status)
            if (request.status === 200) {
                console.log("API response:\n" + request.responseText)
                try {
                    lastResults = JSON.parse(request.responseText)
                } catch (e) {
                    console.error("Invalid JSON response. Could not parse.")
                    errorDialog.show("Ungültige Antwort vom Server.")
                }
                successCallback(chords, lastResults)
            } else if (request.status >= 500) {
                // Server-Fehler.
                errorDialog.show(`Fehler beim Server. Funktioniert ${apiUrl}?`)
            } else if (request.status >= 400) {
                // Fehler bei Kommunikation.
                errorDialog.show(`Fehler bei der Kommunikation mit dem Server. Funktioniert ${apiUrl}?`)
            } else if (request.status >= 300) {
                // Lizenzfehler?
                // TODO change error message when authorize system works...
                errorDialog.show(`Wahrscheinlich passt die Lizenz nicht oder Sie haben noch eine alte Version dieses Plugins. Überprüfen: ${apiUrl}?license=${txtLicenseKey.text}.`)
            } else {
                // Netzwerkfehler?
                errorDialog.show(`Unbekannter Netzwerkfehler (HTTP Status Code ${request.status}). Funktioniert das Internet? Funktioniert ${apiUrl}?`)
            }
        } else {
            // Netzwerkfehler?
            //errorDialog.show(`Wahrscheinlich Netzwerkfehler. Funktioniert das Internet? Funktioniert ${apiUrl}?`)
            console.log(`HTTP request ready status: ${request.readyState} (not DONE)`)
        }
    }
    console.log(`Run in shell for testing:
cat <<TEXT > test.json
${content}
TEXT
curl -H "Content-Type: application/json" --data-binary @test.json "${apiUrl + queryString}"
`)
    request.open("POST", apiUrl + queryString, true)
    request.setRequestHeader("Content-Type", "application/json")
    request.send(content)
}

function collectChords() {
    // It seems to work: Chords are always associated to a voice.
    const selectedVoices = parseVoicesFromTextField()
    let chords = []
    function chordCollecter(chord) {
        if (containsRedNote(chord)) {
            console.log(`Collecting chords: Current chord contains a red note. Skipping to next chord.`)
        } else if (selectedVoices.includes(chord.voice)) {
            chords.push(chord)
        }
    }
    applyToChordsInSelection(maxChordLimit + 1, chordCollecter)
    return chords
}

function changeNotes(zd, reverse) {
    return function(chords, zdResults) {
        lastZD = zd
        let results = extractZDResults(zd, zdResults)
        console.log(zd + ' ' + results)
        if (chords.length !== results.length) {
            console.warn(`Length of selected chords (${chords.length}) and translation result (${results.length}) do not match. Aborting.`)
            return
        }
        let change = reverse ? changeNotesOfChordReverse : changeNotesOfChord
        let invalidNotesCounter = 0
        let error = null
        curScore.startCmd()
        for (let i = 0; i < chords.length; i++) {
            let chord = chords[i]
            let result = results[i]
            // try {
                invalidNotesCounter += change(chord, result, zd, i)
            // } catch (e) {
            //     console.error(e.message)
            //     console.trace()
            //     error = e
            // }
        }
        curScore.endCmd()
        if (error) {
            errorDialog.show(`Fehler: ${error.message}`)
        }
        if (invalidNotesCounter) {
            errorDialog.show(`${invalidNotesCounter} Note(n) konnten nicht übersetzt werden und wurden rot markiert.\n\nEntweder existieren sie nicht auf dem Instrument oder sie waren bereits rot markiert. Die Akkorde mit roten Noten wurden bei der Übersetzung übersprungen.`)
        }
    }
}

function changeNotesOfChordReverse(chord, result, zd, chordIndex) {
    let notes = chord.notes
    let invalidNotesCounter = 0
    if (containsRedNote(notes)) {
        console.log(`Current chord ${chordIndex} contains a red note. Leaving it unchanged. Skipping to next chord.`)
        invalidNotesCounter++
        return invalidNotesCounter
    }
    if (result.Right) {
        let resultr = result.Right
        for (let j = 0; j < notes.length; j++) {
            let noteName = resultr[j]
            let note = notes[j]
            if (notes.length !== resultr.length) {
                console.warn(`Length of current chord (${notes.length}) and translation result (${resultr.length}) do not match in chord ${chordIndex}, note ${j}. Skipping to next chord.`)
                break
            }
            let pitch = getMidiPitch(noteName)
            if (pitch === null) {
                console.warn(`Invalid note position ${noteName} in translation result in chord ${chordIndex}, note ${j}. Skipping to next note.`)
                continue
            }
            let tpc = lookupTonalPitchClass(noteName)
            note.headGroup = NoteHeadGroup.HEAD_NORMAL
            removeCrossBeforeHead(note)
            note.mirrorHead = 0
            console.log(`Changing GS ${note.pitch} (tpc=${note.tpc}) to Nn ${pitch} (tpc=${tpc})`)
            note.pitch = pitch
            note.tpc1 = tpc
            note.tpc2 = tpc
            note.visible = true // Manche GS-Varianten machen Notenkopf unsichtbar und verwenden stattdessen ein anderes Symbol
            note.headType = NoteHeadType.HEAD_AUTO // Manche GS-Varianten ändern den Typ des Notenkopfes
            setAccidentalVisible(note, true)
            resetPlayedNotePitch(note)
        }
    } else if (result.Left) {
        let invalidSymbols = result.Left.map(({position, crossed}) => [getMidiPitch(position), crossed])
        for (let j = 0; j < notes.length; j++) {
            let note = notes[j]
            note.visible = true // Manche GS-Varianten machen Notenkopf unsichtbar und verwenden stattdessen ein anderes Symbol
            // Taste rot markieren, wenn sie auf Instrument nicht existiert
            if (invalidSymbols.some(([p, x]) => p == note.pitch && x == hasCrossedNoteHead(note))) {
            //if (invalidSymbols.includes([note.pitch, hasCrossedNoteHead(note)])) { <- doesn't work because it uses === :(
                note.color = colorRed
                invalidNotesCounter++
            }
        }
    } else {
        throw Error(`Invalid result for current chord ${chordIndex}: ${JSON.stringify(result)}`)
    }
    return invalidNotesCounter
}

function changeNotesOfChord(chord, result, zd, chordIndex) {
    let notes = chord.notes
    let invalidNotesCounter = 0
    if (containsRedNote(notes)) {
        console.log(`Current chord ${chordIndex} contains a red note. Leaving it unchanged. Skipping to next chord.`)
        invalidNotesCounter++
        return invalidNotesCounter
    }
    if (result.Right) {
        for (let j = 0; j < notes.length; j++) {
            let resAlternative = result.Right[alternativeIndex % result.Right.length]
            let res = resAlternative[j]
            let note = notes[j]
            if (notes.length !== resAlternative.length) {
                console.warn(`Length of current chord (${notes.length}) and translation result (${resAlternative.length}) do not match in chord ${chordIndex}, note ${j}. Skipping to next chord.`)
                break
            }
            let pitch = res.pitch
            if (pitch === null) {
                // Should never happen
                console.warn(`Invalid note position ${res.position} in translation result in chord ${chordIndex}, note ${j}. Skipping to next note.`)
                continue
            }
            let tpc = lookupTonalPitchClass(res.position)
            colorNoteZugDruck(note, zd, checkBoxColorZug)
            console.log(`Changing Nn ${note.pitch} (tpc=${note.tpc}) to GS ${pitch} (tpc=${tpc})`)
            note.pitch = pitch
            note.tpc1 = tpc
            note.tpc2 = tpc
            //note.line = 0 // The vertical position counted from top line; but has no effect.
            // Reset crossed note heads when cycling through alternatives:
            if (res.side === null || !checkBoxSortHeads.checked) {
                note.mirrorHead = 0
            } else if (res.side === 'Links') {
                note.mirrorHead = 1
            } else if (res.side === 'Rechts') {
                note.mirrorHead = 2
            }
            note.headGroup = NoteHeadGroup.HEAD_NORMAL
            removeCrossBeforeHead(note)
            setAccidentalVisible(note, false)
            if (res.extra && res.row === 0) {
                note.headGroup = NoteHeadGroup.HEAD_TRIANGLE_UP
            } else if (res.extra && res.row === 1) {
                // How does DIAMOND_OLD looks like?
                note.headGroup = NoteHeadGroup.HEAD_DIAMOND
            } else if (res.crossed) {
                const selectedVariant = comboTabulatureDisplay.currentKey()
                console.log(selectedVariant)
                switch (selectedVariant) {

                case 'klassisch_kreuz':
                    // No difference between row 3 and 4; all crosses before note head.
                    addCrossLightBeforeHead(note)
                    break

                case 'klassisch_doppelkreuz':
                    // No difference between row 3 and 4; all crosses before note head.
                    addCrossSharp2BeforeHead(note)
                    break

                case 'johannesservi.de':
                    if (isHalfOrLonger(chord)) {
                        note.headGroup = NoteHeadGroup.HEAD_WITHX
                        // Damit die Kreislinie überall gleich dick ist; ansonsten ist es
                        // einfach eine Halbe/Ganze mit Kreuz, sieht aber blöd aus.
                        note.headType = NoteHeadType.HEAD_QUARTER
                    } else {
                        note.headGroup = NoteHeadGroup.HEAD_CROSS
                    }
                    break

                case 'johannesservi.de_2':
                    if (isHalfOrLonger(chord)) {
                        note.headGroup = NoteHeadGroup.HEAD_XCIRCLE // same as SymId.noteheadVoidWithX?
                    } else {
                        note.headGroup = NoteHeadGroup.HEAD_CROSS
                    }
                    break

                case 'matthiaspuerner.de':
                    if (isHalfOrLonger(chord)) {
                        addCrossSharp2BeforeHead(note)
                    } else {
                        note.headGroup = NoteHeadGroup.HEAD_CROSS
                    }
                    break

                case 'knoepferl.at':
                    // The cross for notes of row 4 are heavier than row 3
                    if (res.row === 2) {
                        addCrossLightBeforeHead(note)
                    } else {
                        addCrossSharp2BeforeHead(note)
                    }
                    break

                case 'michlbauer.com':
                    if (res.row === 2) {
                        addCrossLightBeforeHead(note)
                    } else {
                        addCrossCircledBeforeHead(note) // TODO in Wirklichkeit ist das Symbol noch kleiner
                    }
                    break

                case 'dickes_kreuz':
                    // Wie klassisch_kreuz, aber DICKES Kreuz für Tasten in 4. Reihe
                    if (res.row === 2) {
                        addCrossLightBeforeHead(note)
                    } else {
                        addCrossBoldBeforeHead(note)
                    }
                    break

                case 'klassisch_kreuz2':
                    // Wie klassisch_kreuz, aber Kreuz als Notenkopf (nur bei Halben/Ganzen vor dem Notenkopf)
                    if (isHalfOrLonger(chord)) {
                        addCrossLightBeforeHead(note)
                    } else {
                        note.headGroup = NoteHeadGroup.HEAD_CROSS
                    }
                    break

                case 'klassisch_doppelkreuz2':
                    // Wie klassisch_doppelkreuz, aber Doppelkreuz als Notenkopf (nur bei Halben/Ganzen vor dem Notenkopf)
                    if (isHalfOrLonger(chord)) {
                        addCrossSharp2BeforeHead(note)
                    } else {
                        note.visible = false // note head invisible
                        // Geht nur in Leland, weil sonst Lücke zwischen Hals und Kopf:
                        addSymbolToNote(note, SymId.accidentalDoubleSharp, 0.1)
                        //addSymbolToNote(note, SymId.noteheadXOrnate, 0.1) // je nach Schriftart unterschiedlich zu echtem Doppelkreuz
                    }
                    break

                default: // 'modern'
                    note.headGroup = NoteHeadGroup.HEAD_CROSS
                    break
                }
            }
            fixPlayedNotePitch(note, res.origPitch)
        }
    } else if (result.Left) {
        let invalidPitches = result.Left.map(getMidiPitch)
        for (let j = 0; j < notes.length; j++) {
            let note = notes[j]
            // Ton rot markieren, wenn er auf Instrument nicht existiert
            if (invalidPitches.includes(note.pitch)) {
                note.color = colorRed
                invalidNotesCounter++
            }
        }
    } else {
        throw Error(`Invalid result for current chord ${chordIndex}: ${JSON.stringify(result)}`)
    }
    return invalidNotesCounter
}

function handleClickZugDruck(zd) {
    let reverse = isReverseDirection()
    console.log(`Starting translation: ${zd}${reverse ? ' reverse' : ''}`)
    let chords = collectChords()
    if (chords.length === 0) {
        console.warn("Keine Noten ausgewählt. Abbruch.")
        return
    }
    if (chords.length > maxChordLimit) {
        console.warn("Zu viele Noten ausgewählt. Abbruch.")
        return
    }
    // Sonderfall: Alternative Griffweisen durchzappen
    if (btnReverseDirection.state === 1 && !isCurrentResultValid()) {
        console.log("Alternative Griffweisen durchzappen")
        callApi(chords, /* GS → Nn: reverse = */ true, toGriffschrift(zd))
        return
    }
    if (reverse || !isCurrentResultValid()) {
        if (looksLikeGriffschrift(chords) && !reverse) {
            console.warn("Markierte Noten sehen nach Griffschrift aus. Abbruch.")
            warningDialog.show("Markierte Noten sehen nach Griffschrift aus und können so nicht nach Griffschrift übersetzt werden.")
            return
        }
        alternativeIndex = 0
        callApi(chords, reverse, changeNotes(zd, reverse))
        btnNextAlternative.enabled = true
    } else {
        // Reuse lastResults
        if (zd !== lastZD) {
            alternativeIndex = 0
        } else {
            alternativeIndex += 1
        }
        changeNotes(zd, false)(chords, lastResults)
    }
    invalidateResultsAfterTimeout()
    if (reverse) {
        disableZDButtonsForTimeout()
    }
}

function makePlayable() {
    invalidateCurrentResults()
    let chords = collectChords()
    if (chords.length === 0) {
        console.warn("Keine Noten ausgewählt. Abbruch.")
        return
    }
    if (chords.length > maxChordLimit) {
        console.warn("Zu viele Noten ausgewählt. Abbruch.")
        return
    }
    // TODO Look how it's done in handleZug / handleDruck
    // Get zd from note color (future: Druckbalken).
    // I need a reverse API call but mostly code from changeNotesOfChord.
    //callApi(chords, true, (chords, zdResults) => {
    //    console.log("finished reverse api call to make GS playable")
    //})
}

function toGriffschrift(zd) {
    return (chords, zdResults) => {
        let results = extractZDResults(zd, zdResults)
        let constructedChords = constructChordsFromNormalResults(results)
        console.log("Aus Normalnoten (die API zurückgeliefert hat) werden jetzt MuseScore Notes erstellt, die dann in GS umgewandelt werden: " + JSON.stringify(constructedChords))
        alternativeIndex = 0 // Can we set this to current alteranitive? Only if originalGSChords are passed to changeNotes.
        let reverse = false // Nn → GS
        callApi(constructedChords, reverse, changeNotes(zd, reverse))
    }
}

function parseVoicesFromTextField() {
    const text = txtVoices.text
    let result = []
    for (let i = 0; i < text.length; i++) {
        if (text[i].match(/[1-4]/)) {
            const voiceIndex = parseInt(text[i]) - 1;
            result.push(voiceIndex)
        }
    }
    if (result.length === 0) {
        result = [0]
    }
    return result
}

// Implements jsArray.find().map(); if not found, return null.
function find(list, filterFun, mapFun) {
    // .find() and .first() are not supported by normal JS arrays...
    const result = list.filter(filterFun).map(mapFun)
    return result ? result[0] : null;
}

function getGermanNoteNamesFromNotes(noteList) {
    let noteNames = []
    for (let i = 0; i < noteList.length; i++) {
        const note = noteList[i]
        const name = find(midiPitchMap, ([_, p]) => note.pitch == p, ([n, _]) => n)
        const nameGerman = find(germanNoteNames, ([n, _]) => n === name, ([_, n]) => n)
        if (nameGerman) {
            noteNames.push(nameGerman)
        }
    }
    return noteNames
}

function lblShowInstrumentClick() {
    // TODO Directly open first selected chord? note names must be in German for this!
    const model = comboModel.currentKey()
    const chords = collectChords()
    const notes = chords.length > 0 ? chords[0].notes : []
    const noteNames = getGermanNoteNamesFromNotes(notes)
    const noteNamesJoined = noteNames.join(' ')
    console.log(noteNamesJoined)
    Qt.openUrlExternally(apiUrl + '?' +
                            queryStringArg('model', model, true) +
                            (noteNames.length ? queryStringArg('notes', noteNamesJoined, false) : '') +
                            (txtLicenseKey.text ? queryStringArg('license', txtLicenseKey.text) : ''))
}

function lblCurrentKeyClick() {
    let keysig = curScore.keysig
    console.log(`Globale Dur-Tonart: ${keysig}`)
    spinnerTonart.value = 8 + keysig
}

function checkBoxColorZugClick() {
    if (!checkBoxColorZug.checked) {
        curScore.startCmd()
        applyToChordsInSelection(1000, (chord) => {
            for (let j = 0; j < chord.notes.length; j++) {
                let note = chord.notes[j]
                if (note.color == colorBlue) {
                    note.color = colorBlack
                }
            }
        })
        curScore.endCmd()
    }
}
