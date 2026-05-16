//
//  QuestRadarOverlayView.swift
//  Soulverse
//
//  Octagonal radar that anchors the 8-Dimensions card. Renders:
//    - an octagonal grid (the 8 wellness dimensions)
//    - per-axis lock icons sitting AT each octagon vertex (when the
//      dimension is not yet assessed)
//    - dimension labels outside the octagon, positioned per side to avoid
//      overlapping the polygon edges (top/bottom centred above/below the
//      vertex; right side outside-of-lock; left side outside-of-lock)
//    - per-axis stage dots from center → vertex when the user has a focus
//      dimension assessed
//
//  Full-card lock affordance (the dimmed scrim + centred lock icon for
//  pre-day-7 users) is layered ON TOP by EightDimensionsCardView, not here.
//

import UIKit

final class QuestRadarOverlayView: UIView {

    private enum Layout {
        static let dotsPerAxis: Int = 5
        static let dotRadius: CGFloat = 6
        /// Padding between the radar's bounds and the octagon's vertex ring.
        /// Reserves space for the axis labels + lock icons that sit OUTSIDE
        /// each vertex. Smaller value → bigger octagon. With current label
        /// font (caption1, ≈14pt) + lockIconSize=16 + labelToLockSpacing=2,
        /// the top/bottom label needs ≈24pt of headroom outside the vertex;
        /// inset=24 sits right at that boundary.
        static let radiusInset: CGFloat = 24
        static let lockIconSize: CGFloat = 16
        static let labelToLockSpacing: CGFloat = 2
        static let labelFontSize: CGFloat = 12
        /// Alpha applied to white when filling the octagon's interior.
        static let octagonFillAlpha: CGFloat = 0.2
        /// Alpha applied to the focus dim's color for stages that have NOT
        /// been reached yet. Reached stages render at full opacity.
        static let unreachedDotAlpha: CGFloat = 0.30
    }

    private static let radarOrder: [Topic] = [
        .physical,      // 0 — top
        .emotional,     // 1 — top-right
        .social,        // 2 — right
        .intellectual,  // 3 — bottom-right
        .environment,   // 4 — bottom
        .occupational,  // 5 — bottom-left
        .spiritual,     // 6 — left
        .financial      // 7 — top-left
    ]

    private var renderModel: EightDimensionsRenderModel?
    private var labelViews: [Topic: UILabel] = [:]
    private var lockIconViews: [Topic: UIImageView] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        buildAxisLabels()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(model: EightDimensionsRenderModel) {
        renderModel = model
        for (i, dim) in Topic.allCases.enumerated() {
            let label = labelViews[dim]
            label?.text = dim.localizedTitle
            label?.textColor = .themeTextSecondary

            let state = model.axes[i]
            let showLock: Bool = {
                if case .neverAssessed = state { return true }
                if case .stage1Locked = state { return true }
                return false
            }()
            lockIconViews[dim]?.isHidden = !showLock
            lockIconViews[dim]?.tintColor = dim.mainColor
        }
        setNeedsLayout()
        setNeedsDisplay()
    }

    private func buildAxisLabels() {
        for dim in Topic.allCases {
            let label = UILabel()
            label.font = .projectFont(ofSize: Layout.labelFontSize, weight: .regular)
            label.textColor = .themeTextSecondary
            label.textAlignment = .center
            addSubview(label)
            labelViews[dim] = label

            let lock = UIImageView()
            lock.image = UIImage(systemName: "lock.fill")
            lock.contentMode = .scaleAspectFit
            lock.isHidden = true
            addSubview(lock)
            lockIconViews[dim] = lock
        }
    }

    private func centerAndRadius() -> (CGPoint, CGFloat) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - Layout.radiusInset
        return (center, radius)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let (center, radius) = centerAndRadius()

