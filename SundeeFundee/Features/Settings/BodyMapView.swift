import SwiftUI

/// Interactive body diagram using a real anatomical illustration.
/// Hotspot rings highlight each tappable region; orange when selected.
///
/// Image credit: stern_in_nudelsuppe via Pixabay
/// https://pixabay.com/vectors/male-body-man-human-anatomy-1859518/
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

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .fill(AppTheme.Colors.cream)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                .stroke(AppTheme.Colors.navy.opacity(0.12), lineWidth: 1)
                        )

                    // Body diagram — the white image background is multiplied with
                    // cream so it disappears; the navy outlines are preserved.
                    BodyDiagramImage(showingFront: showingFront)
                        .frame(width: w, height: h)
                        .colorMultiply(AppTheme.Colors.cream)

                    // Tappable region hotspots
                    ForEach(visibleRegions, id: \.self) { region in
                        let pos = regionPosition(region, width: w, height: h)
                        RegionHotspot(
                            region: region,
                            isSelected: selectedRegions.contains(region),
                            position: pos
                        ) {
                            if selectedRegions.contains(region) {
                                selectedRegions.remove(region)
                            } else {
                                selectedRegions.insert(region)
                            }
                        }
                    }
                }
            }
            .frame(height: 420)
            .animation(.easeInOut(duration: 0.25), value: showingFront)

            // Attribution
            Text("Illustration by stern_in_nudelsuppe / Pixabay")
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))

            // Selected regions summary
            if !selectedRegions.isEmpty {
                Text(selectedRegions.map(\.displayName).sorted().joined(separator: " · "))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.sm)
            }
        }
    }

    // MARK: - Regions visible per view

    private var visibleRegions: [BodyLocation.Region] {
        if showingFront {
            return [.head, .leftShoulder, .rightShoulder, .chest,
                    .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                    .leftHip, .rightHip, .leftKnee, .rightKnee,
                    .leftAnkle, .rightAnkle]
        } else {
            return [.head, .neck, .upperBack, .lowerBack,
                    .leftShoulder, .rightShoulder,
                    .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                    .leftHip, .rightHip, .leftKnee, .rightKnee,
                    .leftAnkle, .rightAnkle]
        }
    }

    // MARK: - Hotspot positions
    //
    // Source image: 640×640px. Front figure: left half. Back figure: right half.
    // Crop window used in BodyDiagramImage:
    //   Front: x=50..330 (cropW=280), y=15..620 (cropH=605)
    //   Back:  x=320..580 (cropW=260), y=15..620 (cropH=605)
    //
    // Pixel positions measured from actual image data:
    //   px = (srcX - cropStartX) / cropW  → 0..1 within the crop
    //   py = (srcY - cropY) / cropH       → 0..1 within the crop
    //
    // NOTE: figure faces viewer → figure's LEFT arm appears on screen RIGHT (higher px).
    //
    // Front figure pixel centers (srcX, srcY):
    //   Head:           176, 40   → px=0.450, py=0.041
    //   Chest:          176,145   → px=0.450, py=0.215
    //   L.Shoulder:     127,125   → px=0.275, py=0.182
    //   R.Shoulder:     227,125   → px=0.632, py=0.182
    //   L.Elbow:        117,220   → px=0.239, py=0.339
    //   R.Elbow:        236,220   → px=0.664, py=0.339
    //   L.Wrist:         94,295   → px=0.157, py=0.463
    //   R.Wrist:        287,295   → px=0.846, py=0.463
    //   L.Hip:          150,338   → px=0.357, py=0.534
    //   R.Hip:          202,338   → px=0.543, py=0.534
    //   L.Knee:         135,450   → px=0.304, py=0.719
    //   R.Knee:         218,450   → px=0.600, py=0.719
    //   L.Ankle:        137,560   → px=0.311, py=0.901
    //   R.Ankle:        216,560   → px=0.593, py=0.901
    //
    // Back figure pixel centers (srcX, srcY):
    //   Head:           434, 40   → px=0.438, py=0.041
    //   Neck:           434, 90   → px=0.438, py=0.124
    //   UpperBack:      435,148   → px=0.442, py=0.220
    //   LowerBack:      434,235   → px=0.438, py=0.364
    //   L.Shoulder:     388,120   → px=0.262, py=0.174
    //   R.Shoulder:     490,120   → px=0.654, py=0.174
    //   L.Elbow:        373,225   → px=0.204, py=0.347
    //   R.Elbow:        496,225   → px=0.677, py=0.347
    //   L.Wrist:        350,300   → px=0.115, py=0.471
    //   R.Wrist:        530,300   → px=0.808, py=0.471
    //   L.Hip:          404,350   → px=0.323, py=0.554
    //   R.Hip:          465,350   → px=0.558, py=0.554
    //   L.Knee:         392,450   → px=0.277, py=0.719
    //   R.Knee:         477,450   → px=0.604, py=0.719
    //   L.Ankle:        394,560   → px=0.285, py=0.901
    //   R.Ankle:        475,560   → px=0.596, py=0.901

    // swiftlint:disable cyclomatic_complexity
    private func regionPosition(_ region: BodyLocation.Region, width: CGFloat, height: CGFloat) -> CGPoint {
        // "left" / "right" are from the figure's anatomical perspective.
        // The figure faces the viewer, so figure's LEFT appears on screen RIGHT (higher x).
        // px values are normalized within the crop window (0..1).
        // All coordinates measured from the actual 640×640 pixel image.
        let (px, py): (CGFloat, CGFloat) = {
            switch region {
            case .head:
                return showingFront ? (0.450, 0.041) : (0.438, 0.041)
            case .neck:
                return (0.438, 0.124)   // back view only
            case .chest:
                return (0.450, 0.215)
            case .upperBack:
                return (0.442, 0.220)
            case .lowerBack:
                return (0.438, 0.364)
            // leftShoulder = figure's anatomical left = screen RIGHT (higher px)
            case .leftShoulder:
                return showingFront ? (0.655, 0.200) : (0.654, 0.174)
            // rightShoulder = figure's anatomical right = screen LEFT (lower px)
            case .rightShoulder:
                return showingFront ? (0.166, 0.200) : (0.262, 0.174)
            case .leftElbow:
                return showingFront ? (0.664, 0.339) : (0.677, 0.347)
            case .rightElbow:
                return showingFront ? (0.239, 0.339) : (0.204, 0.347)
            case .leftWrist:
                return showingFront ? (0.846, 0.463) : (0.808, 0.471)
            case .rightWrist:
                return showingFront ? (0.157, 0.463) : (0.115, 0.471)
            // leftHip = figure's anatomical left = screen RIGHT
            case .leftHip:
                return showingFront ? (0.543, 0.534) : (0.558, 0.554)
            case .rightHip:
                return showingFront ? (0.357, 0.534) : (0.323, 0.554)
            case .leftKnee:
                return showingFront ? (0.600, 0.719) : (0.604, 0.719)
            case .rightKnee:
                return showingFront ? (0.304, 0.719) : (0.277, 0.719)
            case .leftAnkle:
                return showingFront ? (0.593, 0.901) : (0.596, 0.901)
            case .rightAnkle:
                return showingFront ? (0.311, 0.901) : (0.285, 0.901)
            }
        }()
        // Map normalized crop coords → canvas pixel position.
        // Use the per-view crop width so hotspots match the rendered image exactly.
        let cropW = showingFront ? BodyDiagramImage.frontCropW : BodyDiagramImage.backCropW
        let scaleH = height / BodyDiagramImage.cropH
        let scaleW = width / cropW
        let scale = min(scaleH, scaleW)
        let scaledW = cropW * scale
        let scaledH = BodyDiagramImage.cropH * scale
        let xPad = (width - scaledW) / 2
        let yPad = max((height - scaledH) / 2, 4)
        return CGPoint(x: xPad + px * scaledW, y: yPad + py * scaledH)
    }
    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Body Diagram Image

