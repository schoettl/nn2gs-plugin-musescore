
/*

    Nn2GS - Übersetzt zwischen Normalnoten und Griffschrift-Tabulatur für Steirische Harmonika.
    Copyright (C) 2021-2022  Jakob Schöttl <jschoett@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

import QtQuick 2.9
import MuseScore 3.0
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

// Discussion about QtQuick versions:
// https://musescore.org/en/node/281629
// https://doc.qt.io/qt-5/qtquickcontrols-index.html#versions

// Funktionen, die ich vllt noch brauche:
// newElement(type: int)
// removeElement(elem)
// openLog()
// closeLog()
// log(), logn(), log2()

MuseScore {
    id: plugin
    menuPath:   "Plugins.Griffschrift (Nn2GS)"
version: "1.5.1"
    description: "Dieses Plugin übersetzt zwischen Normalnoten und Griffschrift-Tabulatur für Steirische Harmonika."
    requiresScore: true

    pluginType: "dock"
    dockArea:   "left"

    implicitWidth:  200
    implicitHeight: 700

    // Polyfills used by compiled functions:
    property var $jscomp: {}

    onRun: {
        console.log("Starting...")
        btnReverseDirection.text = btnReverseDirection.texts[btnReverseDirection.state]
        btnReverseDirection.background.color = colorButtonNormal

        $jscomp = {} // Polyfill object
        // POLYFILL IMPLEMENTATION HERE:

        // Additional ES5 polyfills:
        // https://tc39.github.io/ecma262/#sec-array.prototype.includes
        if (!Array.prototype.includes) {
            Object.defineProperty(Array.prototype, 'includes', {
                value: function(searchElement, fromIndex) {

                if (this == null) {
                    throw new TypeError('"this" is null or not defined');
                }

                // 1. Let O be ? ToObject(this value).
                var o = Object(this);

                // 2. Let len be ? ToLength(? Get(O, "length")).
                var len = o.length >>> 0;

                // 3. If len is 0, return false.
                if (len === 0) {
                    return false;
                }

                // 4. Let n be ? ToInteger(fromIndex).
                //    (If fromIndex is undefined, this step produces the value 0.)
                var n = fromIndex | 0;

                // 5. If n ≥ 0, then
                //  a. Let k be n.
                // 6. Else n < 0,
                //  a. Let k be len + n.
                //  b. If k < 0, let k be 0.
                var k = Math.max(n >= 0 ? n : len - Math.abs(n), 0);

                function sameValueZero(x, y) {
                    return x === y || (typeof x === 'number' && typeof y === 'number' && isNaN(x) && isNaN(y));
                }

                // 7. Repeat, while k < len
                while (k < len) {
                    // a. Let elementK be the result of ? Get(O, ! ToString(k)).
                    // b. If SameValueZero(searchElement, elementK) is true, return true.
                    if (sameValueZero(o[k], searchElement)) {
                    return true;
                    }
                    // c. Increase k by 1.
                    k++;
                }

                // 8. Return false
                return false;
                }
            });
        }

        // End of polyfills

        populateInstrumentList()
    }
    onScoreStateChanged: {
        if (state.selectionChanged) {
            // Invalidate current translation info and selection
            //console.log("Selection changed")
            invalidateCurrentResults()
            // Selection changes after converting GS → Nn; therefore
            // the disableZDButtonsForTimeout wouldn't have an effect.
            //enableZDButtons(true)
        }
    }

    //readonly property string apiUrl: "https://griffschrift-notation.de/nn2gs"
    readonly property string apiUrl: "https://griffschrift-notation.de/nn2gs"

    readonly property var colorRed: "#ff0000"
    readonly property var colorBlue: "#0000ff"
    readonly property var colorBlack: "#000000"
    readonly property var colorButtonNormal: "#bbb"
    readonly property var colorDirectionReverse: "#666"

    // Generated using Nn2GS.hs:
    // :m +Data.Char Data.Aeson
    // result = map (\(x,y) -> (x, noteNameToGerman.show $ y, computeAccidentals $ Dur y)) quintenZirkel
    // encode result
    // putStrLn ...
    readonly property var tonarten: [[-8,"Fes",["Bes","Ees","Aes","Des","Ges","Ces","Fes"]],[-7,"Ces",["Bes","Ees","Aes","Des","Ges","Ces","Fes"]],[-6,"Ges",["Bes","Ees","Aes","Des","Ges","Ces"]],[-5,"Des",["Bes","Ees","Aes","Des","Ges"]],[-4,"As",["Bes","Ees","Aes","Des"]],[-3,"Es",["Bes","Ees","Aes"]],[-2,"B",["Bes","Ees"]],[-1,"F",["Bes"]],[0,"C",[]],[1,"G",["Fis"]],[2,"D",["Fis","Cis"]],[3,"A",["Fis","Cis","Gis"]],[4,"E",["Fis","Cis","Gis","Dis"]],[5,"H",["Fis","Cis","Gis","Dis","Ais"]],[6,"Fis",["Fis","Cis","Gis","Dis","Ais","Eis"]],[7,"Cis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[8,"Gis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[9,"Dis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[10,"Ais",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[11,"Eis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[12,"His",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]]]


    // Generated using Nn2GS.hs:
    // Exclude some notes; see documentation in getNoteName().
    // :m Data.Aeson
    // encode . filter (not . flip elem [Eis, Bis, Ces, Fes] . withoutOctave . fst) . M.toList $ midiPitchMap
    // putStrLn "..."
    readonly property var midiPitchMap: [["C_",36],["Cis_",37],["Des_",37],["D_",38],["Dis_",39],["Ees_",39],["E_",40],["F_",41],["Fis_",42],["Ges_",42],["G_",43],["Gis_",44],["Aes_",44],["A_",45],["Ais_",46],["Bes_",46],["B_",47],["C",48],["Cis",49],["Des",49],["D",50],["Dis",51],["Ees",51],["E",52],["F",53],["Fis",54],["Ges",54],["G",55],["Gis",56],["Aes",56],["A",57],["Ais",58],["Bes",58],["B",59],["C'",60],["Cis'",61],["Des'",61],["D'",62],["Dis'",63],["Ees'",63],["E'",64],["F'",65],["Fis'",66],["Ges'",66],["G'",67],["Gis'",68],["Aes'",68],["A'",69],["Ais'",70],["Bes'",70],["B'",71],["C''",72],["Cis''",73],["Des''",73],["D''",74],["Dis''",75],["Ees''",75],["E''",76],["F''",77],["Fis''",78],["Ges''",78],["G''",79],["Gis''",80],["Aes''",80],["A''",81],["Ais''",82],["Bes''",82],["B''",83],["C'''",84],["Cis'''",85],["Des'''",85],["D'''",86],["Dis'''",87],["Ees'''",87],["E'''",88],["F'''",89],["Fis'''",90],["Ges'''",90],["G'''",91],["Gis'''",92],["Aes'''",92],["A'''",93],["Ais'''",94],["Bes'''",94],["B'''",95],["C''''",96],["Cis''''",97],["Des''''",97],["D''''",98],["Dis''''",99],["Ees''''",99],["E''''",100],["F''''",101],["Fis''''",102],["Ges''''",102],["G''''",103],["Gis''''",104],["Aes''''",104],["A''''",105],["Ais''''",106],["Bes''''",106],["B''''",107]]

    // Generated using Nn2GS.hs:
    // :m +Data.Char Data.Aeson
    // map (\x -> [show x, map toLower . noteNameToGerman . show $ x]) $ enumFrom C_
    readonly property var germanNoteNames: [["C_","c_"],["Cis_","cis_"],["Des_","des_"],["D_","d_"],["Dis_","dis_"],["Ees_","es_"],["E_","e_"],["Fes_","fes_"],["Eis_","eis_"],["F_","f_"],["Fis_","fis_"],["Ges_","ges_"],["G_","g_"],["Gis_","gis_"],["Aes_","as_"],["A_","a_"],["Ais_","ais_"],["Bes_","b_"],["B_","h_"],["Ces","ces"],["Bis_","his_"],["C","c"],["Cis","cis"],["Des","des"],["D","d"],["Dis","dis"],["Ees","es"],["E","e"],["Fes","fes"],["Eis","eis"],["F","f"],["Fis","fis"],["Ges","ges"],["G","g"],["Gis","gis"],["Aes","as"],["A","a"],["Ais","ais"],["Bes","b"],["B","h"],["Ces'","ces'"],["Bis","his"],["C'","c'"],["Cis'","cis'"],["Des'","des'"],["D'","d'"],["Dis'","dis'"],["Ees'","es'"],["E'","e'"],["Fes'","fes'"],["Eis'","eis'"],["F'","f'"],["Fis'","fis'"],["Ges'","ges'"],["G'","g'"],["Gis'","gis'"],["Aes'","as'"],["A'","a'"],["Ais'","ais'"],["Bes'","b'"],["B'","h'"],["Ces''","ces''"],["Bis'","his'"],["C''","c''"],["Cis''","cis''"],["Des''","des''"],["D''","d''"],["Dis''","dis''"],["Ees''","es''"],["E''","e''"],["Fes''","fes''"],["Eis''","eis''"],["F''","f''"],["Fis''","fis''"],["Ges''","ges''"],["G''","g''"],["Gis''","gis''"],["Aes''","as''"],["A''","a''"],["Ais''","ais''"],["Bes''","b''"],["B''","h''"],["Ces'''","ces'''"],["Bis''","his''"],["C'''","c'''"],["Cis'''","cis'''"],["Des'''","des'''"],["D'''","d'''"],["Dis'''","dis'''"],["Ees'''","es'''"],["E'''","e'''"],["Fes'''","fes'''"],["Eis'''","eis'''"],["F'''","f'''"],["Fis'''","fis'''"],["Ges'''","ges'''"],["G'''","g'''"],["Gis'''","gis'''"],["Aes'''","as'''"],["A'''","a'''"],["Ais'''","ais'''"],["Bes'''","b'''"],["B'''","h'''"],["Ces''''","ces''''"],["Bis'''","his'''"],["C''''","c''''"],["Cis''''","cis''''"],["Des''''","des''''"],["D''''","d''''"],["Dis''''","dis''''"],["Ees''''","es''''"],["E''''","e''''"],["Fes''''","fes''''"],["Eis''''","eis''''"],["F''''","f''''"],["Fis''''","fis''''"],["Ges''''","ges''''"],["G''''","g''''"],["Gis''''","gis''''"],["Aes''''","as''''"],["A''''","a''''"],["Ais''''","ais''''"],["Bes''''","b''''"],["B''''","h''''"],["Ces'''''","ces'''''"],["Bis''''","his''''"]]

    // Generated using Nn2GS.hs:
    // :m Data.Aeson
    // tonalPitches = zip [-1::Int ..4] $ repeat $ flip zip [6::Int ..] $ map snd quintenZirkel
    // encode $ concatMap (\(i, xs) -> map (\(x, p) -> (show $ mkTon' x i, p)) xs) $ map (\(i, xs) -> (i, filter (\(x,_) -> not (i == -1 && x == Ces)) xs)) $ tonalPitches
    // putStrLn ...
    readonly property var tonalPitchClassMap: [["Fes_",6],["Ges_",8],["Des_",9],["Aes_",10],["Ees_",11],["Bes_",12],["F_",13],["C_",14],["G_",15],["D_",16],["A_",17],["E_",18],["B_",19],["Fis_",20],["Cis_",21],["Gis_",22],["Dis_",23],["Ais_",24],["Eis_",25],["Bis_",26],["Fes",6],["Ces",7],["Ges",8],["Des",9],["Aes",10],["Ees",11],["Bes",12],["F",13],["C",14],["G",15],["D",16],["A",17],["E",18],["B",19],["Fis",20],["Cis",21],["Gis",22],["Dis",23],["Ais",24],["Eis",25],["Bis",26],["Fes'",6],["Ces'",7],["Ges'",8],["Des'",9],["Aes'",10],["Ees'",11],["Bes'",12],["F'",13],["C'",14],["G'",15],["D'",16],["A'",17],["E'",18],["B'",19],["Fis'",20],["Cis'",21],["Gis'",22],["Dis'",23],["Ais'",24],["Eis'",25],["Bis'",26],["Fes''",6],["Ces''",7],["Ges''",8],["Des''",9],["Aes''",10],["Ees''",11],["Bes''",12],["F''",13],["C''",14],["G''",15],["D''",16],["A''",17],["E''",18],["B''",19],["Fis''",20],["Cis''",21],["Gis''",22],["Dis''",23],["Ais''",24],["Eis''",25],["Bis''",26],["Fes'''",6],["Ces'''",7],["Ges'''",8],["Des'''",9],["Aes'''",10],["Ees'''",11],["Bes'''",12],["F'''",13],["C'''",14],["G'''",15],["D'''",16],["A'''",17],["E'''",18],["B'''",19],["Fis'''",20],["Cis'''",21],["Gis'''",22],["Dis'''",23],["Ais'''",24],["Eis'''",25],["Bis'''",26],["Fes''''",6],["Ces''''",7],["Ges''''",8],["Des''''",9],["Aes''''",10],["Ees''''",11],["Bes''''",12],["F''''",13],["C''''",14],["G''''",15],["D''''",16],["A''''",17],["E''''",18],["B''''",19],["Fis''''",20],["Cis''''",21],["Gis''''",22],["Dis''''",23],["Ais''''",24],["Eis''''",25],["Bis''''",26]]

    // For each row, the entry contains Bass, Wechselbass_Zug, Wechselbass_Druck.
    // Bass-Mapping könnte später konfigurierbar werden.
    // "W" ist laut dieses Österreichen Lehrerverbands empfohlen, also nicht X and A'?
    readonly property var bassMapping: [["A", "A'", "X"], ["B", "A", "A"], ["C", "B", "B"], ["D", "C", "C"]]

    // Prevent memory/performance problems and API abuse
    readonly property int maxChordLimit: 50

    property var lastResults: null
    property string lastZD: ''
    property int alternativeIndex: 0

    // PURE FUNCTIONS HERE:
function jsonStringifyNonRecursive(a) {
  let b = [];
  return JSON.stringify(a, (c, d) => {
    if ("object" === typeof d && null !== d) {
      if (b.includes(d)) {
        return;
      }
      b.push(d);
    }
    return d;
  });
}
function propertiesOfObject(a) {
  let b = [];
  for (let c in a) {
    b.push(c);
  }
  return b;
}
function fixPlayedNotePitch(a, b) {
  for (let c = 0; c < a.playEvents.length; c++) {
    a.playEvents[c].pitch = b - a.pitch;
  }
}
function resetPlayedNotePitch(a) {
  for (let b = 0; b < a.playEvents.length; b++) {
    a.playEvents[b].pitch = 0;
  }
}
function colorNoteZugDruck(a, b, c) {
  a.color != colorBlue && a.color != colorRed || "zug" === b ? c.checked && "zug" === b && (a.color = colorBlue) : a.color = colorBlack;
}
function setAccidentalVisible(a, b) {
  a.accidental && (a.accidental.visible = b);
}
function addCrossLightBeforeHead(a) {
  addSymbolToNote(a, SymId.noteheadXBlack, -1.3);
}
function addCrossBoldBeforeHead(a) {
  addSymbolToNote(a, SymId.noteheadHeavyX, -1.5);
}
function addCrossSharp2BeforeHead(a) {
  addSymbolToNote(a, SymId.accidentalDoubleSharp, -1.15);
}
function addCrossCircledBeforeHead(a) {
  addSymbolToNote(a, SymId.noteheadCircleX, -1.1);
}
function addSymbolToNote(a, b, c) {
  let d = newElement(Element.SYMBOL);
  d.symbol = b;
  d.offsetX = c;
  a.add(d);
}
function isCrossSymbol(a) {
  return a.type == Element.SYMBOL && (a.symbol == SymId.noteheadXBlack || a.symbol == SymId.noteheadHeavyX || a.symbol == SymId.noteheadXOrnate || a.symbol == SymId.noteheadCircleX || a.symbol == SymId.accidentalDoubleSharp || a.symbol == SymId.accidentalDoubleArabic || a.symbol == SymId.noteheadVoidWithX || a.symbol == SymId.noteheadHalfWithX || a.symbol == SymId.noteheadWholeWithX);
}
function hasCrossSymbol(a) {
  for (let b = 0; b < a.elements.length; b++) {
    if (isCrossSymbol(a.elements[b])) {
      return !0;
    }
  }
}
function removeCrossBeforeHead(a) {
  for (let b = 0; b < a.elements.length; b++) {
    let c = a.elements[b];
    isCrossSymbol(c) && a.remove(c);
  }
}
function removeAllLyrics(a) {
  for (let b = 0; b < a.lyrics.length; b++) {
    a.remove(a.lyrics[b]);
  }
}
function isHalfOrWhole(a) {
  return durationIs(a, 1) || durationIs(a, 2);
}
function isHalfOrLonger(a) {
  return 0.5 <= a.duration.numerator / a.duration.denominator;
}
function durationIs(a, b) {
  return 1 === a.duration.numerator && a.duration.denominator === b;
}
function hasSpecialNoteHead(a) {
  return hasCrossSymbol(a) || a.headGroup != NoteHeadGroup.HEAD_NORMAL;
}
function hasCrossedNoteHead(a) {
  return hasCrossSymbol(a) || a.headGroup == NoteHeadGroup.HEAD_CROSS || a.headGroup == NoteHeadGroup.HEAD_XCIRCLE || a.headGroup == NoteHeadGroup.HEAD_WITHX;
}
function looksLikeGriffschrift(a) {
  return a.map(b => {
    for (let c = 0; c < b.notes.length; c++) {
      if (hasSpecialNoteHead(b.notes[c])) {
        return !0;
      }
    }
    return !1;
  }).some(b => b);
}
function queryStringArg(a, b, c = !1) {
  return (c ? "" : "&") + (encodeURIComponent(a) + "=" + encodeURIComponent(b));
}
function chordsAsApiInput(a, b) {
  let c;
  c = b ? (d, e) => ({crossed:hasCrossedNoteHead(d), position:getNoteName(e), pitch:e}) : (d, e) => getNoteName(e);
  return a.map(d => {
    let e = [];
    d = d.notes;
    for (let f = 0; f < d.length; f++) {
      let g = d[f];
      e.push(c(g, g.pitch));
    }
    console.log(e);
    return e;
  });
}
function getMidiPitch(a) {
  let b = midiPitchMap.find(([c]) => c === a);
  return b ? b[1] : null;
}
function getNoteName(a) {
  let b = midiPitchMap.find(([, c]) => c === a);
  return b ? b[0] : null;
}
function extractZDResults(a, b) {
  return b["druck" === a ? 1 : 0];
}
function lookupTonalPitchClass(a) {
  return tonalPitchClassMap.find(([b]) => a == b)[1];
}
function containsRedNote(a) {
  for (let b = 0; b < a.length; b++) {
    if (a[b].color == colorRed) {
      return !0;
    }
  }
  return !1;
}
function constructChordsFromNormalResults(a) {
  return a.map(b => {
    let c = [], d = {pitch:80, add:f => {
    }, playEvents:{length:0}, elements:{length:0}, duration:{numerator:1, denominator:4}};
    console.log("Created element: " + d);
    const e = f => {
      let g = Object.assign({}, d);
      g.pitch = getMidiPitch(f);
      return g;
    };
    b.Right ? c = b.Right.map(e) : b.Left ? (console.warn(`Did not receive expected normal notation for current chord: ${jsonStringifyNonRecursive(b)}`), c = b.Left.map(({position:f}) => e(f))) : console.warn(`Invalid result for current chord: ${jsonStringifyNonRecursive(b)}`);
    return {notes:c};
  });
}


    // IMPURE FUNCTIONS HERE:
function applyToChordsInSelection(a, b, d) {
  var f = curScore.newCursor();
  f.rewind(1);
  var c = !1;
  if (f.segment) {
    var e = f.staffIdx;
    f.rewind(2);
    var g = 0 === f.tick ? curScore.lastSegment.tick + 1 : f.tick;
    a = f.staffIdx;
  } else {
    if (!a) {
      return;
    }
    c = !0;
    e = 0;
    a = curScore.nstaves - 1;
  }
  console.log(`applyToChordsInSelection: ${e} - ${a} - ${g}`);
  let l = 0;
  for (; e <= a; e++) {
    for (var k = 0; 4 > k; k++) {
      for (f.rewind(1), f.voice = k, f.staffIdx = e, c && f.rewind(0); f.segment && (c || f.tick < g);) {
        if (f.element && f.element.type == Element.CHORD) {
          let h = f.element.graceNotes;
          for (let m = 0; m < h.length; m++) {
            if (d(h[m]), l++, l >= b) {
              return;
            }
          }
          d(f.element);
          l++;
          if (l >= b) {
            return;
          }
        }
        f.next();
      }
    }
  }
}
function populateInstrumentList() {
  let a = new XMLHttpRequest();
  a.onreadystatechange = function() {
    if (a.readyState === XMLHttpRequest.DONE) {
      if (200 === a.status) {
        console.log("Fetched instrument list:\n" + a.responseText);
        const d = JSON.parse(a.responseText), f = comboModel.model;
        f.clear();
        d.map(c => f.append({key:c.iModelId.toLowerCase(), value:c.iDescription, tonarten:JSON.stringify(c.iTonarten)}));
        comboModel.currentIndex = 0;
      } else {
        console.log("Ignoring HTTP error on fetching instrument list."), console.log(a.status);
      }
    }
  };
  const b = apiUrl + "/instruments";
  console.log("GET " + b);
  a.open("GET", b, !0);
  a.send();
}
function callApi(a, b, d) {
  let f = JSON.stringify(chordsAsApiInput(a, b));
  b = "?" + queryStringArg("tonart", tonarten[spinnerTonart.value][1].toLowerCase(), !0) + queryStringArg("model", comboModel.currentKey()) + (b ? queryStringArg("reverse", "yes") : "") + (txtLicenseKey.text ? queryStringArg("license", txtLicenseKey.text) : "");
  console.log(b);
  let c = new XMLHttpRequest();
  c.onreadystatechange = function() {
    if (c.readyState === XMLHttpRequest.DONE) {
      if (console.log("HTTP status: " + c.status), 200 === c.status) {
        console.log("API response:\n" + c.responseText);
        try {
          lastResults = JSON.parse(c.responseText);
        } catch (e) {
          console.error("Invalid JSON response. Could not parse."), errorDialog.show("Ung\u00fcltige Antwort vom Server.");
        }
        d(a, lastResults);
      } else if (500 <= c.status) {
        errorDialog.show(`Fehler beim Server. Funktioniert ${apiUrl}?`);
      } else if (400 <= c.status) {
        errorDialog.show(`Fehler bei der Kommunikation mit dem Server. Funktioniert ${apiUrl}?`);
      } else if (300 <= c.status) {
        errorDialog.show(`Wahrscheinlich passt die Lizenz nicht oder Sie haben noch eine alte Version dieses Plugins. \u00dcberpr\u00fcfen: ${apiUrl}?license=${txtLicenseKey.text}.`);
      } else {
        let e = `Request failed with HTTP status ${c.status}\nReceived response headers:\n${c.getAllResponseHeaders()}\nResponse text:\n${c.responseText}`;
        errorDialog.show(`Unbekannter Netzwerkfehler (HTTP Status Code ${c.status}). Funktioniert das Internet? Funktioniert ${apiUrl}?\n\n${e}`);
        console.error(e);
      }
    } else {
      console.log(`HTTP request ready status: ${c.readyState} (not DONE)`);
    }
  };
  console.log(`Run in shell for testing:
cat <<TEXT > test.json
${f}
TEXT
curl -H "Content-Type: application/json" --data-binary @test.json "${apiUrl + b}"
`);
  c.open("POST", apiUrl + b, !0);
  c.setRequestHeader("Content-Type", "application/json");
  c.send(f);
}
function collectChords() {
  const a = getSelectedVoices();
  let b = [];
  applyToChordsInSelection(!1, maxChordLimit + 1, function(d) {
    containsRedNote(d) ? console.log("Collecting chords: Current chord contains a red note. Skipping to next chord.") : a.includes(d.voice) && b.push(d);
  });
  return b;
}
function changeNotes(a, b) {
  return function(d, f) {
    lastZD = a;
    f = extractZDResults(a, f);
    console.log(a + " " + f);
    if (d.length !== f.length) {
      console.warn(`Length of selected chords (${d.length}) and translation result (${f.length}) do not match. Aborting.`);
    } else {
      var c = b ? changeNotesOfChordReverse : changeNotesOfChord, e = 0;
      curScore.startCmd();
      for (let g = 0; g < d.length; g++) {
        e += c(d[g], f[g], a, g);
      }
      curScore.endCmd();
      e && errorDialog.show(`${e} Note(n) konnten nicht \u00fcbersetzt werden und wurden rot markiert.\n\nEntweder existieren sie nicht auf dem Instrument oder sie waren bereits rot markiert. Die Akkorde mit roten Noten wurden bei der \u00dcbersetzung \u00fcbersprungen.`);
    }
  };
}
function changeNotesOfChordReverse(a, b, d, f) {
  a = a.notes;
  d = 0;
  if (containsRedNote(a)) {
    return console.log(`Current chord ${f} contains a red note. Leaving it unchanged. Skipping to next chord.`), d++, d;
  }
  if (b.Right) {
    b = b.Right;
    for (let e = 0; e < a.length; e++) {
      var c = b[e];
      let g = a[e];
      if (a.length !== b.length) {
        console.warn(`Length of current chord (${a.length}) and translation result (${b.length}) do not match in chord ${f}, note ${e}. Skipping to next chord.`);
        break;
      }
      let l = getMidiPitch(c);
      null === l ? console.warn(`Invalid note position ${c} in translation result in chord ${f}, note ${e}. Skipping to next note.`) : (c = lookupTonalPitchClass(c), g.headGroup = NoteHeadGroup.HEAD_NORMAL, removeCrossBeforeHead(g), g.mirrorHead = 0, console.log(`Changing GS ${g.pitch} (tpc=${g.tpc}) to Nn ${l} (tpc=${c})`), g.pitch = l, g.tpc1 = c, g.tpc2 = c, g.visible = !0, g.headType = NoteHeadType.HEAD_AUTO, setAccidentalVisible(g, !0), resetPlayedNotePitch(g));
    }
  } else if (b.Left) {
    for (f = b.Left.map(({position:e, crossed:g}) => [getMidiPitch(e), g]), b = 0; b < a.length; b++) {
      let e = a[b];
      e.visible = !0;
      f.some(([g, l]) => g == e.pitch && l == hasCrossedNoteHead(e)) && (e.color = colorRed, d++);
    }
  } else {
    throw Error(`Invalid result for current chord ${f}: ${JSON.stringify(b)}`);
  }
  return d;
}
function changeNotesOfChord(a, b, d, f) {
  let c = a.notes, e = 0;
  if (containsRedNote(c)) {
    return console.log(`Current chord ${f} contains a red note. Leaving it unchanged. Skipping to next chord.`), e++, e;
  }
  if (b.Right) {
    for (let l = 0; l < c.length; l++) {
      var g = b.Right[alternativeIndex % b.Right.length];
      let k = g[l], h = c[l];
      if (c.length !== g.length) {
        console.warn(`Length of current chord (${c.length}) and translation result (${g.length}) do not match in chord ${f}, note ${l}. Skipping to next chord.`);
        break;
      }
      g = k.pitch;
      if (null === g) {
        console.warn(`Invalid note position ${k.position} in translation result in chord ${f}, note ${l}. Skipping to next note.`);
        continue;
      }
      let m = lookupTonalPitchClass(k.position);
      colorNoteZugDruck(h, d, checkBoxColorZug);
      console.log(`Changing Nn ${h.pitch} (tpc=${h.tpc}) to GS ${g} (tpc=${m})`);
      h.pitch = g;
      h.tpc1 = m;
      h.tpc2 = m;
      null !== k.side && checkBoxSortHeads.checked ? "Links" === k.side ? h.mirrorHead = 1 : "Rechts" === k.side && (h.mirrorHead = 2) : h.mirrorHead = 0;
      h.headGroup = NoteHeadGroup.HEAD_NORMAL;
      removeCrossBeforeHead(h);
      setAccidentalVisible(h, !1);
      if (k.extra && 0 === k.row) {
        h.headGroup = NoteHeadGroup.HEAD_TRIANGLE_UP;
      } else if (k.extra && 1 === k.row) {
        h.headGroup = NoteHeadGroup.HEAD_DIAMOND;
      } else if (k.crossed) {
        switch(g = comboTabulatureDisplay.currentKey(), console.log(g), g) {
          case "klassisch_kreuz":
            addCrossLightBeforeHead(h);
            break;
          case "klassisch_doppelkreuz":
            addCrossSharp2BeforeHead(h);
            break;
          case "johannesservi.de":
            isHalfOrLonger(a) ? (h.headGroup = NoteHeadGroup.HEAD_WITHX, h.headType = NoteHeadType.HEAD_QUARTER) : h.headGroup = NoteHeadGroup.HEAD_CROSS;
            break;
          case "johannesservi.de_2":
            isHalfOrLonger(a) ? h.headGroup = NoteHeadGroup.HEAD_XCIRCLE : h.headGroup = NoteHeadGroup.HEAD_CROSS;
            break;
          case "matthiaspuerner.de":
            isHalfOrLonger(a) ? addCrossSharp2BeforeHead(h) : h.headGroup = NoteHeadGroup.HEAD_CROSS;
            break;
          case "knoepferl.at":
            2 === k.row ? addCrossLightBeforeHead(h) : addCrossSharp2BeforeHead(h);
            break;
          case "michlbauer.com":
            2 === k.row ? addCrossLightBeforeHead(h) : addCrossCircledBeforeHead(h);
            break;
          case "dickes_kreuz":
            2 === k.row ? addCrossLightBeforeHead(h) : addCrossBoldBeforeHead(h);
            break;
          case "klassisch_kreuz2":
            isHalfOrLonger(a) ? addCrossLightBeforeHead(h) : h.headGroup = NoteHeadGroup.HEAD_CROSS;
            break;
          case "klassisch_doppelkreuz2":
            isHalfOrLonger(a) ? addCrossSharp2BeforeHead(h) : (h.visible = !1, addSymbolToNote(h, SymId.accidentalDoubleSharp, 0.1));
            break;
          default:
            h.headGroup = NoteHeadGroup.HEAD_CROSS;
        }
      }
      fixPlayedNotePitch(h, k.origPitch);
    }
  } else if (b.Left) {
    for (a = b.Left.map(getMidiPitch), b = 0; b < c.length; b++) {
      d = c[b], a.includes(d.pitch) && (d.color = colorRed, e++);
    }
  } else {
    throw Error(`Invalid result for current chord ${f}: ${JSON.stringify(b)}`);
  }
  return e;
}
function addLyricsToChord(a, b, d, f) {
  let c = a.notes, e = 0;
  console.log(`result for chord: ${b}`);
  removeAllLyrics(a);
  for (let k = 0; k < c.length; k++) {
    var g = b[k];
    g = g[alternativeIndex % g.length];
    var l = c[k];
    if (c.length !== b.length) {
      console.warn(`Length of current chord (${c.length}) and translation result (${b.length}) do not match in chord ${f}, note ${k}. Skipping to next chord.`);
      break;
    }
    colorNoteZugDruck(l, d, checkBoxColorZug);
    g ? (l = newElement(Element.LYRICS), l.text = g, l.verse = k, a.add(l)) : (l.color = colorRed, e++);
  }
  return e;
}
function callBassApi(a, b) {
  let d = JSON.stringify(chordsAsApiInput(a, !1));
  const f = apiUrl + "/bass";
  let c = "?" + queryStringArg("tonart", tonarten[spinnerTonart.value][1].toLowerCase(), !0) + queryStringArg("stimmung", comboStimmung.currentKey()) + queryStringArg("basssystem", comboBasssystem.currentKey()) + queryStringArg("bassbenennung", comboBassbenennung.currentKey());
  console.log(c);
  let e = new XMLHttpRequest();
  e.onreadystatechange = function() {
    if (e.readyState === XMLHttpRequest.DONE) {
      if (console.log("HTTP status: " + e.status), 200 === e.status) {
        console.log("API response:\n" + e.responseText);
        try {
          lastResults = JSON.parse(e.responseText);
        } catch (g) {
          console.error("Invalid JSON response. Could not parse."), errorDialog.show("Ung\u00fcltige Antwort vom Server.");
        }
        b(a, lastResults);
      } else if (500 <= e.status) {
        errorDialog.show(`Fehler beim Server. Funktioniert ${apiUrl}?`);
      } else if (400 <= e.status) {
        errorDialog.show(`Fehler bei der Kommunikation mit dem Server. Funktioniert ${apiUrl}?`);
      } else if (300 <= e.status) {
        errorDialog.show(`Wahrscheinlich passt die Lizenz nicht oder Sie haben noch eine alte Version dieses Plugins. \u00dcberpr\u00fcfen: ${apiUrl}?license=${txtLicenseKey.text}.`);
      } else {
        let g = `Request failed with HTTP status ${e.status}\nReceived response headers:\n${e.getAllResponseHeaders()}\nResponse text:\n${e.responseText}`;
        errorDialog.show(`Unbekannter Netzwerkfehler (HTTP Status Code ${e.status}). Funktioniert das Internet? Funktioniert ${apiUrl}?\n\n${g}`);
        console.error(g);
      }
    } else {
      console.log(`HTTP request ready status: ${e.readyState} (not DONE)`);
    }
  };
  console.log(`Run in shell for testing:
cat <<TEXT > test.json
${d}
TEXT
curl -H "Content-Type: application/json" --data-binary @test.json "${f + c}"
`);
  e.open("POST", f + c, !0);
  e.setRequestHeader("Content-Type", "application/json");
  e.send(d);
}
function addLyricsToNotes(a) {
  return function(b, d) {
    lastZD = a;
    d = extractZDResults(a, d);
    console.log(a + " " + d);
    if (b.length !== d.length) {
      console.warn(`Length of selected chords (${b.length}) and translation result (${d.length}) do not match. Aborting.`);
    } else {
      var f = 0;
      curScore.startCmd();
      for (let c = 0; c < b.length; c++) {
        f += addLyricsToChord(b[c], d[c], a, c);
      }
      curScore.endCmd();
      f && errorDialog.show(`${f} Note(n) konnten nicht \u00fcbersetzt werden und wurden rot markiert.\n\nEntweder existieren sie nicht auf dem Instrument oder sie waren bereits rot markiert. Die Akkorde mit roten Noten wurden bei der \u00dcbersetzung \u00fcbersprungen.`);
    }
  };
}
function addBassNamesAsLyrics(a) {
  checkVoiceCheckboxesValidity();
  console.log(`Starting translation: ${a}`);
  let b = collectChords();
  0 === b.length ? (console.warn("Keine Noten ausgew\u00e4hlt. Abbruch."), warningDialog.show("Es sind keine Noten bzw. Takte ausgew\u00e4hlt.")) : b.length > maxChordLimit ? (console.warn("Zu viele Noten ausgew\u00e4hlt. Abbruch."), warningDialog.show("Es sind zu viele Noten bzw. Takte ausgew\u00e4hlt. Es k\u00f6nnen immer nur ein paar Takte auf einmal \u00fcbersetzt werden.")) : (isCurrentResultValid() ? (alternativeIndex = a !== lastZD ? 0 : alternativeIndex + 1, addLyricsToNotes(a)(b, lastResults)) : 
  (alternativeIndex = 0, callBassApi(b, addLyricsToNotes(a)), btnNextAlternative.enabled = !0), invalidateResultsAfterTimeout());
}
function translateToFromGriffschrift(a) {
  checkVoiceCheckboxesValidity();
  let b = isReverseDirection();
  console.log(`Starting translation: ${a}${b ? " reverse" : ""}`);
  let d = collectChords();
  if (0 === d.length) {
    console.warn("Keine Noten ausgew\u00e4hlt. Abbruch."), warningDialog.show("Es sind keine Noten bzw. Takte ausgew\u00e4hlt.");
  } else {
    if (d.length > maxChordLimit) {
      console.warn("Zu viele Noten ausgew\u00e4hlt. Abbruch."), warningDialog.show("Es sind zu viele Noten bzw. Takte ausgew\u00e4hlt. Es k\u00f6nnen immer nur ein paar Takte auf einmal \u00fcbersetzt werden.");
    } else {
      if (1 !== btnReverseDirection.state || isCurrentResultValid()) {
        if (b || !isCurrentResultValid()) {
          if (looksLikeGriffschrift(d) && !b) {
            console.warn("Markierte Noten sehen nach Griffschrift aus. Abbruch.");
            warningDialog.show("Markierte Noten sehen nach Griffschrift aus und k\u00f6nnen so nicht nach Griffschrift \u00fcbersetzt werden.");
            return;
          }
          alternativeIndex = 0;
          callApi(d, b, changeNotes(a, b));
          btnNextAlternative.enabled = !0;
        } else {
          alternativeIndex = a !== lastZD ? 0 : alternativeIndex + 1, changeNotes(a, !1)(d, lastResults);
        }
        invalidateResultsAfterTimeout();
        b && disableZDButtonsForTimeout();
      } else {
        console.log("Alternative Griffweisen durchzappen"), callApi(d, !0, toGriffschrift(a));
      }
    }
  }
}
function makePlayable() {
  invalidateCurrentResults();
  let a = collectChords();
  0 === a.length ? console.warn("Keine Noten ausgew\u00e4hlt. Abbruch.") : a.length > maxChordLimit && console.warn("Zu viele Noten ausgew\u00e4hlt. Abbruch.");
}
function toGriffschrift(a) {
  return (b, d) => {
    b = extractZDResults(a, d);
    b = constructChordsFromNormalResults(b);
    console.log("Aus Normalnoten (die API zur\u00fcckgeliefert hat) werden jetzt MuseScore Notes erstellt, die dann in GS umgewandelt werden: " + JSON.stringify(b));
    alternativeIndex = 0;
    callApi(b, !1, changeNotes(a, !1));
  };
}
function checkVoiceCheckboxesValidity() {
  checkBoxVoice1.checked || checkBoxVoice2.checked || checkBoxVoice3.checked || checkBoxVoice4.checked || warningDialog.show("Mindestens eine Stimme muss zum \u00dcbersetzen ausgew\u00e4hlt sein.");
}
function getSelectedVoices() {
  let a = [];
  checkBoxVoice1.checked && a.push(0);
  checkBoxVoice2.checked && a.push(1);
  checkBoxVoice3.checked && a.push(2);
  checkBoxVoice4.checked && a.push(3);
  return a;
}
function find(a, b, d) {
  return (a = a.filter(b).map(d)) ? a[0] : null;
}
function getGermanNoteNamesFromNotes(a) {
  let b = [];
  for (let d = 0; d < a.length; d++) {
    const f = a[d], c = find(midiPitchMap, ([, g]) => f.pitch == g, ([g]) => g), e = find(germanNoteNames, ([g]) => g === c, ([, g]) => g);
    e && b.push(e);
  }
  return b;
}
function lblShowInstrumentClick() {
  const a = comboModel.currentKey();
  var b = collectChords();
  b = getGermanNoteNamesFromNotes(0 < b.length ? b[0].notes : []);
  const d = b.join(" ");
  console.log(d);
  Qt.openUrlExternally(apiUrl + "?" + queryStringArg("model", a, !0) + (b.length ? queryStringArg("notes", d, !1) : "") + (txtLicenseKey.text ? queryStringArg("license", txtLicenseKey.text) : ""));
}
function lblCurrentKeyClick() {
  let a = curScore.keysig;
  console.log(`Globale Dur-Tonart: ${a}`);
  spinnerTonart.value = 8 + a;
}
function proceedToNextChord() {
  cmd("next-chord");
  cmd("select-next-chord");
  cmd("select-prev-chord");
}
function checkBoxColorZugClick() {
  checkBoxColorZug.checked || (curScore.startCmd(), applyToChordsInSelection(!0, 10000, a => {
    for (let b = 0; b < a.notes.length; b++) {
      let d = a.notes[b];
      d.color == colorBlue && (d.color = colorBlack);
    }
  }), curScore.endCmd());
}


    Shortcut {
        sequence: "Alt+R"
        context: Qt.ApplicationShortcut
        onActivated: clickReverseDirection()
    }
    // Alt+D für Druck ist schon vergeben von Menü, deswegen J/K für Z/D als Alternative
    Shortcut {
        sequence: "Alt+J"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (btnZug.enabled)
                clickZug()
        }
    }
    Shortcut {
        sequence: "Alt+K"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (btnDruck.enabled)
                clickDruck()
        }
    }
    Shortcut {
        sequence: "Alt+N"
        context: Qt.ApplicationShortcut
        onActivated: proceedToNextChord()
    }

    MessageDialog {
        id: errorDialog
        title: "Fehler"
        icon: StandardIcon.Critical
        function show(msg) {
            text = msg
            open()
        }
    }

    MessageDialog {
        id: warningDialog
        title: "Warnung"
        icon: StandardIcon.Warning
        function show(msg) {
            text = msg
            open()
        }
    }

    MessageDialog {
        id: infoDialog
        title: "Info"
        icon: StandardIcon.Information
        text: "Nn2GS - Übersetzen zwischen Normalnoten und Griffschrift für Steirische Harmonika und ähnliche Instrumente.\n\n      https://griffschrift-notation.de/\n\nMomentan kostenlos, irgendwann wird man für die Nutzung eine günstige Lizenz kaufen müssen.\n\nTastenkürzel: Alt+R (Übersetzungsrichtung), Alt+J (Zug), Alt+K (Druck); auch auf Beschriftungen im Plugin kann geklickt werden (versteckte Funktionen)."
    }

    Timer {
      id: invalidateResultsTimer
      interval: 100000
      running: false
      repeat: false
      //singleShot: true
      onTriggered: invalidateCurrentResults()
    }

    Timer {
      id: disableZDButtonsTimer
      interval: 2000
      running: false
      repeat: false
      //singleShot: true
      onTriggered: enableZDButtons(true)
    }

    function enableZDButtons(yes) {
        console.log("zd buttons enabled: " + yes)
        btnZug.enabled = yes
        btnDruck.enabled = yes
    }

    function invalidateCurrentResults() {
        btnNextAlternative.enabled = false
        lastResults = null
    }

    function isCurrentResultValid() {
        return !!lastResults
    }

    function disableZDButtonsForTimeout() {
        enableZDButtons(false)
        disableZDButtonsTimer.restart()
    }

    function invalidateResultsAfterTimeout() {
        invalidateResultsTimer.restart()
    }

    function switchDiskantBass() {
        invalidateCurrentResults()
        // Set visibility of controls:
        var bassMode = comboSide.isBassMode()
        var diskantMode = comboSide.isDiskantMode()
        spinnerTonart.enabled = !bassMode
        panelBass.visible = bassMode
        txtInstrument.visible = diskantMode
        comboModel.visible = diskantMode
        btnReverseDirection.visible = diskantMode
        txtGSVariante.visible = diskantMode
        comboTabulatureDisplay.visible = diskantMode
        checkBoxSortHeads.visible = diskantMode
    }

    function clickTest() {
        addBassNamesAsLyrics('zug')
    }
    function clickZug() {
        if (comboSide.isBassMode())
            addBassNamesAsLyrics('zug')
        else
            translateToFromGriffschrift('zug')
    }
    function clickDruck() {
        if (comboSide.isBassMode())
            addBassNamesAsLyrics('druck')
        else
            translateToFromGriffschrift('druck')
    }
    function isReverseDirection() {
        //return comboDirection.currentIndex !== 0
        return btnReverseDirection.state === 2
    }
    function clickNextAlternative() {
        // Only for Normalnotation → GS
        if (!isCurrentResultValid() || isReverseDirection()) {
            error.warn("btnNextAlternative should be disabled. Aborting.")
            return
        }
        var chords = collectChords()
        alternativeIndex += 1
        changeNotes(lastZD, false)(chords, lastResults)
    }

    function clickReverseDirection() {
        invalidateCurrentResults()
        var state = btnReverseDirection.state
        state = (state + 1) % 3
        btnReverseDirection.state = state
        btnReverseDirection.text = btnReverseDirection.texts[state]
        btnReverseDirection.background.color = (state === 2) ? colorDirectionReverse : colorButtonNormal
    }

    Pane {
        anchors.fill: parent
        padding: 2
        ColumnLayout {
            anchors.fill: parent
            Layout.fillWidth: true

            ComboBox {
                id: comboSide
                Layout.fillWidth: true
                onCurrentIndexChanged: switchDiskantBass()
                model: ListModel {
                    ListElement { value: "Diskant-/Melodieseite"; }
                    ListElement { value: "Bassseite"; }
                }
                function isBassMode() {
                    return currentIndex == 1
                }
                function isDiskantMode() {
                    return !isBassMode()
                }
            }

            Pane {
                Layout.fillWidth: true
                padding: 0
                id: panelBass
                ColumnLayout {
                    anchors.fill: parent
                    Layout.fillWidth: true
                    Text {
                        text: "Stimmung der Harmonika"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        id: comboStimmung
                        Layout.fillWidth: true
                        textRole: "value"
                        model: ListModel {
                            // Generated using Nn2GS:
                            // :m +Music.Nn2GS
                            // putStrLn $ unlines $ map (\x -> "ListElement { key: \"" ++ showStimmung x ++ "\"; value: \"" ++ showStimmung x ++ "\"; }") stimmungen
                            ListElement { key: "G-C-F-B"; value: "G-C-F-B"; }
                            ListElement { key: "A-D-G-C"; value: "A-D-G-C"; }
                            ListElement { key: "C-F-B-Es"; value: "C-F-B-Es"; }
                            ListElement { key: "B-Es-As-Des"; value: "B-Es-As-Des"; }
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Stimmung = Tonarten der Harmonika"
                        function currentKey() {
                            return model.get(currentIndex).key
                        }
                        onCurrentIndexChanged: {
                            invalidateCurrentResults()
                        }
                    }
                    Text {
                        text: "Basssystem"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        // TODO bei klick das hier verlinken?
                        // Qt.openUrlExternally('http://ziach.de/Tastenbelegung/index.htm')
                    }
                    ComboBox {
                        id: comboBasssystem
                        Layout.fillWidth: true
                        textRole: "value"
                        model: ListModel {
                            // Generated using Nn2GS:
                            // :m +Music.Nn2GS Music.Nn2GS.Bass
                            // putStrLn $ unlines $ map (\x -> "ListElement { key: \"" ++ modelId x ++ "\"; value: \"" ++ description x ++ "\"; }") basssysteme
                            ListElement { key: "GCFB_15-8-7-Ronegg"; value: "15 Tasten (Ronegg, Steiermark)"; }
                            ListElement { key: "ADGC_16-8-8-BayernSalzburg"; value: "16 Tasten (Bayern-Salzburg)"; }
                            ListElement { key: "ADGC_16-8-8-Schaborak"; value: "16 Tasten (Schaborak/Dufter)"; }
                            ListElement { key: "ADGC_16-8-8-Boehmisch"; value: "16 Tasten (überliefert böhmisch)"; }
                            ListElement { key: "ADGC_16-8-8-BoehmischAuer"; value: "16 Tasten (Hans Auer, böhmisch)"; }
                            ListElement { key: "GCFB_16-9-7-Michlbauer"; value: "16 Tasten (Michlbauer)"; }
                            ListElement { key: "ADGC_18-9-9-Gmachl"; value: "18 Tasten (Gmachl, Salzburg)"; }
                            ListElement { key: "ADGC_18-9-9-Schaborak"; value: "18 Tasten (Schaborak)"; }
                            ListElement { key: "ADGC_21-10-11-Schaborak"; value: "21 Tasten (Schaborak)"; }
                            ListElement { key: "ADGC_22-11-11-Schaborak"; value: "22 Tasten (Schaborak, 21 + 1)"; }
                        }
                        function currentKey() {
                            return model.get(currentIndex).key
                        }
                        onCurrentIndexChanged: {
                            invalidateCurrentResults()
                        }
                    }
                    Text {
                        text: "Benennungsschema für Basstasten"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        id: comboBassbenennung
                        Layout.fillWidth: true
                        textRole: "value"
                        model: ListModel {
                            // Generated using Nn2GS:
                            // :m +Music.Nn2GS.Bass
                            // putStrLn $ unlines $ map (\x -> "ListElement { key: \"" ++ bbId x ++ "\"; value: \"" ++ bbDescription x ++ "\"; }") bassbenennungsschemas
                            ListElement { key: "15-8-7-A'"; value: "15 Bässe, A, A', …"; }
                            ListElement { key: "15-8-7-A-H"; value: "15 Bässe, A-H"; }
                            ListElement { key: "16-8-8-A-H"; value: "16 Bässe, A-H"; }
                            ListElement { key: "16-9-7-A-H+X"; value: "16 Bässe, A-H + X"; }
                            ListElement { key: "18-9-9"; value: "18 Bässe, A, A', …, X, Y"; }
                            ListElement { key: "22-10-11-A'XYZ'"; value: "22 Bässe, A, A', …, X, Y"; }
                            ListElement { key: "22-11-11-A'XYZ"; value: "22 Bässe, A, A', …, X, Y, Z"; }
                        }
                        function currentKey() {
                            return model.get(currentIndex).key
                        }
                        onCurrentIndexChanged: {
                            invalidateCurrentResults()
                        }
                    }
                }
            }

            Text {
                text: "Instrument (anzeigen)"
                id: txtInstrument
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: lblShowInstrumentClick()
                }
                ToolTip.visible: hovered // TODO ToolTip funktioniert für Text labels leider nicht
                ToolTip.text: "Klicken, um Instrument auf Webseite anzuzeigen"
            }
            ComboBox {
                id: comboModel
                Layout.fillWidth: true
                textRole: "value"
                model: ListModel {
                    // Generated using Nn2GS.hs:
                    // :{
                    // f (Steirische {steirModelId=x, steirTonarten=ts}) = (x, Just ts)
                    // f instrument = (modelId instrument, Nothing)
                    // :}
                    // putStrLn $ unlines $ map (\(x, ts) -> "ListElement { key: \"" ++ map toLower x ++ "\"; value: \"" ++ x ++ "\"; tonarten: " ++ maybe "\"null\"" (show . show . map show) ts ++ "; }") $ map f listOfInstruments
                    // Cannot define array as property value; use JSON.parse() to decode property 'tonarten'.
                    ListElement { key: "adgc50"; value: "ADGC50"; tonarten: "[\"A\",\"D\",\"G\",\"C\"]"; }
                    ListElement { key: "besasdes50"; value: "BEsAsDes50"; tonarten: "[\"Bes\",\"Ees\",\"Aes\",\"Des\"]"; }
                    ListElement { key: "besasdes46"; value: "BEsAsDes46"; tonarten: "[\"Bes\",\"Ees\",\"Aes\",\"Des\"]"; }
                    ListElement { key: "gcfb50"; value: "GCFB50"; tonarten: "[\"G\",\"C\",\"F\",\"B\"]"; }
                    ListElement { key: "schwyzer-orgel_b"; value: "Schwyzer-Orgel_B"; tonarten: "[\"B\",\"Ees\"]"; }
                    ListElement { key: "club_cf"; value: "Club_CF"; tonarten: "[\"C\",\"F\"]"; }
                    ListElement { key: "knopfakkordeon_b"; value: "Knopfakkordeon_B"; tonarten: "null"; }
                }
                function currentKey() {
                    return model.get(currentIndex).key
                }
                onCurrentIndexChanged: {
                    invalidateCurrentResults()
                }
            }
            Text {
                text: "Aktuelle Dur-Tonart"
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: lblCurrentKeyClick()
                }
                ToolTip.visible: hovered // TODO ToolTip funktioniert für Text labels leider nicht
                ToolTip.text: "Klicken, um Haupttonart automatisch zu erkennen"
            }

            SpinBox {
                width: parent.width
                Layout.fillWidth: true
                id: spinnerTonart
                value: 8
                from: 0
                to: 20
                editable: true
                //validator: QRegExpValidator(/.*/) // tonarten.join('|') + ^$ anchors?
                validator: null
                textFromValue: function(value, locale) {
                    return tonarten[value][1]
                }
                valueFromText: function(text, locale) {
                    var i = tonarten.indexOf(text)
                    if (i >= 0) return i
                    return 0
                }
                onValueChanged: {
                    invalidateCurrentResults()
                }
                ToolTip.visible: hovered
                ToolTip.text: "Tonart des Teils, der übersetzt werden soll"
            }

            ComboBox {
                id: comboDirection
                Layout.fillWidth: true
                visible: false // in favor of btnReverseDirection
                textRole: "value"
                model: ListModel {
                    ListElement { value: "Normal → GS" }
                    ListElement { value: "GS-Alternativen" }
                    ListElement { value: "GS → Normal" }
                }
                onCurrentIndexChanged: {
                    invalidateCurrentResults()
                }
            }
            Button {
                id: btnReverseDirection
                Layout.fillWidth: true
                readonly property var texts: ["Normal → GS", "GS-Alternativen", "GS → Normal"]
                //background.color: colorButtonNormal
                text: "Reverse"
                property int state: 0
                checkable: false // checked state doesn't work reliably with double clicks
                checked: false
                // Handle both events because on double click, click AND
                // double click are fired which causes a faster switching:
                onClicked: clickReverseDirection()
                //onDoubleClicked: clickReverseDirection() <- does not work on Windows
                ToolTip.visible: hovered
                ToolTip.text: "Übersetzungsrichtung (Alt+R)"
            }

            Button {
                text: "Test"
                id: btnTest
                visible: false
                Layout.fillWidth: true
                onClicked: clickTest()
            }
            Button {
                text: "Zug"
                id: btnZug
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                onClicked: clickZug()
                ToolTip.visible: hovered
                ToolTip.text: "Ausgewählte Takte auf Zug (Alt+J)"
            }
            Button {
                text: "Druck"
                id: btnDruck
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                onClicked: clickDruck()
                ToolTip.visible: hovered
                ToolTip.text: "Ausgewählte Takte auf Druck (Alt+K)"
            }
            Button {
                text: "Nächste Alternative"
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                visible: false
                enabled: false
                id: btnNextAlternative
                onClicked: clickNextAlternative()
                ToolTip.visible: hovered
                ToolTip.text: "Alternative Griffweisen durchschalten"
            }
            Button {
                text: "Nächster Akkord"
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                onClicked: proceedToNextChord()
                ToolTip.visible: hovered
                ToolTip.text: "Nächsten Akkord markieren (Alt+N)"
            }

            //GroupBox {
            //    title: "Einstellungen"
            //    ColumnLayout {

            Text {
                text: "Griffschrift-Variante"
                id: txtGSVariante
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            ComboBox {
                id: comboTabulatureDisplay
                Layout.fillWidth: true
                textRole: "text"
                enabled: true
                currentIndex: 0
                model: ListModel {
                    ListElement { text: "Modern (~ Schaborak)"; key: "modern" }  // Modern
                    ListElement { text: "Klassisch (× vor Note)"; key: "klassisch_kreuz" }          // klassisch, Kreuz vor Noten
                    ListElement { text: "Klassisch (× nur vor langer Note)"; key: "klassisch_kreuz2" } // wie klassisch_kreuz, aber Notenkopf in Kreuzform (außer bei Halben/Ganzen)
                    ListElement { text: "Rosenzopf (𝄪 vor Note)"; key: "klassisch_doppelkreuz" } // Klassisch, Doppelkreuz vor Noten
                    ListElement { text: "Rosenzopf (𝄪 nur vor langer Note)"; key: "klassisch_doppelkreuz2" } // wie klassisch_doppelkreuz, aber Notenkopf in Doppelkreuzform (außer bei Halben/Ganzen)
                    ListElement { text: "Michlbauer"; key: "michlbauer.com" } // Kreuz vor Noten, 3. R. einfaches Kreuz, 4. R. kleine umringeltes Kreuz => Bravura
                    ListElement { text: "Knöpferl"; key: "knoepferl.at" } // Kreuz vor Noten, 3. R. einfaches Kreuz, 4. R. Doppelkreuz - Quelle: https://knoepferl.at/produkt/orf-wetterpanorama/
                    ListElement { text: "Klassisch (4. Reihe dickes ×)"; key: "dickes_kreuz" } // wie klassisch_kreuz, aber das dicke Kreuz für 4. Reihe
                    ListElement { text: "Matthias Pürner (×/𝄪 gemischt)"; key: "matthiaspuerner.de" }  // Matthias Pürner, Doppelkreuz vor Halben/Ganzen, normales Kreuz als Notenkopf sonst - Quelle: https://matthiaspuerner.de/wp-content/uploads/2020/11/01_19er-Marscherl-Griffschrift-2S-Partitur.pdf
                    ListElement { text: "Johannes Servi"; key: "johannesservi.de" }   // Johannes Servi (kleines Kreuz in kleinem Kreis bei langen Noten)
                    ListElement { text: "Johannes Servi mod."; key: "johannesservi.de_2" }   // Johannes Servi (Kreuz in rundem, größerem Kreis bei langen Noten)
                }
                function currentKey() {
                    return model.get(currentIndex).key
                }
                ToolTip.visible: hovered
                ToolTip.text: "Aussehen der Griffschrift (Notenköpfe, Kreuzsymbole usw.)"
            }
            TextField {
                text: ""
                id: txtLicenseKey
                Layout.fillWidth: true
                visible: false
                placeholderText: "Lizenz-Schlüssel eingeben…"
                Keys.onPressed: {
                    if (text.trim() === '' && event.key === Qt.Key_Return) {
                        console.log("Opening URL in browser.")
                        Qt.openUrlExternally(apiUrl + '#faq-kosten')
                        text = ''
                    }
                }
                // Use local storage to save the key for the next session
                // https://doc.qt.io/qt-5/qtquick-localstorage-qmlmodule.html
            }

            CheckBox {
                id: checkBoxSortHeads
                checked: true
                text: "Um Notenhals sortieren"
                ToolTip.visible: hovered
                ToolTip.text: "Notenköpfe platzieren je nach Lage auf Tastatur"
            }

            CheckBox {
                id: checkBoxColorZug
                checked: true
                text: "Zug-GS blau färben"
                onClicked: checkBoxColorZugClick()
                ToolTip.visible: hovered
                ToolTip.text: "Haken wegnehmen, um alles schwarz zu färben"
            }

            Button {
                text: "GS abspielbar machen"
                visible: false
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                onClicked: makePlayable()
            }

            Pane {
                Layout.fillWidth: true
                padding: 3
                GridLayout {
                    anchors.fill: parent
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 0
                    Text {
                        text: "Stimmen übersetzen"
                        horizontalAlignment: Text.AlignHCenter
                        bottomPadding: 3
                        Layout.fillWidth: true
                        Layout.columnSpan: 4
                    }

                    Text {
                        text: "1. St."
                        leftPadding: 4
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "2. St."
                        leftPadding: 4
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "3. St."
                        leftPadding: 4
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "4. St."
                        leftPadding: 4
                        Layout.fillWidth: true
                    }

                    CheckBox {
                        id: checkBoxVoice1
                        leftPadding: 0
                        checked: true
                        onClicked: checkVoiceCheckboxesValidity()
                        ToolTip.visible: hovered
                        ToolTip.text: "Innerhalb einer Notenzeile können mehrere Stimmen stehen."
                    }
                    CheckBox {
                        id: checkBoxVoice2
                        leftPadding: 0
                        checked: true
                        onClicked: checkVoiceCheckboxesValidity()
                        ToolTip.visible: hovered
                        ToolTip.text: "Für die meisten zwei- und dreistimmigen Stücke reicht aber die 1. Stimme aus."
                    }
                    CheckBox {
                        id: checkBoxVoice3
                        leftPadding: 0
                        checked: true
                        onClicked: checkVoiceCheckboxesValidity()
                        ToolTip.visible: hovered
                        ToolTip.text: "Für die meisten zwei- und dreistimmigen Stücke reicht aber die 1. Stimme aus."
                    }
                    CheckBox {
                        id: checkBoxVoice4
                        leftPadding: 0
                        checked: true
                        onClicked: checkVoiceCheckboxesValidity()
                        ToolTip.visible: hovered
                        ToolTip.text: "Eine unsichtbare 4. Stimme mit Liedtext kann z.B. für Bassnotation verwendet werden."
                    }
                }
            }

            Button {
                text: "Info"
                Layout.fillWidth: true
                //background.color: colorButtonNormal
                onClicked: infoDialog.open()
            }
        }
    }
  }
