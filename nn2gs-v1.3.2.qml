
/*

    Nn2GS - Übersetzt zwischen Normalnoten und Griffschrift-Tabulatur für Steirische Harmonika.
    Copyright (C) 2021  Jakob Schöttl <jschoett@gmail.com>

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
version: "1.3.2"
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
$jscomp.scope = {};
$jscomp.createTemplateTagFirstArg = function(a) {
  return a.raw = a;
};
$jscomp.createTemplateTagFirstArgWithRaw = function(a, b) {
  a.raw = b;
  return a;
};
$jscomp.arrayIteratorImpl = function(a) {
  var b = 0;
  return function() {
    return b < a.length ? {done:!1, value:a[b++], } : {done:!0};
  };
};
$jscomp.arrayIterator = function(a) {
  return {next:$jscomp.arrayIteratorImpl(a)};
};
$jscomp.makeIterator = function(a) {
  var b = "undefined" != typeof Symbol && Symbol.iterator && a[Symbol.iterator];
  return b ? b.call(a) : $jscomp.arrayIterator(a);
};

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

    //readonly property string apiUrl: "https://ziach.intensovet.de/nn2gs"
    readonly property string apiUrl: "https://ziach.intensovet.de/nn2gs"

    readonly property var colorRed: "#ff0000"
    readonly property var colorBlue: "#0000ff"
    readonly property var colorBlack: "#000000"
    readonly property var colorButtonNormal: "#bbb"
    readonly property var colorDirectionReverse: "#666"

    // Generated using Nn2GS.hs:
    // result = map (\(x,y) -> (x, map toLower.noteNameToGerman.show $ y, computeAccidentals $ Dur y)) quintenZirkel
    // encode result
    // putStrLn ...
    readonly property var tonarten: [[-8,"fes",["Bes","Ees","Aes","Des","Ges","Ces","Fes"]],[-7,"ces",["Bes","Ees","Aes","Des","Ges","Ces","Fes"]],[-6,"ges",["Bes","Ees","Aes","Des","Ges","Ces"]],[-5,"des",["Bes","Ees","Aes","Des","Ges"]],[-4,"as",["Bes","Ees","Aes","Des"]],[-3,"es",["Bes","Ees","Aes"]],[-2,"b",["Bes","Ees"]],[-1,"f",["Bes"]],[0,"c",[]],[1,"g",["Fis"]],[2,"d",["Fis","Cis"]],[3,"a",["Fis","Cis","Gis"]],[4,"e",["Fis","Cis","Gis","Dis"]],[5,"h",["Fis","Cis","Gis","Dis","Ais"]],[6,"fis",["Fis","Cis","Gis","Dis","Ais","Eis"]],[7,"cis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[8,"gis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[9,"dis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[10,"ais",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[11,"eis",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]],[12,"his",["Fis","Cis","Gis","Dis","Ais","Eis","Bis"]]]

    // Generated using Nn2GS.hs:
    // Exclude some notes; see documentation in getNoteName().
    // encode . filter (not . flip elem [Eis, Bis, Ces, Fes] . withoutOctave . fst) . M.toList $ midiPitchMap
    // putStrLn "..."
    readonly property var midiPitchMap: [["C_",36],["Cis_",37],["Des_",37],["D_",38],["Dis_",39],["Ees_",39],["E_",40],["F_",41],["Fis_",42],["Ges_",42],["G_",43],["Gis_",44],["Aes_",44],["A_",45],["Ais_",46],["Bes_",46],["B_",47],["C",48],["Cis",49],["Des",49],["D",50],["Dis",51],["Ees",51],["E",52],["F",53],["Fis",54],["Ges",54],["G",55],["Gis",56],["Aes",56],["A",57],["Ais",58],["Bes",58],["B",59],["C'",60],["Cis'",61],["Des'",61],["D'",62],["Dis'",63],["Ees'",63],["E'",64],["F'",65],["Fis'",66],["Ges'",66],["G'",67],["Gis'",68],["Aes'",68],["A'",69],["Ais'",70],["Bes'",70],["B'",71],["C''",72],["Cis''",73],["Des''",73],["D''",74],["Dis''",75],["Ees''",75],["E''",76],["F''",77],["Fis''",78],["Ges''",78],["G''",79],["Gis''",80],["Aes''",80],["A''",81],["Ais''",82],["Bes''",82],["B''",83],["C'''",84],["Cis'''",85],["Des'''",85],["D'''",86],["Dis'''",87],["Ees'''",87],["E'''",88],["F'''",89],["Fis'''",90],["Ges'''",90],["G'''",91],["Gis'''",92],["Aes'''",92],["A'''",93],["Ais'''",94],["Bes'''",94],["B'''",95],["C''''",96],["Cis''''",97],["Des''''",97],["D''''",98],["Dis''''",99],["Ees''''",99],["E''''",100],["F''''",101],["Fis''''",102],["Ges''''",102],["G''''",103],["Gis''''",104],["Aes''''",104],["A''''",105],["Ais''''",106],["Bes''''",106],["B''''",107]]

    // Generated using Nn2GS.hs:
    // map (\x -> [show x, map toLower . noteNameToGerman . show $ x]) $ enumFrom C_
    readonly property var germanNoteNames: [["C_","c_"],["Cis_","cis_"],["Des_","des_"],["D_","d_"],["Dis_","dis_"],["Ees_","es_"],["E_","e_"],["Fes_","fes_"],["Eis_","eis_"],["F_","f_"],["Fis_","fis_"],["Ges_","ges_"],["G_","g_"],["Gis_","gis_"],["Aes_","as_"],["A_","a_"],["Ais_","ais_"],["Bes_","b_"],["B_","h_"],["Ces","ces"],["Bis_","his_"],["C","c"],["Cis","cis"],["Des","des"],["D","d"],["Dis","dis"],["Ees","es"],["E","e"],["Fes","fes"],["Eis","eis"],["F","f"],["Fis","fis"],["Ges","ges"],["G","g"],["Gis","gis"],["Aes","as"],["A","a"],["Ais","ais"],["Bes","b"],["B","h"],["Ces'","ces'"],["Bis","his"],["C'","c'"],["Cis'","cis'"],["Des'","des'"],["D'","d'"],["Dis'","dis'"],["Ees'","es'"],["E'","e'"],["Fes'","fes'"],["Eis'","eis'"],["F'","f'"],["Fis'","fis'"],["Ges'","ges'"],["G'","g'"],["Gis'","gis'"],["Aes'","as'"],["A'","a'"],["Ais'","ais'"],["Bes'","b'"],["B'","h'"],["Ces''","ces''"],["Bis'","his'"],["C''","c''"],["Cis''","cis''"],["Des''","des''"],["D''","d''"],["Dis''","dis''"],["Ees''","es''"],["E''","e''"],["Fes''","fes''"],["Eis''","eis''"],["F''","f''"],["Fis''","fis''"],["Ges''","ges''"],["G''","g''"],["Gis''","gis''"],["Aes''","as''"],["A''","a''"],["Ais''","ais''"],["Bes''","b''"],["B''","h''"],["Ces'''","ces'''"],["Bis''","his''"],["C'''","c'''"],["Cis'''","cis'''"],["Des'''","des'''"],["D'''","d'''"],["Dis'''","dis'''"],["Ees'''","es'''"],["E'''","e'''"],["Fes'''","fes'''"],["Eis'''","eis'''"],["F'''","f'''"],["Fis'''","fis'''"],["Ges'''","ges'''"],["G'''","g'''"],["Gis'''","gis'''"],["Aes'''","as'''"],["A'''","a'''"],["Ais'''","ais'''"],["Bes'''","b'''"],["B'''","h'''"],["Ces''''","ces''''"],["Bis'''","his'''"],["C''''","c''''"],["Cis''''","cis''''"],["Des''''","des''''"],["D''''","d''''"],["Dis''''","dis''''"],["Ees''''","es''''"],["E''''","e''''"],["Fes''''","fes''''"],["Eis''''","eis''''"],["F''''","f''''"],["Fis''''","fis''''"],["Ges''''","ges''''"],["G''''","g''''"],["Gis''''","gis''''"],["Aes''''","as''''"],["A''''","a''''"],["Ais''''","ais''''"],["Bes''''","b''''"],["B''''","h''''"],["Ces'''''","ces'''''"],["Bis''''","his''''"]]

    // Generated using Nn2GS.hs:
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
  var b = [];
  return JSON.stringify(a, function(c, d) {
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
  var b = [], c;
  for (c in a) {
    b.push(c);
  }
  return b;
}
function fixPlayedNotePitch(a, b) {
  for (var c = 0; c < a.playEvents.length; c++) {
    a.playEvents[c].pitch = b - a.pitch;
  }
}
function resetPlayedNotePitch(a) {
  for (var b = 0; b < a.playEvents.length; b++) {
    a.playEvents[b].pitch = 0;
  }
}
function colorNoteZugDruck(a, b, c) {
  a.color == colorBlue && "zug" !== b ? a.color = colorBlack : c.checked && "zug" === b && (a.color = colorBlue);
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
  var d = newElement(Element.SYMBOL);
  d.symbol = b;
  d.offsetX = c;
  a.add(d);
}
function isCrossSymbol(a) {
  return a.type == Element.SYMBOL && (a.symbol == SymId.noteheadXBlack || a.symbol == SymId.noteheadHeavyX || a.symbol == SymId.noteheadXOrnate || a.symbol == SymId.noteheadCircleX || a.symbol == SymId.accidentalDoubleSharp || a.symbol == SymId.accidentalDoubleArabic || a.symbol == SymId.noteheadVoidWithX || a.symbol == SymId.noteheadHalfWithX || a.symbol == SymId.noteheadWholeWithX);
}
function hasCrossSymbol(a) {
  for (var b = 0; b < a.elements.length; b++) {
    if (isCrossSymbol(a.elements[b])) {
      return !0;
    }
  }
}
function removeCrossBeforeHead(a) {
  for (var b = 0; b < a.elements.length; b++) {
    var c = a.elements[b];
    isCrossSymbol(c) && a.remove(c);
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
  return a.map(function(b) {
    for (var c = 0; c < b.notes.length; c++) {
      if (hasSpecialNoteHead(b.notes[c])) {
        return !0;
      }
    }
    return !1;
  }).some(function(b) {
    return b;
  });
}
function queryStringArg(a, b, c) {
  return ((void 0 === c ? 0 : c) ? "" : "&") + (encodeURIComponent(a) + "=" + encodeURIComponent(b));
}
function chordsAsApiInput(a, b) {
  var c = b ? function(d, e) {
    return {crossed:hasCrossedNoteHead(d), position:getNoteName(e), pitch:e};
  } : function(d, e) {
    return getNoteName(e);
  };
  return a.map(function(d) {
    var e = [];
    d = d.notes;
    for (var f = 0; f < d.length; f++) {
      var g = d[f];
      e.push(c(g, g.pitch));
    }
    console.log(e);
    return e;
  });
}
function getMidiPitch(a) {
  var b = midiPitchMap.find(function(c) {
    c = $jscomp.makeIterator(c);
    var d = c.next().value;
    c.next();
    return d === a;
  });
  return b ? b[1] : null;
}
function getNoteName(a) {
  var b = midiPitchMap.find(function(c) {
    c = $jscomp.makeIterator(c);
    c.next();
    return c.next().value === a;
  });
  return b ? b[0] : null;
}
function extractZDResults(a, b) {
  return b["druck" === a ? 1 : 0];
}
function lookupTonalPitchClass(a) {
  return tonalPitchClassMap.find(function(b) {
    b = $jscomp.makeIterator(b);
    var c = b.next().value;
    b.next();
    return a == c;
  })[1];
}
function containsRedNote(a) {
  for (var b = 0; b < a.length; b++) {
    if (a[b].color == colorRed) {
      return !0;
    }
  }
  return !1;
}
function constructChordsFromNormalResults(a) {
  return a.map(function(b) {
    var c = [], d = {pitch:80, add:function(f) {
    }, playEvents:{length:0}, elements:{length:0}, duration:{numerator:1, denominator:4}};
    console.log("Created element: " + d);
    var e = function(f) {
      var g = Object.assign({}, d);
      g.pitch = getMidiPitch(f);
      return g;
    };
    b.Right ? c = b.Right.map(e) : b.Left ? (console.warn("Did not receive expected normal notation for current chord: " + jsonStringifyNonRecursive(b)), c = b.Left.map(function(f) {
      return e(f.position);
    })) : console.warn("Invalid result for current chord: " + jsonStringifyNonRecursive(b));
    return {notes:c};
  });
}


    // IMPURE FUNCTIONS HERE:
function applyToChordsInSelection(b, a) {
  var c = curScore.newCursor();
  c.rewind(1);
  var g = !1;
  if (c.segment) {
    var e = c.staffIdx;
    c.rewind(2);
    var k = 0 === c.tick ? curScore.lastSegment.tick + 1 : c.tick;
    var f = c.staffIdx;
  } else {
    g = !0, e = 0, f = curScore.nstaves - 1;
  }
  console.log("applyToChordsInSelection: " + e + " - " + f + " - " + k);
  for (var l = 0; e <= f; e++) {
    for (var h = 0; 4 > h; h++) {
      for (c.rewind(1), c.voice = h, c.staffIdx = e, g && c.rewind(0); c.segment && (g || c.tick < k);) {
        if (c.element && c.element.type == Element.CHORD) {
          for (var d = c.element.graceNotes, m = 0; m < d.length; m++) {
            if (a(d[m]), l++, l >= b) {
              return;
            }
          }
          a(c.element);
          l++;
          if (l >= b) {
            return;
          }
        }
        c.next();
      }
    }
  }
}
function callApi(b, a, c) {
  var g = JSON.stringify(chordsAsApiInput(b, a));
  a = "?" + queryStringArg("tonart", tonarten[spinnerTonart.value][1], !0) + queryStringArg("model", comboModel.currentKey()) + (a ? queryStringArg("reverse", "yes") : "") + (txtLicenseKey.text ? queryStringArg("license", txtLicenseKey.text) : "");
  console.log(a);
  var e = new XMLHttpRequest;
  e.onreadystatechange = function() {
    if (e.readyState === XMLHttpRequest.DONE) {
      if (console.log("HTTP status: " + e.status), 200 === e.status) {
        console.log("API response:\n" + e.responseText);
        try {
          lastResults = JSON.parse(e.responseText);
        } catch (k) {
          console.error("Invalid JSON response. Could not parse."), errorDialog.show("Ung\u00fcltige Antwort vom Server.");
        }
        c(b, lastResults);
      } else {
        500 <= e.status ? errorDialog.show("Fehler beim Server. Funktioniert " + apiUrl + "?") : 400 <= e.status ? errorDialog.show("Fehler bei der Kommunikation mit dem Server. Funktioniert " + apiUrl + "?") : 300 <= e.status ? errorDialog.show("Wahrscheinlich passt die Lizenz nicht oder Sie haben noch eine alte Version dieses Plugins. \u00dcberpr\u00fcfen: " + apiUrl + "?license=" + txtLicenseKey.text + ".") : errorDialog.show("Unbekannter Netzwerkfehler (HTTP Status Code " + e.status + "). Funktioniert das Internet? Funktioniert " + 
        apiUrl + "?");
      }
    } else {
      console.log("HTTP request ready status: " + e.readyState + " (not DONE)");
    }
  };
  console.log("Run in shell for testing:\ncat <<TEXT > test.json\n" + g + '\nTEXT\ncurl -H "Content-Type: application/json" --data-binary @test.json "' + (apiUrl + a) + '"\n');
  e.open("POST", apiUrl + a, !0);
  e.setRequestHeader("Content-Type", "application/json");
  e.send(g);
}
function collectChords() {
  var b = parseVoicesFromTextField(), a = [];
  applyToChordsInSelection(maxChordLimit + 1, function(c) {
    containsRedNote(c) ? console.log("Collecting chords: Current chord contains a red note. Skipping to next chord.") : b.includes(c.voice) && a.push(c);
  });
  return a;
}
function changeNotes(b, a) {
  return function(c, g) {
    lastZD = b;
    g = extractZDResults(b, g);
    console.log(b + " " + g);
    if (c.length !== g.length) {
      console.warn("Length of selected chords (" + c.length + ") and translation result (" + g.length + ") do not match. Aborting.");
    } else {
      var e = a ? changeNotesOfChordReverse : changeNotesOfChord, k = 0;
      curScore.startCmd();
      for (var f = 0; f < c.length; f++) {
        k += e(c[f], g[f], b, f);
      }
      curScore.endCmd();
      k && errorDialog.show(k + " Note(n) konnten nicht \u00fcbersetzt werden und wurden rot markiert.\n\nEntweder existieren sie nicht auf dem Instrument oder sie waren bereits rot markiert. Die Akkorde mit roten Noten wurden bei der \u00dcbersetzung \u00fcbersprungen.");
    }
  };
}
function changeNotesOfChordReverse(b, a, c, g) {
  b = b.notes;
  c = 0;
  if (containsRedNote(b)) {
    return console.log("Current chord " + g + " contains a red note. Leaving it unchanged. Skipping to next chord."), c++, c;
  }
  if (a.Right) {
    a = a.Right;
    for (var e = 0; e < b.length; e++) {
      var k = a[e], f = b[e];
      if (b.length !== a.length) {
        console.warn("Length of current chord (" + b.length + ") and translation result (" + a.length + ") do not match in chord " + g + ", note " + e + ". Skipping to next chord.");
        break;
      }
      var l = getMidiPitch(k);
      null === l ? console.warn("Invalid note position " + k + " in translation result in chord " + g + ", note " + e + ". Skipping to next note.") : (k = lookupTonalPitchClass(k), f.headGroup = NoteHeadGroup.HEAD_NORMAL, removeCrossBeforeHead(f), f.mirrorHead = 0, console.log("Changing GS " + f.pitch + " (tpc=" + f.tpc + ") to Nn " + l + " (tpc=" + k + ")"), f.pitch = l, f.tpc1 = k, f.tpc2 = k, f.visible = !0, f.headType = NoteHeadType.HEAD_AUTO, setAccidentalVisible(f, !0), resetPlayedNotePitch(f));
    }
  } else {
    if (a.Left) {
      for (g = a.Left.map(function(h) {
        var d = h.crossed;
        return [getMidiPitch(h.position), d];
      }), a = {}, e = 0; e < b.length; a = {$jscomp$loop$prop$note$1$5:a.$jscomp$loop$prop$note$1$5}, e++) {
        a.$jscomp$loop$prop$note$1$5 = b[e], a.$jscomp$loop$prop$note$1$5.visible = !0, g.some(function(h) {
          return function(d) {
            var m = $jscomp.makeIterator(d);
            d = m.next().value;
            m = m.next().value;
            return d == h.$jscomp$loop$prop$note$1$5.pitch && m == hasCrossedNoteHead(h.$jscomp$loop$prop$note$1$5);
          };
        }(a)) && (a.$jscomp$loop$prop$note$1$5.color = colorRed, c++);
      }
    } else {
      throw Error("Invalid result for current chord " + g + ": " + JSON.stringify(a));
    }
  }
  return c;
}
function changeNotesOfChord(b, a, c, g) {
  var e = b.notes, k = 0;
  if (containsRedNote(e)) {
    return console.log("Current chord " + g + " contains a red note. Leaving it unchanged. Skipping to next chord."), k++, k;
  }
  if (a.Right) {
    for (var f = 0; f < e.length; f++) {
      var l = a.Right[alternativeIndex % a.Right.length], h = l[f], d = e[f];
      if (e.length !== l.length) {
        console.warn("Length of current chord (" + e.length + ") and translation result (" + l.length + ") do not match in chord " + g + ", note " + f + ". Skipping to next chord.");
        break;
      }
      l = h.pitch;
      if (null === l) {
        console.warn("Invalid note position " + h.position + " in translation result in chord " + g + ", note " + f + ". Skipping to next note.");
      } else {
        var m = lookupTonalPitchClass(h.position);
        colorNoteZugDruck(d, c, checkBoxColorZug);
        console.log("Changing Nn " + d.pitch + " (tpc=" + d.tpc + ") to GS " + l + " (tpc=" + m + ")");
        d.pitch = l;
        d.tpc1 = m;
        d.tpc2 = m;
        null !== h.side && checkBoxSortHeads.checked ? "Links" === h.side ? d.mirrorHead = 1 : "Rechts" === h.side && (d.mirrorHead = 2) : d.mirrorHead = 0;
        d.headGroup = NoteHeadGroup.HEAD_NORMAL;
        removeCrossBeforeHead(d);
        setAccidentalVisible(d, !1);
        if (h.extra && 0 === h.row) {
          d.headGroup = NoteHeadGroup.HEAD_TRIANGLE_UP;
        } else {
          if (h.extra && 1 === h.row) {
            d.headGroup = NoteHeadGroup.HEAD_DIAMOND;
          } else {
            if (h.crossed) {
              switch(l = comboTabulatureDisplay.currentKey(), console.log(l), l) {
                case "klassisch_kreuz":
                  addCrossLightBeforeHead(d);
                  break;
                case "klassisch_doppelkreuz":
                  addCrossSharp2BeforeHead(d);
                  break;
                case "johannesservi.de":
                  isHalfOrLonger(b) ? (d.headGroup = NoteHeadGroup.HEAD_WITHX, d.headType = NoteHeadType.HEAD_QUARTER) : d.headGroup = NoteHeadGroup.HEAD_CROSS;
                  break;
                case "johannesservi.de_2":
                  isHalfOrLonger(b) ? d.headGroup = NoteHeadGroup.HEAD_XCIRCLE : d.headGroup = NoteHeadGroup.HEAD_CROSS;
                  break;
                case "matthiaspuerner.de":
                  isHalfOrLonger(b) ? addCrossSharp2BeforeHead(d) : d.headGroup = NoteHeadGroup.HEAD_CROSS;
                  break;
                case "knoepferl.at":
                  2 === h.row ? addCrossLightBeforeHead(d) : addCrossSharp2BeforeHead(d);
                  break;
                case "michlbauer.com":
                  2 === h.row ? addCrossLightBeforeHead(d) : addCrossCircledBeforeHead(d);
                  break;
                case "dickes_kreuz":
                  2 === h.row ? addCrossLightBeforeHead(d) : addCrossBoldBeforeHead(d);
                  break;
                case "klassisch_kreuz2":
                  isHalfOrLonger(b) ? addCrossLightBeforeHead(d) : d.headGroup = NoteHeadGroup.HEAD_CROSS;
                  break;
                case "klassisch_doppelkreuz2":
                  isHalfOrLonger(b) ? addCrossSharp2BeforeHead(d) : (d.visible = !1, addSymbolToNote(d, SymId.accidentalDoubleSharp, 0.1));
                  break;
                default:
                  d.headGroup = NoteHeadGroup.HEAD_CROSS;
              }
            }
          }
        }
        fixPlayedNotePitch(d, h.origPitch);
      }
    }
  } else {
    if (a.Left) {
      for (b = a.Left.map(getMidiPitch), a = 0; a < e.length; a++) {
        c = e[a], b.includes(c.pitch) && (c.color = colorRed, k++);
      }
    } else {
      throw Error("Invalid result for current chord " + g + ": " + JSON.stringify(a));
    }
  }
  return k;
}
function handleClickZugDruck(b) {
  var a = isReverseDirection();
  console.log("Starting translation: " + b + (a ? " reverse" : ""));
  var c = collectChords();
  if (0 === c.length) {
    console.warn("Keine Noten ausgew\u00e4hlt. Abbruch.");
  } else {
    if (c.length > maxChordLimit) {
      console.warn("Zu viele Noten ausgew\u00e4hlt. Abbruch.");
    } else {
      if (1 !== btnReverseDirection.state || isCurrentResultValid()) {
        if (a || !isCurrentResultValid()) {
          if (looksLikeGriffschrift(c) && !a) {
            console.warn("Markierte Noten sehen nach Griffschrift aus. Abbruch.");
            warningDialog.show("Markierte Noten sehen nach Griffschrift aus und k\u00f6nnen so nicht nach Griffschrift \u00fcbersetzt werden.");
            return;
          }
          alternativeIndex = 0;
          callApi(c, a, changeNotes(b, a));
          btnNextAlternative.enabled = !0;
        } else {
          alternativeIndex = b !== lastZD ? 0 : alternativeIndex + 1, changeNotes(b, !1)(c, lastResults);
        }
        invalidateResultsAfterTimeout();
        a && disableZDButtonsForTimeout();
      } else {
        console.log("Alternative Griffweisen durchzappen"), callApi(c, !0, toGriffschrift(b));
      }
    }
  }
}
function makePlayable() {
  invalidateCurrentResults();
  var b = collectChords();
  0 === b.length ? console.warn("Keine Noten ausgew\u00e4hlt. Abbruch.") : b.length > maxChordLimit && console.warn("Zu viele Noten ausgew\u00e4hlt. Abbruch.");
}
function toGriffschrift(b) {
  return function(a, c) {
    a = extractZDResults(b, c);
    a = constructChordsFromNormalResults(a);
    console.log("Aus Normalnoten (die API zur\u00fcckgeliefert hat) werden jetzt MuseScore Notes erstellt, die dann in GS umgewandelt werden: " + JSON.stringify(a));
    alternativeIndex = 0;
    callApi(a, !1, changeNotes(b, !1));
  };
}
function parseVoicesFromTextField() {
  for (var b = txtVoices.text, a = [], c = 0; c < b.length; c++) {
    if (b[c].match(/[1-4]/)) {
      var g = parseInt(b[c]) - 1;
      a.push(g);
    }
  }
  0 === a.length && (a = [0]);
  return a;
}
function lblShowInstrumentClick() {
  var b = comboModel.currentKey();
  collectChords();
  var a = [];
  console.log(a.join(" "));
  Qt.openUrlExternally(apiUrl + "?" + queryStringArg("model", b, !0) + (a.length ? queryStringArg("notes", a.join(" "), !1) : "") + (txtLicenseKey.text ? queryStringArg("license", txtLicenseKey.text) : ""));
}
function lblCurrentKeyClick() {
  var b = curScore.keysig;
  console.log("Globale Dur-Tonart: " + b);
  spinnerTonart.value = 8 + b;
}
function checkBoxColorZugClick() {
  checkBoxColorZug.checked || (curScore.startCmd(), applyToChordsInSelection(1000, function(b) {
    for (var a = 0; a < b.notes.length; a++) {
      var c = b.notes[a];
      c.color == colorBlue && (c.color = colorBlack);
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
        text: "Nn2GS - Übersetzen zwischen Normalnoten und Griffschrift für Steirische Harmonika und ähnliche Instrumente.\n\n      https://ziach.intensovet.de/\n\nMomentan kostenlos, irgendwann wird man für die Nutzung eine günstige Lizenz kaufen müssen.\n\nTastenkürzel: Alt+R (Übersetzungsrichtung), Alt+J (Zug), Alt+K (Druck); auch auf Beschriftungen im Plugin kann geklickt werden (versteckte Funktionen)."
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

    function clickZug() {
        handleClickZugDruck('zug')
    }
    function clickDruck() {
        handleClickZugDruck('druck')
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

    GridLayout {
        anchors.fill: parent
        Layout.fillWidth: true
        columns: 1
        rowSpacing: 1

        Text {
            text: "Instrument (anzeigen)"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            MouseArea {
                anchors.fill: parent
                onClicked: lblShowInstrumentClick()
            }
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
        }

        Button {
            text: "Zug"
            id: btnZug
            Layout.fillWidth: true
            //background.color: colorButtonNormal
            onClicked: clickZug()
        }
        Button {
            text: "Druck"
            id: btnDruck
            Layout.fillWidth: true
            //background.color: colorButtonNormal
            onClicked: clickDruck()
        }
        Button {
            text: "Nächste Alternative"
            Layout.fillWidth: true
            //background.color: colorButtonNormal
            visible: false
            enabled: false
            id: btnNextAlternative
            onClicked: clickNextAlternative()
        }

        Text {
            text: "Einstellungen"
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
                  ListElement { text: "Modern"; key: "modern" }  // Modern
                  ListElement { text: "Modern 2"; key: "johannesservi.de" }   // Johannes Servi
                  ListElement { text: "Modern 3"; key: "johannesservi.de_2" }   // Johannes Servi
                  ListElement { text: "Klassisch (Kreuz)"; key: "klassisch_kreuz" }          // Rosenzopf, klassisch, Kreuz vor Noten
                  ListElement { text: "Klassisch (Kreuz, vor langen Noten)"; key: "klassisch_kreuz2" }          // wie klassisch_kreuz, aber Notenkopf in Kreuzform (außer bei Halben/Ganzen)
                  ListElement { text: "Klassisch (Doppelkreuz)"; key: "klassisch_doppelkreuz" } // Klassisch, Doppelkreuz vor Noten
                  ListElement { text: "Klassisch (Doppelkreuz, vor langen Noten)"; key: "klassisch_doppelkreuz2" } // wie klassisch_doppelkreuz, aber Notenkopf in Doppelkreuzform (außer bei Halben/Ganzen)
                  ListElement { text: "Michlbauer"; key: "michlbauer.com" } // Kreuz vor Noten, 3. R. einfaches Kreuz, 4. R. kleine umringeltes Kreuz => Bravura
                  ListElement { text: "Knöpferl"; key: "knoepferl.at" } // Kreuz vor Noten, 3. R. einfaches Kreuz, 4. R. Doppelkreuz - Quelle: https://knoepferl.at/produkt/orf-wetterpanorama/
                  ListElement { text: "Dickes Kreuz für 4. Reihe"; key: "dickes_kreuz" } // wie klassisch_kreuz, aber das dicke Kreuz für 4. Reihe
                  ListElement { text: "Kreuz/Doppelkreuz gemischt"; key: "matthiaspuerner.de" }  // Matthias Pürner, Doppelkreuz vor Halben/Ganzen, normales Kreuz als Notenkopf sonst - Quelle: https://matthiaspuerner.de/wp-content/uploads/2020/11/01_19er-Marscherl-Griffschrift-2S-Partitur.pdf
            }
            function currentKey() {
                return model.get(currentIndex).key
            }
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
        }

        CheckBox {
            id: checkBoxColorZug
            checked: true
            text: "Zug-GS blau färben"
            onClicked: checkBoxColorZugClick()
        }

        Button {
            text: "GS abspielbar machen"
            visible: false
            Layout.fillWidth: true
            //background.color: colorButtonNormal
            onClicked: makePlayable()
        }

        TextField {
            text: ""
            id: txtVoices
            Layout.fillWidth: true
            placeholderText: "Stimmen übersetzen, z.B. 1, 2, 3"
        }

        Button {
            text: "Info"
            Layout.fillWidth: true
            //background.color: colorButtonNormal
            onClicked: infoDialog.open()
        }
     }
  }
