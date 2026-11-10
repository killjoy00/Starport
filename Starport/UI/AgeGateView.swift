import SwiftUI

/// Self-attested age check. No birth date or other personal data is collected.
/// A user who does not affirm they are at least 13 never reaches the library,
/// the story, ad requests, or in-app purchase UI.
struct AgeGateView: View {
    let onConfirm13Plus: () -> Void
    @State private var under13 = false

    var body: some View {
        ZStack {
            Starfield()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    StarportMasthead()
                        .padding(.top, 30)
                    OrbitArtwork()
                        .frame(height: 170)

                    Text(under13 ? "See you when you're older." : "Before you enter \(AppBrand.current.name)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)

                    if under13 {
                        Text("\(AppBrand.current.name) is for people aged 13 and older. You can't open the adventure library yet.")
                            .font(.title3)
                            .foregroundStyle(StarportTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("When you're 13 or older, you can check again.")
                            .font(.body)
                            .foregroundStyle(StarportTheme.muted)
                        Button("Back") { under13 = false }
                            .font(.headline)
                            .padding(.vertical, 12)
                    } else {
                        Text("\(AppBrand.current.name) is an adventure app for ages 13 and up. Please confirm your age to continue.")
                            .font(.title3)
                            .foregroundStyle(StarportTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        PrimaryAction(label: "I'm 13 or older") {
                            onConfirm13Plus()
                        }
                        Button("I'm under 13") {
                            under13 = true
                        }
                        .font(.headline)
                        .foregroundStyle(StarportTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)

                        Text("We don't ask for your name or date of birth. \(AppBrand.current.name) remembers only that you confirmed you're old enough.")
                            .font(.footnote)
                            .foregroundStyle(StarportTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: 540)
                .padding(.horizontal, 26)
                .padding(.bottom, 50)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
