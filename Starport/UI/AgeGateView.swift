import SwiftUI

/// A single, low-friction age acknowledgment for StarPort's 13+ audience.
/// No date of birth, account, or profile is collected. The existing local
/// confirmation remains valid after upgrading, so returning readers skip it.
struct AgeGateView: View {
    let onConfirm13Plus: () -> Void
    @State private var under13 = false

    var body: some View {
        ZStack {
            Starfield()

            VStack(spacing: 0) {
                StarportMasthead()
                    .padding(.top, 18)
                Spacer(minLength: 28)

                VStack(alignment: .leading, spacing: 15) {
                    Text("\(AppBrand.current.masthead)  /  STORIES")
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .tracking(1.3)
                        .foregroundStyle(StarportTheme.teal)

                    Text(AppBrand.current.isStuffyLand ? "Choose a story." : "Your next adventure starts here.")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)

                    if under13 {
                        Text("\(AppBrand.current.name) is for ages 13 and up.")
                            .font(.subheadline)
                            .foregroundStyle(StarportTheme.muted)
                        Button("Back") { under13 = false }
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 10)
                    } else {
                        Text("Ages 13+. Confirm you're 13 or older to continue.")
                            .font(.subheadline)
                            .foregroundStyle(StarportTheme.muted)

                        PrimaryAction(label: "Continue") {
                            onConfirm13Plus()
                        }
                        .accessibilityHint("Confirms you are at least thirteen and opens the StarPort library.")

                        Button("Under 13") {
                            under13 = true
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(StarportTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
                .padding(22)
                .frame(maxWidth: 420, alignment: .leading)
                .background(StarportTheme.panel.opacity(0.98),
                            in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(StarportTheme.line, lineWidth: 1)
                }

                Spacer(minLength: 32)
            }
            .frame(maxWidth: 540)
            .padding(.horizontal, 23)
        }
    }
}
