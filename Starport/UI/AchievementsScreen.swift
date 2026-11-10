import SwiftUI

/// An offline, account-free achievement shelf shared by Starport adventures.
struct AchievementsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameStore

    private var earned: Int {
        AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).filter { game.achievements.contains($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(AppBrand.current.achievementsEyebrow)
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(StarportTheme.orange)
                        Text("\(earned) of \(AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).count) unlocked")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(StarportTheme.paper)
                        ProgressView(value: Double(earned), total: Double(AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).count))
                            .tint(StarportTheme.teal)
                            .accessibilityLabel("\(earned) of \(AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).count) achievements unlocked")
                        Text("Explore every branch, recover from wrong turns, and collect the real endings. Achievements stay on this device.")
                            .font(.subheadline)
                            .foregroundStyle(StarportTheme.muted)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 16))

                    ForEach(Achievement.Group.allCases, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 11) {
                            Text(AppBrand.current.isStuffyLand && group == .endings ? "STORY ENDINGS" : group.rawValue.uppercased())
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .tracking(1.3)
                                .foregroundStyle(StarportTheme.orange)
                            ForEach(AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).filter { $0.group == group }) { badge in
                                achievementRow(badge)
                            }
                        }
                    }
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 35)
                .frame(maxWidth: .infinity)
            }
            .background(Starfield())
            .navigationTitle(AppBrand.current.isStuffyLand ? "Memory book" : "Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(StarportTheme.teal)
    }

    private func achievementRow(_ item: Achievement) -> some View {
        let unlocked = game.achievements.contains(item.id)
        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: unlocked ? item.symbol : "lock")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(unlocked ? StarportTheme.teal : StarportTheme.muted)
                .frame(width: 43, height: 43)
                .background(StarportTheme.ink, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(unlocked || !item.secret ? item.title : "Undiscovered ending")
                    .font(.headline)
                    .foregroundStyle(StarportTheme.paper)
                Text(unlocked || !item.secret ? item.detail : "Discover this outcome to reveal its achievement.")
                    .font(.subheadline)
                    .foregroundStyle(StarportTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: unlocked ? "checkmark.seal.fill" : "circle.dotted")
                .foregroundStyle(unlocked ? StarportTheme.teal : StarportTheme.muted)
                .accessibilityHidden(true)
        }
        .padding(15)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(StarportTheme.line.opacity(unlocked ? 1 : 0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(unlocked ? "unlocked" : "locked")")
    }
}
