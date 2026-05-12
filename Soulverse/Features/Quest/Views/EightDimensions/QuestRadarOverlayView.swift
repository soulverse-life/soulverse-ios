//
//  QuestRadarOverlayView.swift
//  Soulverse
//
//  Octagonal radar that anchors the 8-Dimensions card. Renders:
//    - an octagonal grid (per spec — the 8 wellness dimensions)
//    - per-axis lock icons next to each dimension label (when neverAssessed)
//    - dimension labels around the octagon
//    - per-axis stage dots when the user has assessed the dimension
//
//  Pre-day-7 lock is layered ON TOP by EightDimensionsCardView (large lock
//  icon + scrim), not inside this view — keeps this component focused on
//  visualisation, not on lock UX.
//

import UIKit

final class QuestRadarOverlayView: UIView {

    private enum Layout {
        static let dotsPerAxis: Int = 5
        static let dotRadius: CGFloat = 3.5
        static let labelOffset: CGFloat = 18
        static let lockIconSize: CGFloat = 14
        static let labelFontSize: CGFloat = 12
    }

    private var renderModel: EightDimensionsRenderModel?
    private var labelViews: [UILabel] = []
    private var lockIconViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        buildAxisLabels()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(model: EightDimensionsRenderModel) {
        renderModel = model
        for (i, dim) in Topic.allCases.enumerated() {
            let label = labelViews[i]
            label.text = dim.localizedTitle
            label.textColor = .themeTextSecondary

            let state = model.axes[i]
            let showLock: Bool = {
                if case .neverAssessed = state { return true }
                if case .stage1Locked = state { return true }
                return false
            }()
            lockIconViews[i].isHidden = !showLock
            lockIconViews[i].tintColor = dim.mainColor
        }
        setNeedsLayout()
        setNeedsDisplay()
    }

    private func buildAxisLabels() {
        for _ in Topic.allCases {
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .themeTextSecondary
            label.textAlignment = .center
            addSubview(label)
            labelViews.append(label)

            let lock = UIImageView()
            lock.image = UIImage(systemName: "lock.fill")
            lock.contentMode = .scaleAspectFit
            lock.isHidden = true
            addSubview(lock)
            lockIconViews.append(lock)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 40   // room for labels
        let labelRadius = radius + Layout.labelOffset

        let count = Topic.allCases.count
        for (i, _) in Topic.allCases.enumerated() {
            // 12 o'clock = -π/2; rotate clockwise around the octagon.
            let angle = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(count)) * (2 * .pi)
            let labelCenter = CGPoint(
                x: center.x + cos(angle) * labelRadius,
                y: center.y + sin(angle) * labelRadius
            )
            let label = labelViews[i]
            label.sizeToFit()
            let lblSize = label.intrinsicContentSize
            label.frame = CGRect(
                x: labelCenter.x - lblSize.width / 2,
                y: labelCenter.y - lblSize.height / 2,
                width: lblSize.width,
                height: lblSize.height
            )
            // Lock icon sits just to the right of the label (small badge).
            let lock = lockIconViews[i]
            lock.frame = CGRect(
                x: label.frame.maxX + 4,
                y: label.frame.midY - Layout.lockIconSize / 2,
                width: Layout.lockIconSize,
                height: Layout.lockIconSize
            )
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let model = renderModel else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 40

        drawOctagonGrid(in: ctx, center: center, radius: radius)

        // Per-axis dots only for axes with stage data.
        let axisCount = model.axes.count
        for (i, state) in model.axes.enumerated() {
            let angle = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(axisCount)) * (2 * .pi)
            drawAxis(in: ctx, center: center, angle: angle, radius: radius, state: state)
        }
    }

    private func drawOctagonGrid(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
        let count = Topic.allCases.count
        UIColor.themeTextSecondary.withAlphaComponent(0.25).setStroke()
        ctx.setLineWidth(1)
        let path = UIBezierPath()
        for i in 0..<count {
            let angle = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(count)) * (2 * .pi)
            let pos = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 { path.move(to: pos) } else { path.addLine(to: pos) }
        }
        path.close()
        path.stroke()
    }

    private func drawAxis(
        in ctx: CGContext,
        center: CGPoint,
        angle: CGFloat,
        radius: CGFloat,
        state: DimensionAxisState
    ) {
        switch state {
        case .stage1Locked, .neverAssessed:
            return  // No per-axis dots in these states.
        case .currentFocusNoSoC:
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: 0)
        case let .currentFocusWithSoC(stage):
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: stage)
        case let .previouslyFocused(stage):
            drawDotRow(in: ctx, center: center, angle: angle, radius: radius, activeStage: stage)
        }
    }

    private func drawDotRow(
        in ctx: CGContext,
        center: CGPoint,
        angle: CGFloat,
        radius: CGFloat,
        activeStage: Int
    ) {
        let count = Layout.dotsPerAxis
        for i in 1...count {
            let frac = CGFloat(i) / CGFloat(count)
            let pos = CGPoint(
                x: center.x + cos(angle) * radius * frac,
                y: center.y + sin(angle) * radius * frac
            )
            let isActive = (i == activeStage)
            let rect = CGRect(
                x: pos.x - Layout.dotRadius,
                y: pos.y - Layout.dotRadius,
                width: Layout.dotRadius * 2,
                height: Layout.dotRadius * 2
            )
            if isActive {
                UIColor.themeButtonPrimaryBackground.setFill()
                ctx.fillEllipse(in: rect)
            } else {
                UIColor.themeTextSecondary.setStroke()
                ctx.setLineWidth(1)
                ctx.strokeEllipse(in: rect)
            }
        }
    }
}

// (Per-dimension colors live on Topic.mainColor in Shared/Models/Topic.swift —
//  used above to tint the per-axis lock icons.)
