import UIKit

class SpiralView: UIView {

    // MARK: - Layers
    private let spiralPathLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let progressLayer = CAShapeLayer()
    private let headGlowLayer = CALayer()

    // MARK: - Properties
    private var spiralPath: UIBezierPath?
    private var points: [CGPoint] = []

    // Configuration
    var visualConfig = SpiralVisualConfig()
    var actionConfig = SpiralActionConfig()

    private var totalPathLength: CGFloat = 0.0
    private var cumulativeLengths: [CGFloat] = []
    private var lastProgress: CGFloat = 0.0
    private var lastIsInhale: Bool = true
    private var lastClosestIndex: Int = 0

    var pathLength: CGFloat {
        return totalPathLength
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        if spiralPath == nil || bounds.width != spiralPath?.bounds.width {
            generateSpiralPath()
            // Re-apply progress after path generation to ensure offset is calculated correctly
            setProgress(lastProgress, isInhale: lastIsInhale)
        }
    }

    private func setupLayers() {
        // Base track layer (dimmed)
        spiralPathLayer.fillColor = UIColor.clear.cgColor
        spiralPathLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
        spiralPathLayer.lineWidth = visualConfig.lineWidth
        spiralPathLayer.lineCap = .round
        layer.addSublayer(spiralPathLayer)

        // Gradient Layer (holds the colors)
        gradientLayer.colors = [
            UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0).cgColor,  // Purple
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,  // Blue
            UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0).cgColor,  // Green
            UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0).cgColor,  // Orange
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.type = .conic
        layer.addSublayer(gradientLayer)

        // Progress Layer (Mask for the gradient)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.black.cgColor  // Color doesn't matter for mask
        progressLayer.lineWidth = visualConfig.lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.0

        gradientLayer.mask = progressLayer

        // Head Glow Layer
        headGlowLayer.backgroundColor = UIColor.white.cgColor
        headGlowLayer.bounds = CGRect(
            x: 0, y: 0, width: visualConfig.headSize, height: visualConfig.headSize)
        headGlowLayer.cornerRadius = visualConfig.headSize / 2.0
        headGlowLayer.shadowColor = UIColor.white.cgColor
        headGlowLayer.shadowOpacity = 1.0
        headGlowLayer.shadowOffset = .zero
        headGlowLayer.shadowRadius = 10
        headGlowLayer.opacity = 0.0
        layer.addSublayer(headGlowLayer)
    }

    private func generateSpiralPath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()
        points = []
        cumulativeLengths = []
        totalPathLength = 0.0

        // Dynamic sizing
        let padding: CGFloat = 20.0
        let maxRadius = min(bounds.width, bounds.height) / 2.0 - padding

        // Archimedean spiral: r = a + b * theta
        // Max r = startRadius + b * totalAngle
        // b = (Max r - startRadius) / totalAngle
        let totalAngle = visualConfig.rotations * 2 * .pi
        let b = (maxRadius - visualConfig.startRadius) / totalAngle

        // We want to draw enough points to make it smooth
        let step = 0.1  // Radian step

        var firstPoint = true
        var lastPoint: CGPoint?

        for theta in stride(from: 0, through: totalAngle, by: step) {
            let radius = visualConfig.startRadius + b * theta
            let x = center.x + radius * cos(theta)
            let y = center.y + radius * sin(theta)
            let point = CGPoint(x: x, y: y)

            if firstPoint {
                path.move(to: point)
                firstPoint = false
                cumulativeLengths.append(0.0)
            } else {
                path.addLine(to: point)
                if let last = lastPoint {
                    let dist = hypot(point.x - last.x, point.y - last.y)
                    totalPathLength += dist
                }
                cumulativeLengths.append(totalPathLength)
            }
            points.append(point)
            lastPoint = point
        }

        self.spiralPath = path
        spiralPathLayer.path = path.cgPath
        progressLayer.path = path.cgPath

        // Position head at start
        if let start = points.first {
            headGlowLayer.position = start
        }
    }

    // MARK: - Public Methods

    func setProgress(_ progress: CGFloat, isInhale: Bool = true) {
        // Store state for re-layout
        lastProgress = progress
        lastIsInhale = isInhale

        // Clamp progress
        let clampedProgress = max(0.0, min(1.0, progress))

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if isInhale {
            // Inhale: Fill from center
            // Apply constant distance offset
            // Convert distance offset to progress percentage
            let progressOffset =
                totalPathLength > 0 ? (visualConfig.colorDistanceOffset / totalPathLength) : 0.0
            let drawProgress = max(0.0, min(1.0, clampedProgress + progressOffset))

            progressLayer.strokeStart = 0.0
            progressLayer.strokeEnd = drawProgress
        } else {
            // Exhale: Fill from outside (end) back to center (start)
            // Apply offset to strokeStart to ensure color follows "right behind" the finger (closing the gap)
            // We want strokeStart to be slightly closer to 0 than the current position
            let progressOffset =
                totalPathLength > 0 ? (visualConfig.colorDistanceOffset / totalPathLength) : 0.0

            // clampedProgress is (1.0 - currentPosition)
            // So (1.0 - clampedProgress) is currentPosition
            // We want start to be currentPosition - offset
            let drawStart = max(0.0, min(1.0, (1.0 - clampedProgress) - progressOffset))

            progressLayer.strokeEnd = 1.0
            progressLayer.strokeStart = drawStart
        }

        // Update head position
        if !points.isEmpty && !cumulativeLengths.isEmpty {
            // For inhale: 0 -> 1
            // For exhale: 1 -> 0 (we are tracing back)
            let effectiveProgress = isInhale ? clampedProgress : (1.0 - clampedProgress)
            let targetLength = totalPathLength * effectiveProgress

            // Find index where cumulativeLength is closest to targetLength
            // Binary search or linear scan (linear is fine for < 1000 points)
            var closestIndex = 0
            var minDiff = CGFloat.greatestFiniteMagnitude

            for (i, length) in cumulativeLengths.enumerated() {
                let diff = abs(length - targetLength)
                if diff < minDiff {
                    minDiff = diff
                    closestIndex = i
                } else {
                    // Since cumulativeLengths is sorted, if diff starts increasing, we found closest
                    break
                }
            }

            if closestIndex >= 0 && closestIndex < points.count {
                headGlowLayer.position = points[closestIndex]
            }
        }
        CATransaction.commit()
    }

    func setOpacity(_ opacity: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.opacity = opacity
        headGlowLayer.opacity = opacity
        CATransaction.commit()
    }

    func resetForExhale() {
        progressLayer.removeAnimation(forKey: "fade")
        progressLayer.opacity = 1.0
        progressLayer.strokeEnd = 1.0

        // Apply offset to strokeStart so it leads slightly inward
        let progressOffset =
            totalPathLength > 0 ? (visualConfig.colorDistanceOffset / totalPathLength) : 0.0
        // Start at 1.0 (end), move inward by offset
        let startProgress = max(0.0, 1.0 - progressOffset)
        progressLayer.strokeStart = startProgress

        // Head at end
        if let last = points.last {
            headGlowLayer.position = last
        }
        headGlowLayer.opacity = 1.0
    }

    func getHeadPosition() -> CGPoint {
        return headGlowLayer.position
    }

    func setHeadGlow(visible: Bool) {
        let opacity: Float = visible ? 1.0 : 0.0
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = headGlowLayer.presentation()?.opacity
        animation.toValue = opacity
        animation.duration = 0.3
        headGlowLayer.opacity = opacity
        headGlowLayer.add(animation, forKey: "fade")
    }

    func startHoldPulse() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")

        // Cycle: Up -> Pause -> Down
        // Durations from config
        let totalDuration = actionConfig.holdCycleDuration
        let upDuration = actionConfig.holdCycleUpDuration
        let pauseDuration = actionConfig.holdCyclePauseDuration
        // Down duration is remaining

        // Key times (normalized 0..1)
        let t1 = NSNumber(value: upDuration / totalDuration)
        let t2 = NSNumber(value: (upDuration + pauseDuration) / totalDuration)
        let t3 = NSNumber(value: 1.0)

        // Values: 1.0 -> 3.0 -> 3.0 -> 1.0
        animation.values = [1.0, 3.0, 3.0, 1.0]
        animation.keyTimes = [0.0, t1, t2, t3]

        // EaseOut for the scaling segments
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),  // Up
            CAMediaTimingFunction(name: .linear),  // Pause
            CAMediaTimingFunction(name: .easeOut),  // Down
        ]

        animation.duration = totalDuration
        animation.repeatCount = .infinity

        headGlowLayer.add(animation, forKey: "holdPulse")
    }

    func stopHoldPulse() {
        headGlowLayer.removeAnimation(forKey: "holdPulse")
        // Reset to identity
        headGlowLayer.transform = CATransform3DIdentity
    }

    func pulseHead() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.5
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        headGlowLayer.add(animation, forKey: "pulse")
    }

    func stopPulse() {
        headGlowLayer.removeAnimation(forKey: "pulse")
        headGlowLayer.transform = CATransform3DIdentity
    }

    // Helper to find closest point on spiral to a given point
    // Returns (progress, distance)
    func closestProgress(to point: CGPoint) -> (CGFloat, CGFloat) {
        guard !points.isEmpty, !cumulativeLengths.isEmpty else {
            return (0, CGFloat.greatestFiniteMagnitude)
        }

        var minDistance = CGFloat.greatestFiniteMagnitude
        var closestIndex = 0

        // Local search optimization
        // Search window size (e.g., +/- 50 points)
        let window = 50
        let start = max(0, lastClosestIndex - window)
        let end = min(points.count - 1, lastClosestIndex + window)

        // First check local window
        for i in start...end {
            let p = points[i]
            let distance = hypot(p.x - point.x, p.y - point.y)
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }

        // If the user jumped too far (minDistance is still large, e.g. > 50),
        // or if we want to be safe, we could do a full scan.
        // But for dragging, local search is usually sufficient.
        // Let's do a full scan ONLY if the local best is "too far" (e.g. > 100 points)
        // which implies a jump or fast movement outside the window.
        if minDistance > 100.0 {
            minDistance = CGFloat.greatestFiniteMagnitude
            for (index, p) in points.enumerated() {
                let distance = hypot(p.x - point.x, p.y - point.y)
                if distance < minDistance {
                    minDistance = distance
                    closestIndex = index
                }
            }
        }

        lastClosestIndex = closestIndex

        // Return length-based progress instead of index-based
        let progress = totalPathLength > 0 ? cumulativeLengths[closestIndex] / totalPathLength : 0
        return (progress, minDistance)
    }

    func getPoint(at progress: CGFloat) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let index = Int(CGFloat(points.count - 1) * progress)
        if index >= 0 && index < points.count {
            return points[index]
        }
        return nil
    }
}
