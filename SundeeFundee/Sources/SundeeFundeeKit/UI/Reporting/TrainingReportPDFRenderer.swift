#if canImport(UIKit)
import CoreText
import SwiftUI
import UIKit

// MARK: - TrainingReportPDFRenderer
//
// Renders a TrainingReportDocument to a paginated US Letter PDF.
//
// Deliberately not ImageRenderer-based, unlike ShareCardRenderer. A share card
// is one fixed-size image; this report is flowing text of unbounded length
// that has to break across pages. Rasterizing it would produce a picture of a
// document — no selectable or searchable text, no accessibility, and a file
// far larger than the few kilobytes this needs to be. CoreText framesetting
// gives real pagination and real text, which is what someone handing this to a
// clinician actually needs.
//
// This type makes no decisions about content. Which sections appear and what
// is withheld is settled in TrainingReportDocument, which is pure and tested.

/// Renders a `TrainingReportDocument` to a paginated US Letter PDF.
@available(iOS 18.0, *)
public enum TrainingReportPDFRenderer {
    // MARK: - Page Metrics

    /// US Letter at 72 dpi.
    public static let pageSize = CGSize(width: 612, height: 792)

    /// 0.75" margins — wide enough to survive printing without clipping.
    public static let margin: CGFloat = 54

    // MARK: - Palette
    //
    // A report is printed or read as a document, so it uses the brand's fixed
    // light-appearance tokens rather than the adaptive ones — a dark-mode
    // reader should still get a white page, not white-on-black ink.

    private static var navy: UIColor { UIColor(AppTheme.Background.navy) }
    private static var ink: UIColor { UIColor(AppTheme.Background.navy).withAlphaComponent(0.88) }
    private static var slate: UIColor { UIColor(AppTheme.Background.navy).withAlphaComponent(0.62) }

    // MARK: - Rendering

    /// Renders report content directly to PDF data.
    public static func render(
        _ content: TrainingReportContent,
        calendar: Calendar = .current
    ) -> Data {
        render(TrainingReportDocument.make(from: content, calendar: calendar))
    }

    /// Renders an already-laid-out document to PDF data.
    public static func render(_ document: TrainingReportDocument) -> Data {
        let text = attributedText(for: document)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Training Summary",
            kCGPDFContextCreator as String: "Sundee Fundee"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        return renderer.pdfData { context in
            let framesetter = CTFramesetterCreateWithAttributedString(text)
            let textBounds = CGRect(
                x: margin,
                y: margin,
                width: pageSize.width - margin * 2,
                height: pageSize.height - margin * 2
            )
            var consumed = 0

            repeat {
                context.beginPage()
                let cgContext = context.cgContext

                // Core Text draws in a bottom-left origin space; UIKit page
                // contexts are top-left. Flip so the frame lands where the
                // margins say it should.
                //
                // textBounds is expressed in the flipped space, where its y is
                // the distance from the *bottom* of the page. That happens to
                // read the same as a top inset only because the top and bottom
                // margins are equal — split `margin` into separate top and
                // bottom values and this rect has to be recomputed.
                cgContext.textMatrix = .identity
                cgContext.translateBy(x: 0, y: pageSize.height)
                cgContext.scaleBy(x: 1, y: -1)

                let path = CGPath(rect: textBounds, transform: nil)
                let frame = CTFramesetterCreateFrame(
                    framesetter,
                    CFRange(location: consumed, length: 0),
                    path,
                    nil
                )
                CTFrameDraw(frame, cgContext)

                let drawn = CTFrameGetVisibleStringRange(frame).length
                // A zero-length page means nothing more can fit — a single
                // unbreakable run taller than the page, say. Stop rather than
                // spin emitting blank pages forever.
                guard drawn > 0 else { break }
                consumed += drawn
            } while consumed < text.length
        }
    }

    // MARK: - Attributed Text

    private static func attributedText(for document: TrainingReportDocument) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for block in document.blocks {
            result.append(attributed(block))
        }
        return result
    }

    private static func attributed(_ block: TrainingReportDocument.Block) -> NSAttributedString {
        switch block {
        case .title(let text):
            return paragraph(
                text,
                font: .systemFont(ofSize: 26, weight: .bold),
                color: navy,
                spacingBefore: 0,
                spacingAfter: 2
            )

        case .subtitle(let text):
            return paragraph(
                text,
                font: .systemFont(ofSize: 12, weight: .regular),
                color: slate,
                spacingBefore: 0,
                spacingAfter: 18
            )

        case .heading(let text):
            return paragraph(
                text,
                font: .systemFont(ofSize: 15, weight: .semibold),
                color: navy,
                spacingBefore: 16,
                spacingAfter: 6
            )

        case .paragraph(let text):
            return paragraph(
                text,
                font: .systemFont(ofSize: 11, weight: .regular),
                color: ink,
                spacingBefore: 0,
                spacingAfter: 6
            )

        case .bullet(let text):
            return paragraph(
                "•  \(text)",
                font: .systemFont(ofSize: 11, weight: .regular),
                color: ink,
                spacingBefore: 0,
                spacingAfter: 5,
                headIndent: 14
            )

        case .timelineRow(let date, let summary, let note):
            let row = NSMutableAttributedString()
            row.append(paragraph(
                date,
                font: .systemFont(ofSize: 10, weight: .semibold),
                color: slate,
                spacingBefore: 6,
                spacingAfter: 1
            ))
            row.append(paragraph(
                summary,
                font: .systemFont(ofSize: 11, weight: .regular),
                color: ink,
                spacingBefore: 0,
                spacingAfter: note == nil ? 4 : 1,
                headIndent: 12,
                firstLineIndent: 12
            ))
            if let note {
                row.append(paragraph(
                    note,
                    font: .italicSystemFont(ofSize: 10),
                    color: slate,
                    spacingBefore: 0,
                    spacingAfter: 4,
                    headIndent: 12,
                    firstLineIndent: 12
                ))
            }
            return row

        case .footnote(let text):
            return paragraph(
                text,
                font: .systemFont(ofSize: 9, weight: .regular),
                color: slate,
                spacingBefore: 10,
                spacingAfter: 0
            )
        }
    }

    private static func paragraph(
        _ text: String,
        font: UIFont,
        color: UIColor,
        spacingBefore: CGFloat,
        spacingAfter: CGFloat,
        headIndent: CGFloat = 0,
        firstLineIndent: CGFloat = 0
    ) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = spacingBefore
        style.paragraphSpacing = spacingAfter
        style.lineHeightMultiple = 1.18
        style.headIndent = headIndent
        style.firstLineHeadIndent = firstLineIndent
        // Keep long clinical terms and exercise names from being hyphenated
        // mid-word in a document someone may read aloud to a patient.
        style.hyphenationFactor = 0

        return NSAttributedString(
            string: text + "\n",
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
        )
    }
}
#endif