private struct BodyDiagramImage: View {
    let showingFront: Bool

    private let imgW: CGFloat = 640
    private let imgH: CGFloat = 640

    // Crop window shared with hotspot position math.
    // Front figure: x=50..330 (w=280). Back figure: x=320..580 (w=260).
    // Both figures span y=15..620 (h=605).
    static let cropH: CGFloat = 605
    static let frontCropW: CGFloat = 280
    static let backCropW: CGFloat = 260
    static var cropW: CGFloat { 280 }   // kept for layout sizing; use the wider front crop
    private var cropX: CGFloat { showingFront ? 50 : 320 }
    private var thisCropW: CGFloat { showingFront ? Self.frontCropW : Self.backCropW }
    private let cropY: CGFloat = 15

    var body: some View {
        GeometryReader { geo in
            let canvasW = geo.size.width
            let canvasH = geo.size.height
            let scaleH = canvasH / Self.cropH
            let scaleW = canvasW / thisCropW
            let scale = min(scaleH, scaleW)
            let scaledW = thisCropW * scale
            let scaledH = Self.cropH * scale
            let xPad = (canvasW - scaledW) / 2
            let yPad = max((canvasH - scaledH) / 2, 4)

            ZStack {
                Image("body_diagram")
                    .resizable()
                    .frame(width: imgW * scale, height: imgH * scale)
                    .offset(x: -(cropX * scale), y: -(cropY * scale))
            }
            .frame(width: scaledW, height: scaledH, alignment: .topLeading)
            .clipped()
            .offset(x: xPad, y: yPad)
        }
    }
}

