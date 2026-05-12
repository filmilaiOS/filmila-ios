import Foundation

enum FilmStatus: String, Codable, Equatable, Sendable {
    case pending
    case approved
    case rejected
}

struct Film: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let title: String
    let titleAr: String?
    let description: String?
    let descriptionAr: String?
    let thumbnailUrl: String?
    let hlsUrl: String?
    let videoUrl: String?
    let price: Double
    let status: FilmStatus
    let genre: String?
    let duration: Int?
    let viewCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleAr = "title_ar"
        case description
        case descriptionAr = "description_ar"
        case thumbnailUrl = "thumbnail_url"
        case hlsUrl = "hls_url"
        case videoUrl = "video_url"
        case price
        case status
        case genre
        case duration
        case viewCount = "view_count"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        title: String,
        titleAr: String? = nil,
        description: String? = nil,
        descriptionAr: String? = nil,
        thumbnailUrl: String? = nil,
        hlsUrl: String? = nil,
        videoUrl: String? = nil,
        price: Double,
        status: FilmStatus,
        genre: String? = nil,
        duration: Int? = nil,
        viewCount: Int,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.titleAr = titleAr
        self.description = description
        self.descriptionAr = descriptionAr
        self.thumbnailUrl = thumbnailUrl
        self.hlsUrl = hlsUrl
        self.videoUrl = videoUrl
        self.price = price
        self.status = status
        self.genre = genre
        self.duration = duration
        self.viewCount = viewCount
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        titleAr = try container.decodeIfPresent(String.self, forKey: .titleAr)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        descriptionAr = try container.decodeIfPresent(String.self, forKey: .descriptionAr)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        hlsUrl = try container.decodeIfPresent(String.self, forKey: .hlsUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        price = try container.decodeLossyDouble(forKey: .price)
        status = try container.decode(FilmStatus.self, forKey: .status)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
    }

    var isFree: Bool {
        price == 0
    }

    var displayTitle: String {
        let prefersArabic = Locale.current.language.languageCode?.identifier == "ar"
            || Locale.preferredLanguages.first?.hasPrefix("ar") == true
        if prefersArabic, let ar = titleAr, !ar.isEmpty {
            return ar
        }
        return title
    }

    var displayDescription: String? {
        let prefersArabic = Locale.current.language.languageCode?.identifier == "ar"
            || Locale.preferredLanguages.first?.hasPrefix("ar") == true
        if prefersArabic, let ar = descriptionAr, !ar.isEmpty {
            return ar
        }
        if let description, !description.isEmpty {
            return description
        }
        return descriptionAr
    }
}
