import Foundation

/// App-specific identity. Both iOS targets compile the same story engine and
/// reading screens; only their content bundles, identifiers and presentation differ.
enum AppBrand: String {
    case starport
    case stuffyland

    static var current: AppBrand {
        let raw = Bundle.main.object(forInfoDictionaryKey: "STORY_BRAND") as? String
        return AppBrand(rawValue: raw ?? "") ?? .starport
    }

    var isStuffyLand: Bool { self == .stuffyland }
    // Stuffy Land relies on the App Store age classification, not a consumer-facing age question.
    // Starport's existing age acknowledgment remains unchanged.
    var requiresInAppAgeConfirmation: Bool { !isStuffyLand }
    var name: String { isStuffyLand ? "Stuffy Land" : "Starport" }
    var masthead: String { isStuffyLand ? "STUFFY LAND" : "STARPORT" }
    var tagline: String { isStuffyLand ? "A WORLD OF STORIES" : "STORIES BEYOND HOME" }
    var heroEyebrow: String { isStuffyLand ? "THE STORY SHELF" : "INTERACTIVE FICTION" }
    var heroTitle: String { isStuffyLand ? "Every story starts somewhere." : "Choose a story.\nChange the ending." }
    var heroDescription: String {
        isStuffyLand
            ? "Some stories you read. In others, you decide what happens."
            : "The story moves forward because of your decisions."
    }
    var readerFooter: String { isStuffyLand ? "STUFFY LAND  /  STORYBOOK" : "STARPORT NINE  /  FIELD NOTES" }
    var achievementsEyebrow: String { isStuffyLand ? "THE MEMORY BOOK" : "MISSION RECORD" }
    var storagePrefix: String { isStuffyLand ? "stuffyland" : "starport" }
    var removeAdsProductID: String { isStuffyLand ? "pro.stuffyland.stories.remove_ads" : "pro.starport.story.remove_ads" }
    var remoteContentRoot: String {
        isStuffyLand
            ? "https://raw.githubusercontent.com/killjoy00/Starport/main/StuffyLand/Content/"
            : "https://raw.githubusercontent.com/killjoy00/Starport/main/Starport/Content/"
    }
    func statTitle(_ stat: StoryStat) -> String {
        guard isStuffyLand else { return stat.title }
        switch stat {
        case .clues: return "Curiosity"
        case .power: return "Courage"
        case .trust: return "Friendship"
        }
    }
}