// MARK: - Region Hotspot
// Rendered as a subtle zone indicator: a thin dashed ring with a name tag.
// Selected state: filled orange zone + solid ring + white label.
// Unselected state: faint dashed ring only — nearly invisible, non-intrusive.

private struct RegionHotspot: View {
    let region: BodyLocation.Region
    let isSelected: Bool
    let position: CGPoint
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                // Zone ring
                Ellipse()
                    .fill(isSelected
                          ? AppTheme.Colors.accentOrange.opacity(0.22)
                          : Color.clear)
                    .overlay(
                        Ellipse()
                            .strokeBorder(
                                isSelected
                                    ? AppTheme.Colors.accentOrange
                                    : AppTheme.Colors.navy.opacity(0.28),
                                style: StrokeStyle(
                                    lineWidth: isSelected ? 1.5 : 1,
                                    dash: isSelected ? [] : [4, 3]
                                )
                            )
                    )
                    .frame(width: zoneW, height: zoneH)
                    .contentShape(Ellipse())
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isSelected)

                // Name tag — shown only when selected, floats just above the zone
                if isSelected, let label = regionLabel {
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(AppTheme.Colors.accentOrange)
                        )
                        .offset(y: -(zoneH / 2 + 10))
                        .fixedSize()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .position(position)
        .accessibilityLabel(region.displayName)
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Ellipse size — roughly proportional to the anatomical area
    private var zoneW: CGFloat {
        switch region {
        case .head:                          return 32
        case .chest, .upperBack:             return 34
        case .lowerBack:                     return 34
        case .leftShoulder, .rightShoulder:  return 26
        case .leftHip, .rightHip:            return 26
        case .leftKnee, .rightKnee:          return 24
        case .leftElbow, .rightElbow:        return 20
        case .leftAnkle, .rightAnkle:        return 18
        case .leftWrist, .rightWrist:        return 18
        case .neck:                          return 22
        }
    }

    private var zoneH: CGFloat {
        switch region {
        case .head:                          return 34
        case .chest, .upperBack:             return 28
        case .lowerBack:                     return 28
        case .leftShoulder, .rightShoulder:  return 22
        case .leftHip, .rightHip:            return 22
        case .leftKnee, .rightKnee:          return 26
        case .leftElbow, .rightElbow:        return 20
        case .leftAnkle, .rightAnkle:        return 20
        case .leftWrist, .rightWrist:        return 16
        case .neck:                          return 18
        }
    }

    private var regionLabel: String? {
        switch region {
        case .head:          return "Head"
        case .neck:          return "Neck"
        case .chest:         return "Chest"
        case .upperBack:     return "Upper Back"
        case .lowerBack:     return "Lower Back"
        case .leftShoulder:  return "L. Shoulder"
        case .rightShoulder: return "R. Shoulder"
        case .leftElbow:     return "L. Elbow"
        case .rightElbow:    return "R. Elbow"
        case .leftWrist:     return "L. Wrist"
        case .rightWrist:    return "R. Wrist"
        case .leftHip:       return "L. Hip"
        case .rightHip:      return "R. Hip"
        case .leftKnee:      return "L. Knee"
        case .rightKnee:     return "R. Knee"
        case .leftAnkle:     return "L. Ankle"
        case .rightAnkle:    return "R. Ankle"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Front") {
    @Previewable @State var regions: Set<BodyLocation.Region> = [.leftKnee, .chest, .leftShoulder]
    ScrollView {
        BodyMapView(selectedRegions: $regions)
            .padding()
    }
    .background(AppTheme.Colors.cream)
}

#Preview("Back") {
    @Previewable @State var regions: Set<BodyLocation.Region> = [.lowerBack, .neck]
    ScrollView {
        BodyMapView(selectedRegions: $regions)
            .padding()
    }
    .background(AppTheme.Colors.cream)
}
#endif
