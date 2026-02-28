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
    // Source image: 640×480px. Front figure: left half. Back figure: right half.
    // Crop window used in BodyDiagramImage:
    //   Front: x=55..297 (cropW=242), y=10..478 (cropH=468)
    //   Back:  x=348..590 (cropW=242), y=10..478 (cropH=468)
    //
    // Pixel measurements from the source image (front/back figure coords):
    //   px = (srcX - cropStartX) / cropW  → 0..1 within the crop
    //   py = (srcY - cropY) / cropH       → 0..1 within the crop
    //
    // Front figure approximate source pixel centers:
    //   Head:           161, 38   → px=0.438, py=0.060
    //   Neck:           161, 78   → px=0.438, py=0.145
    //   Chest:          161,135   → px=0.438, py=0.267
    //   L.Shoulder:     111,115   → px=0.231, py=0.224
    //   R.Shoulder:     210,115   → px=0.640, py=0.224  (mirrored: 1-0.640=0.360 from right)
    //   L.Elbow:         84,185   → px=0.120, py=0.374
    //   R.Elbow:        237,185   → px=0.752, py=0.374
    //   L.Wrist:         67,248   → px=0.050, py=0.509
    //   R.Wrist:        255,248   → px=0.826, py=0.509
    //   L.Hip:          140,260   → px=0.351, py=0.534
    //   R.Hip:          182,260   → px=0.524, py=0.534
    //   L.Knee:         133,356   → px=0.322, py=0.739
    //   R.Knee:         189,356   → px=0.554, py=0.739
    //   L.Ankle:        128,440   → px=0.302, py=0.919
    //   R.Ankle:        194,440   → px=0.574, py=0.919
    //
    // Back figure approximate source pixel centers (offset by 348 for cropX):
    //   Head:           479, 38   → px=(479-348)/242=0.541, py=0.060
    //   Neck:           479, 78   → px=0.541, py=0.145
    //   UpperBack:      479,130   → px=0.541, py=0.256
    //   LowerBack:      479,200   → px=0.541, py=0.406
    //   L.Shoulder:     432,115   → px=(432-348)/242=0.347, py=0.224
    //   R.Shoulder:     526,115   → px=(526-348)/242=0.736, py=0.224
    //   L.Elbow:        408,185   → px=0.248, py=0.374
    //   R.Elbow:        550,185   → px=0.835, py=0.374
    //   L.Wrist:        392,248   → px=0.182, py=0.509
    //   R.Wrist:        566,248   → px=0.901, py=0.509
    //   L.Hip:          458,260   → px=0.455, py=0.534
    //   R.Hip:          500,260   → px=0.628, py=0.534
    //   L.Knee:         452,356   → px=0.430, py=0.739
    //   R.Knee:         506,356   → px=0.653, py=0.739
    //   L.Ankle:        449,440   → px=0.417, py=0.919
    //   R.Ankle:        509,440   → px=0.665, py=0.919

    // swiftlint:disable cyclomatic_complexity
    private func regionPosition(_ region: BodyLocation.Region, width: CGFloat, height: CGFloat) -> CGPoint {
        let (px, py): (CGFloat, CGFloat) = {
            switch region {
            // --- Front view ---
            case .head:           return (0.438, 0.060)
            case .chest:          return (0.438, 0.267)
            case .leftShoulder:   return (0.231, 0.224)
            case .rightShoulder:  return (0.645, 0.224)
            case .leftElbow:      return (0.120, 0.374)
            case .rightElbow:     return (0.752, 0.374)
            case .leftWrist:      return (0.050, 0.509)
            case .rightWrist:     return (0.826, 0.509)
            case .leftHip:        return (0.351, 0.534)
            case .rightHip:       return (0.524, 0.534)
            case .leftKnee:       return (0.322, 0.739)
            case .rightKnee:      return (0.554, 0.739)
            case .leftAnkle:      return (0.302, 0.919)
            case .rightAnkle:     return (0.574, 0.919)
            // --- Back-only ---
            case .neck:           return (0.541, 0.145)
            case .upperBack:      return (0.541, 0.256)
            case .lowerBack:      return (0.541, 0.406)
            }
        }()
        // Map normalized crop coords → canvas pixel position
        let scaleH = height / BodyDiagramImage.cropH
        let scaleW = width / BodyDiagramImage.cropW * 0.92
        let scale = min(scaleH, scaleW)
        let scaledW = BodyDiagramImage.cropW * scale
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
    private let imgH: CGFloat = 480

    // Crop window shared with hotspot position math
    static let cropH: CGFloat = 468
    static let cropW: CGFloat = 242
    private var cropX: CGFloat { showingFront ? 55 : 348 }
    private let cropY: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let canvasW = geo.size.width
            let canvasH = geo.size.height
            let scaleH = canvasH / Self.cropH
            let scaleW = canvasW / Self.cropW * 0.92
            let scale = min(scaleH, scaleW)
            let scaledW = Self.cropW * scale
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
        .position(position)
    }

    // Ellipse size — roughly proportional to the anatomical area
    private var zoneW: CGFloat {
        switch region {
        case .head:                          return 36
        case .chest, .upperBack:             return 46
        case .lowerBack:                     return 42
        case .leftShoulder, .rightShoulder:  return 28
        case .leftHip, .rightHip:            return 28
        case .leftKnee, .rightKnee:          return 26
        case .leftElbow, .rightElbow:        return 22
        case .leftAnkle, .rightAnkle:        return 20
        case .leftWrist, .rightWrist:        return 20
        case .neck:                          return 24
        }
    }

    private var zoneH: CGFloat {
        switch region {
        case .head:                          return 40
        case .chest, .upperBack:             return 36
        case .lowerBack:                     return 30
        case .leftShoulder, .rightShoulder:  return 24
        case .leftHip, .rightHip:            return 24
        case .leftKnee, .rightKnee:          return 28
        case .leftElbow, .rightElbow:        return 22
        case .leftAnkle, .rightAnkle:        return 22
        case .leftWrist, .rightWrist:        return 18
        case .neck:                          return 20
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
