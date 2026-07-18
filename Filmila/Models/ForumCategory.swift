import Foundation
import SwiftUI

struct ForumCategory: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let color: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case color
        case createdAt = "created_at"
    }

    init(
        id: Int,
        name: String,
        description: String? = nil,
        color: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        createdAt = try container.decodeFilmilaTimestampIfPresent(forKey: .createdAt)
    }

    var displayColor: Color {
        guard let color = color?.trimmingCharacters(in: .whitespacesAndNewlines), !color.isEmpty else {
            return FilmilaColors.accent
        }
        return Color(hex: color)
    }
}
