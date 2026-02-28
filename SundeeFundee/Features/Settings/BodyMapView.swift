import SwiftUI

/// Interactive front/back body silhouette for selecting injury locations.
/// Navy fill, cream background, orange selection highlights (Art Deco theme).
struct BodyMapView: View {
    @Binding var selectedRegions: Set<BodyLocation.Region>
    @State private var showingFront = true

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Picker("View", selection: $showingFront) {
                Text("Front").tag(true)
                Text("Back").tag(false)
            }
            .pickerStyle(.segmented)

            ZStack {
                // Body silhouette background
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(AppTheme.Colors.cream)
                    .stroke(AppTheme.Colors.navy.opacity(0.2), lineWidth: 1)

                if showingFront {
                    frontBody
                } else {
                    backBody
                }
            }
            .frame(height: 400)

            // Selected regions summary
            if !selectedRegions.isEmpty {
                Text(selectedRegions.map(\.displayName).sorted().joined(separator: ", "))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
        }
    }

    private var frontBody: some View {
        VStack(spacing: 8) {
            regionButton(.head, yOffset: 0)
            HStack(spacing: 40) {
                regionButton(.leftShoulder, yOffset: 0)
                regionButton(.chest, yOffset: 0)
                regionButton(.rightShoulder, yOffset: 0)
            }
            HStack(spacing: 60) {
                regionButton(.leftElbow, yOffset: 0)
                regionButton(.rightElbow, yOffset: 0)
            }
            HStack(spacing: 60) {
                regionButton(.leftWrist, yOffset: 0)
                regionButton(.rightWrist, yOffset: 0)
            }
            HStack(spacing: 40) {
                regionButton(.leftHip, yOffset: 0)
                regionButton(.rightHip, yOffset: 0)
            }
            HStack(spacing: 40) {
                regionButton(.leftKnee, yOffset: 0)
                regionButton(.rightKnee, yOffset: 0)
            }
            HStack(spacing: 40) {
                regionButton(.leftAnkle, yOffset: 0)
                regionButton(.rightAnkle, yOffset: 0)
            }
        }
    }

    private var backBody: some View {
        VStack(spacing: 8) {
            regionButton(.neck, yOffset: 0)
            regionButton(.upperBack, yOffset: 0)
            regionButton(.lowerBack, yOffset: 0)
            HStack(spacing: 40) {
                regionButton(.leftHip, yOffset: 0)
                regionButton(.rightHip, yOffset: 0)
            }
            HStack(spacing: 40) {
                regionButton(.leftKnee, yOffset: 0)
                regionButton(.rightKnee, yOffset: 0)
            }
            HStack(spacing: 40) {
                regionButton(.leftAnkle, yOffset: 0)
                regionButton(.rightAnkle, yOffset: 0)
            }
        }
    }

    private func regionButton(_ region: BodyLocation.Region, yOffset: CGFloat) -> some View {
        let isSelected = selectedRegions.contains(region)
        return Button {
            if isSelected {
                selectedRegions.remove(region)
            } else {
                selectedRegions.insert(region)
            }
        } label: {
            Text(region.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? AppTheme.Colors.cream : AppTheme.Colors.navy)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.1))
                )
        }
        .offset(y: yOffset)
    }
}
