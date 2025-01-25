// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Tonic/

import Foundation

/// A set of intervals from the root (tonic).
public struct Scale: OptionSet, Hashable {
    public let rawValue: Int

    public let scaleDescription: String

    public var intervals: [Interval] {
        var result: [Interval] = []
        for i in 0 ..< Interval.allCases.count {
            if (rawValue >> i) & 1 != 0 {
                result.append(Interval(rawValue: i)!)
            }
        }
        return result
    }

    public init(rawValue: Int) {
        self.rawValue = rawValue
        scaleDescription = ""
    }

    public init(intervals: [Interval], description: String) {
        self.scaleDescription = description
        var r = 0
        for interval in intervals {
            r |= (1 << interval.rawValue)
        }
        rawValue = r
    }
    
//    public init(rawValue: Int, description: String) {
//        self.rawValue = rawValue
//        self.scaleDescription = description
//    }
}

extension Scale: CustomStringConvertible {
    public var description: String {
        scaleDescription
    }
}

/// Automatic synthesis of Codable would use OptionSets RawRepresentable Conformance to de- and encode objects.
/// Unfortunatly this will lead to the loss of the "description" property. That's why we decided to create explicit codable support.
extension Scale: Codable {
    private enum CodingKeys: String, CodingKey {
        case intervals
        case scaleDescription
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let intervals = try container.decode(Int.self, forKey: .intervals)
        let description = try container.decode(String.self, forKey: .scaleDescription)
//        self = .init(rawValue: intervals, description: description)
        
        rawValue = intervals
        scaleDescription = description
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .intervals)
        try container.encode(scaleDescription, forKey: .scaleDescription)
    }
}