        for (renderIndex, dim) in Self.radarOrder.enumerated() {
            let angle = angleForVertex(renderIndex: renderIndex)
            let vertex = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            positionLockAndLabel(at: vertex, renderIndex: renderIndex, dim: dim)
        }
    }

    /// Position the lock + label as a unit. The lock's CENTRE is always at
    /// the vertex; only the label moves around it based on which side of the
    /// octagon the vertex is on:
    /// - Top (0): label centred above the lock
    /// - Right-side (1, 2, 3): label to the right of the lock
    /// - Bottom (4): label centred below the lock
    /// - Left-side (5, 6, 7): label to the left of the lock
    private func positionLockAndLabel(at vertex: CGPoint, renderIndex: Int, dim: Topic) {
        guard let label = labelViews[dim], let lock = lockIconViews[dim] else { return }
        label.sizeToFit()
        let lblSize = label.intrinsicContentSize
        let lockSize = Layout.lockIconSize
        let spacing = Layout.labelToLockSpacing

        // Lock centre is ALWAYS at the vertex point.
        let lockOrigin = CGPoint(x: vertex.x - lockSize / 2, y: vertex.y - lockSize / 2)

        let labelOrigin: CGPoint
        switch renderIndex {
        case 0:   // Top — label centred above lock
            labelOrigin = CGPoint(x: vertex.x - lblSize.width / 2, y: lockOrigin.y - lblSize.height - spacing)
        case 4:   // Bottom — label centred below lock
            labelOrigin = CGPoint(x: vertex.x - lblSize.width / 2, y: lockOrigin.y + lockSize + spacing)
        case 1, 2, 3:   // Right-side — label to the right of lock
            labelOrigin = CGPoint(x: lockOrigin.x + lockSize + spacing, y: vertex.y - lblSize.height / 2)
        default:   // 5, 6, 7 — left-side — label to the left of lock
            labelOrigin = CGPoint(x: lockOrigin.x - spacing - lblSize.width, y: vertex.y - lblSize.height / 2)
        }

        lock.frame = CGRect(origin: lockOrigin, size: CGSize(width: lockSize, height: lockSize))
        label.frame = CGRect(origin: labelOrigin, size: lblSize)
    }

    private func angleForVertex(renderIndex: Int) -> CGFloat {
        // 12 o'clock = -π/2; rotate clockwise around the octagon.
        return -CGFloat.pi / 2 + (CGFloat(renderIndex) / CGFloat(Self.radarOrder.count)) * (2 * .pi)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let model = renderModel else { return }
        let (center, radius) = centerAndRadius()

        drawOctagonGrid(in: ctx, center: center, radius: radius)

        // Per-axis dots — iterate in renderOrder so the angle matches the
        // visual layout, then index into the canonical axes array by Topic.
        // Pass the Topic into drawAxis so focus-state dots can use its
        // `mainColor`.
        for (renderIndex, dim) in Self.radarOrder.enumerated() {
            guard let canonicalIndex = Topic.allCases.firstIndex(of: dim) else { continue }
            let state = model.axes[canonicalIndex]
            let angle = angleForVertex(renderIndex: renderIndex)
            drawAxis(in: ctx, center: center, angle: angle, radius: radius, state: state, dim: dim)
        }
    }

    private func drawOctagonGrid(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
        let path = UIBezierPath()
        for renderIndex in 0..<Self.radarOrder.count {
            let angle = angleForVertex(renderIndex: renderIndex)
            let pos = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if renderIndex == 0 { path.move(to: pos) } else { path.addLine(to: pos) }
        }
        path.close()

        // Fill interior first so the outline + per-axis dots draw on top.
        UIColor.white.withAlphaComponent(Layout.octagonFillAlpha).setFill()
        path.fill()

        // Octagon outline.
        UIColor.themeTextSecondary.withAlphaComponent(0.25).setStroke()
        ctx.setLineWidth(1)
        path.stroke()
    }

    private func drawAxis(
        in ctx: CGContext,
        center: CGPoint,
        angle: CGFloat,
        radius: CGFloat,
        state: DimensionAxisState,
        dim: Topic
    ) {
        switch state {
        case .stage1Locked, .neverAssessed:
            return  // No per-axis dots in these states.
        case .currentFocusNoSoC:
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: 0, color: dim.mainColor)
        case let .currentFocusWithSoC(stage):
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: stage, color: dim.mainColor)
        case let .previouslyFocused(stage):
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: stage, color: dim.mainColor)
        }
    }

    private func drawDotRow(
        in ctx: CGContext,
        center: CGPoint,
        angle: CGFloat,
        radius: CGFloat,
        activeStage: Int,
        color: UIColor
    ) {
        let count = Layout.dotsPerAxis
        for i in 1...count {
            let frac = CGFloat(i) / CGFloat(count)
            let pos = CGPoint(
                x: center.x + cos(angle) * radius * frac,
                y: center.y + sin(angle) * radius * frac
            )
            // Stages 1…activeStage are "reached" → full opacity.
            // Stages > activeStage have not been reached yet → 30% opacity.
            // Both are filled with the same dimension color so the row reads
            // as one chromatic gradient.
            let isReached = i <= activeStage
            let rect = CGRect(
                x: pos.x - Layout.dotRadius,
                y: pos.y - Layout.dotRadius,
                width: Layout.dotRadius * 2,
                height: Layout.dotRadius * 2
            )
            let fillColor = isReached ? color : color.withAlphaComponent(Layout.unreachedDotAlpha)
            fillColor.setFill()
            ctx.fillEllipse(in: rect)
        }
    }
}
