
// Des hod an Deife g'seng! Lässt MuseScore abstürzen, also ist wohl nicht wirklich non-recursive.
function jsonStringifyNonRecursive(obj) {
    let seen = []
    return JSON.stringify(obj, (_, value) => {
        if (typeof value === 'object' && value !== null) {
            if (seen.includes(value)) return
            else seen.push(value)
        }
        return value
    })
}

function propertiesOfObject(obj) {
    let result = []
    for (let x in obj) result.push(x)
    return result
}

function findTonartIndex(tonarten, tonart) {
    let i = tonarten.findIndex(([i, x, _]) => x == tonart)
    if (i >= 0) return i
    return 8
}

// Make Griffschrift note sound like it sounds.
function fixPlayedNotePitch(note, originalPitch) {
    // console.log(`playEvents[0]: ${note?.playEvents?.[0]}`)
    // console.log(`playEvents: ${jsonStringifyNonRecursive(note.playEvents)}`)
    for (let i = 0; i < note.playEvents.length; i++) {
        note.playEvents[i].pitch = originalPitch - note.pitch
    }
}

function resetPlayedNotePitch(note) {
    for (let i = 0; i < note.playEvents.length; i++) {
        note.playEvents[i].pitch = 0
    }
}

function colorNoteZugDruck(note, zd, checkBoxColorZug) {
    if ((note.color == colorBlue || note.color == colorRed) && zd !== 'zug') {
        note.color = colorBlack
    } else if (checkBoxColorZug.checked && zd === 'zug') {
        note.color = colorBlue
    }
}

function setAccidentalVisible(note, visible) {
    // This function often has no effect when converting to GS.
    // Zum Beispiel hat der Gleichton der 2. Reihe bei b-Tonarten ein
    // Auflösungszeichen, das aber nicht unsichtbar gemacht werden
    // kann (note.accidental ist nicht true). Grund ist wahrscheinlich,
    // dass das Auflösungszeichen erst bei endCmd() hinzugefügt wird
    // und deswegen hier noch nicht zur Verfügung steht.
    if (note.accidental) {
        note.accidental.visible = visible
    }
}

function addCrossLightBeforeHead(note) {
    addSymbolToNote(note, SymId.noteheadXBlack, -1.3)
}

function addCrossBoldBeforeHead(note) {
    addSymbolToNote(note, SymId.noteheadHeavyX, -1.5)
}

function addCrossSharp2BeforeHead(note) {
    // SymId.noteheadXOrnate is pretty much the same as accidentalDoubleSharp
    addSymbolToNote(note, SymId.accidentalDoubleSharp, -1.15)
}

function addCrossCircledBeforeHead(note) {
    // This one is much bigger with default font Leland/Emmentaler than in Bravura.
    // Only looks good in Bravura, to me.
    addSymbolToNote(note, SymId.noteheadCircleX, -1.1)
}

function addSymbolToNote(note, symId, xoffset) {
    let cross = newElement(Element.SYMBOL)
    cross.symbol = symId
    cross.offsetX = xoffset
    note.add(cross)
}

function isCrossSymbol(element) {
    return element.type == Element.SYMBOL &&
        (element.symbol == SymId.noteheadXBlack  || // light cross
         element.symbol == SymId.noteheadHeavyX  || // heavy cross
         element.symbol == SymId.noteheadXOrnate || // heavy cross, Doppelkreuz
         element.symbol == SymId.noteheadCircleX || // light cross in small circle for 4. Reihe (Michlbauer)
         element.symbol == SymId.accidentalDoubleSharp  || // in Bravura gleich noteheadXOrnate
         element.symbol == SymId.accidentalDoubleArabic || // in Bravura gleich noteheadXOrnate
         element.symbol == SymId.noteheadVoidWithX || // cross in circle for half/whole notes (Servi)
         element.symbol == SymId.noteheadHalfWithX || // hässlicher
         element.symbol == SymId.noteheadWholeWithX)  // noch hässlicher
}

function hasCrossSymbol(note) {
    for (let i = 0; i < note.elements.length; i++) {
        let elem = note.elements[i]
        if (isCrossSymbol(elem)) {
            return true
        }
    }
}

function removeCrossBeforeHead(note) {
    for (let i = 0; i < note.elements.length; i++) {
        let elem = note.elements[i]
        if (isCrossSymbol(elem)) {
            note.remove(elem)
        }
    }
}

function removeAllLyrics(chord) {
    for (let i = 0; i < chord.lyrics.length; i++) {
        let elem = chord.lyrics[i]
        chord.remove(elem)
        // TODO Bug: This function seem to not always remove all
        // lyrics. Sometimes one verse stays.
        //console.log(`lyrics to remove: ${elem}`)
    }
}

function isHalfOrWhole(chord) {
    return durationIs(chord, 1) || durationIs(chord, 2)
}

