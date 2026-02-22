import SwiftUI

enum Brand {
    static let tint = Color("BrandTint")
    static let navy = Color("BrandNavy")
    static let orange = Color("BrandOrange")
    static let gold = Color("BrandGold")
    static let background = Color("BrandBackground")
    static let surface = Color("BrandSurface")
    static let danger = Color("BrandDanger")
}

struct BrandBackgroundView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Brand.background
                .ignoresSafeArea()
            content
        }
    }
}

