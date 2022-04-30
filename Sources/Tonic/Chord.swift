
import Foundation

/// Chord addresses all possible combinations of simultaneous MIDI notes.
public struct Chord {

    public var noteSet = NoteSet()

    public init(notes: [Note]) {
        for n in notes {
            add(note: n)
        }
    }

    public var noteCount: Int {
        notes.count
    }

    public var isDyad: Bool {
        noteCount == 2
    }

    public var isTriad: Bool {
        noteCount == 3
    }

    public var notes: [Note] {
        var r: [Note] = []
        forEachNote({ r.append($0)})
        return r
    }

    /// Calls a function for each note in the chord.
    public func forEachNote(_ f: (Note) -> ()) {
        noteSet.forEachNote { n in
            f(n)
        }
    }

    /// Add a note to a chord.
    public mutating func add(note: Note) {
        noteSet.add(note: note)
    }

    /// Is a note in a chord?
    public func contains(note: Note) -> Bool {
        noteSet.contains(note: note)
    }

    /// One-sided Hausdorff distance to another chord.
    ///
    /// https://en.wikipedia.org/wiki/Hausdorff_distance
    public func hausdorff(to: Chord) -> Int {
        var d_sup = 0
        self.forEachNote { n0 in
            var d_inf = Int.max
            to.forEachNote { n1 in
                d_inf = min(d_inf, n0.semitones(to: n1))
            }
            d_sup = max(d_sup, d_inf)
        }
        return d_sup
    }

    /// Try to give this chord a name in a particular key.
    public var name: String {

        let table = ChordTable.shared
        let hash = pitchClassesHash

        if let info = table.triads[hash] {
            let root = info.root
            switch info.type {
            case .major: return root.spelling
            case .minor: return "\(root.spelling)m"
            case .diminished: return "\(root.spelling)°"
            case .augmented: return "\(root.spelling)⁺"
            }
        }

        return "unknown chord"
    }

    public var pitchClassesHash: Int {
        var r = NoteSet()
        noteSet.forEachNote { note in
            r.add(note: note.pitchClass)
        }
        return r.hashValue
    }

}

public enum TriadType {
    case major, minor, diminished, augmented
}

public struct TriadInfo {
    var root: Note
    var type: TriadType
}

/// A table of note sets so we can look up chord names.
class ChordTable {

    static let shared = ChordTable()

    static func hashPitchClasses(notes: [Note?]) -> Int {
        var r = NoteSet()
        for note in notes {
            if let note = note {
                r.add(note: note.pitchClass)
            }
        }
        return r.hashValue
    }
    
    static func generateTriads(third: Interval, fifth: Interval, type: TriadType, _ r: inout [Int: TriadInfo]) {
        let accidentals: [Accidental] = [.flat, .natural, .sharp]
        for accidental in accidentals {
            for letter in Letter.allCases {
                let root = Note(letter, accidental: accidental)
                r[ChordTable.hashPitchClasses(notes: [root, root.shiftUp(third), root.shiftUp(fifth)])] = TriadInfo(root: root, type: type)
            }
        }
    }

    static func generateAllTriads() -> [Int: TriadInfo] {
        var r: [Int: TriadInfo] = [:]

        ChordTable.generateTriads(third: .M3, fifth: .P5, type: .major, &r)
        ChordTable.generateTriads(third: .m3, fifth: .P5, type: .minor, &r)
        ChordTable.generateTriads(third: .m3, fifth: .d5, type: .diminished, &r)
        ChordTable.generateTriads(third: .M3, fifth: .A5, type: .augmented, &r)

        print("generated \(r.count) triads")

        return r
    }

    lazy var triads: [Int: TriadInfo] = ChordTable.generateAllTriads()

}

/// A set of intervals from the root (tonic).
struct ChordType: OptionSet {
    let rawValue: Int

    var intervals: [Interval] {

        var result: [Interval] = []
        for i in 0..<11 {
            if (rawValue >> i) & 1 != 0 {
                result.append(Interval(rawValue: i)!)
            }
        }
        return result
    }

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(intervals: [Interval]) {
        var r = 0
        for interval in intervals {
            r |= (1 << interval.rawValue)
        }
        self.rawValue = r
    }

    static let majorTriad = ChordType(intervals: [.M3, .P5])
    static let majorSixth = ChordType(intervals: [.M3, .P5, .M6])
    static let dominantSeventh = ChordType(intervals: [.M3, .P5, .m7])
    static let minorTriad = ChordType(intervals: [.m3, .P5])
}