function isHalfOrLonger(chord) {
    return (chord.duration.numerator / chord.duration.denominator) >= 0.5
}

function durationIs(chord, value) {
    // value = Notenwert: 1 = Ganze, 2 = Halbe usw.
    //console.log(`Note duration: ${chord.duration.numerator} / ${chord.duration.denominator}`)
    return chord.duration.numerator == 1 && chord.duration.denominator == value
}

function hasSpecialNoteHead(note) {
    return hasCrossSymbol(note) ||
           note.headGroup != NoteHeadGroup.HEAD_NORMAL
}
function hasCrossedNoteHead(note) {
    return hasCrossSymbol(note) ||
           note.headGroup == NoteHeadGroup.HEAD_CROSS ||
           note.headGroup == NoteHeadGroup.HEAD_XCIRCLE ||
           note.headGroup == NoteHeadGroup.HEAD_WITHX
}
function looksLikeGriffschrift(chords) {
    let result = chords.map((chord) => {
        for (let i = 0; i < chord.notes.length; i++) {
            let note = chord.notes[i]
            if (hasSpecialNoteHead(note)) {
                return true
            }
        }
        return false
    }).some(x => x)
    return result
}

function queryStringArg(key, val, first = false) {
    let result = first ? '' : '&'
    result += encodeURIComponent(key) + '=' + encodeURIComponent(val)
    return result
}

function chordsAsApiInput(chords, reverse) {
    //return [["G'"]] // example
    let convert
    if (reverse) {
        convert = (note, pitch) => {
            return { crossed: hasCrossedNoteHead(note), position: getNoteName(pitch), pitch: pitch }
        }
    } else {
        convert = (note, pitch) => getNoteName(pitch)
    }
    return chords.map((chord) => {
        let result = []
        let notes = chord.notes
        for (let i = 0; i < notes.length; i++) {
            let note = notes[i]
            result.push(convert(note, note.pitch))
        }
        console.log(result)
        return result
    })
}

function getMidiPitch(noteName) {
    let entry = midiPitchMap.find(([x, _]) => x === noteName)
    return entry ? entry[1] : null
}

function getNoteName(pitch) {
    // More matches for one pitch possible, e.g.:
    // In D-Dur hat eine Griffschrift-Note mit Position f ein
    // Auflösungszeichen davor, wenn die Tonart noch nicht
    // "gelöscht" wurde.
    // Beim Zurückübersetzen von Griffschrift nach Normalnoten
    // wird der MIDI Pitch als eis statt f interpretiert.
    // Damit ist der Stammton fälschlicherweise ein e statt f und
    // so liegt der Übersetzung nach Normalnotation eine falsche
    // Griffschrift zugrunde.
    let entry = midiPitchMap.find(([_, x]) => x === pitch)
    return entry ? entry[0] : null
}

function extractZDResults(zd, zdResults) {
    return zdResults[zd === 'druck' ? 1 : 0]
}

function lookupTonalPitchClass(noteName) {
    return tonalPitchClassMap.find(([nn, _]) => noteName == nn)[1]
}

function containsRedNote(notes) {
    // A red note can be
    // a) in normal notation that could not be converted to
    //    Griffschrift because the tone doesn't exist on the selected
    //    instrument (auf Zug oder Druck).
    // b) in Griffschrift that could not be converted to normal
    //    notation because it refers to a button that not exists on
    //    the selected instrument.
    // If a chord contains one red Griffschrift note, the
    // other notes are also Griffschrift.
    // If a chord contains one red normal note, the
    // other notes are also normal notes.
    for (let i = 0; i < notes.length; i++) {
        if (notes[i].color == colorRed) {
            return true
        }
    }
    return false
}

function constructChordsFromNormalResults(results) {
    return results.map((chord) => {
        let notes = []
        let newNoteProto = { // Mock-up instead of real Note element
            pitch: 80,
            add: (_) => {},
            playEvents: { length: 0 },
            elements:   { length: 0 },
            duration: { numerator: 1, denominator: 4 }
        }
        //let newNoteProto = newElement(Element.NOTE) <- // makes MuseScore crash?
        console.log('Created element: ' + newNoteProto)
        const constructNewNote = (noteName) => {
            let newNote = Object.assign({}, newNoteProto)
            newNote.pitch = getMidiPitch(noteName)
            return newNote
            // return { ...newNoteProto, pitch: getMidiPitch(noteName) } // <- not yet supported in MuseScore
        }
        if (chord.Right) {
            notes = chord.Right.map(constructNewNote)
        } else if (chord.Left) {
            console.warn(`Did not receive expected normal notation for current chord: ${jsonStringifyNonRecursive(chord)}`)
            // Not sure what happens after this...
            notes = chord.Left.map(({position}) => constructNewNote(position))
        } else {
            console.warn(`Invalid result for current chord: ${jsonStringifyNonRecursive(chord)}`)
        }
        return { notes: notes }
    })
}
