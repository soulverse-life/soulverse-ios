//
//  QuestRadarOverlayView.swift
//  Soulverse
//
//  Lightweight overlay rendered on top of the radar chart. Per-axis dot row
//  (1–5 outline + solid for active stage), lock icon for never-assessed axes,
//  EmoPet image at center.
//
//  Drawn with CALayer subnodes — no DGCharts dependency.
//

import UIKit

final class QuestRadarOverlayView: UIView {

    private enum Layout {
        static let dotsPerAxis: Int = 5
        static let dotRadius: CGFloat = 3.5
        static let centerImageSize: CGFloat = 56
    }

    private let centerImageView = UIImageView()
    private var renderModel: EightDimensionsRenderModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        centerImageView.image = UIImage(named: "EMOPet/basic_first_level")
        centerImageView.contentMode = .scaleAspectFit
        addSubview(centerImageView)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(model: EightDimensionsRenderModel) {
        renderModel = model
        setNeedsLayout()
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerImageView.frame = CGRect(
            x: bounds.midX - Layout.centerImageSize / 2,
            y: bounds.midY - Layout.centerImageSize / 2,
            width: Layout.centerImageSize,
            height: Layout.centerImageSize
        )
        centerImageView.isHidden = renderModel?.isCardLocked == false
            && renderModel?.axes.contains { state in
                if case .currentFocusWithSoC = state { return true }
                if case .currentFocusNoSoC = state { return true }
                return false
            } == true
        // Center icon hidden when there's an active focus dim drawing dots,
        // visible during stage-1 lock affordance otherwise.
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let model = renderModel else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 12
        let axisCount = model.axes.count

        for (i, state) in model.axes.enumerated() {
            // Compute axis angle (12 o'clock = -π/2, clockwise).
            let angle = -CGFloat.pi / 2 + (CGFloat(i) / CGFloat(axisCount)) * (2 * .pi)
            drawAxis(in: ctx, center: center, angle: angle, radius: radius, state: state)
        }
    }

    private func drawAxis(
        in ctx: CGContext,
        center: CGPoint,
        angle: CGFloat,
        radius: CGFloat,
        state: DimensionAxisState
    ) {
        switch state {
        case .stage1Locked:
            return  // No dots/locks during stage 1 — center icon carries the affordance.
        case .neverAssessed:
            // Lock at outermost position.
            let pos = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            UIColor.themeTextSecondary.withAlphaComponent(0.4).setFill()
            ctx.fillEllipse(in: CGRect(
                x: pos.x - Layout.dotRadius,
                y: pos.y - Layout.dotRadius,
                width: Layout.dotRadius * 2,
                height: Layout.dotRadius * 2
            ))
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
            if isActive {
                UIColor.themeButtonPrimaryBackground.setFill()
                ctx.fillEllipse(in: CGRect(
                    x: pos.x - Layout.dotRadius,
                    y: pos.y - Layout.dotRadius,
                    width: Layout.dotRadius * 2,
                    height: Layout.dotRadius * 2
                ))
            } else {
                UIColor.themeTextSecondary.setStroke()
                ctx.setLineWidth(1)
                ctx.strokeEllipse(in: CGRect(
                    x: pos.x - Layout.dotRadius,
                    y: pos.y - Layout.dotRadius,
                    width: Layout.dotRadius * 2,
                    height: Layout.dotRadius * 2
                ))
            }
        }
    }
}
