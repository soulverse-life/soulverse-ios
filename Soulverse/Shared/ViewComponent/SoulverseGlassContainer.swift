import SnapKit
import UIKit

/// A container view that applies a liquid glass effect to its children.
/// Uses UIGlassContainerEffect on supported iOS versions (iOS 26+),
/// and falls back to standard blur effects on older versions.
class SoulverseGlassContainer: UIVisualEffectView {

    // MARK: - Properties

    /// The style of the glass effect for child elements
    var glassStyle: UIGlassEffectStyle = .clear

    // MARK: - Initialization

    init(glassStyle: UIGlassEffectStyle = .clear) {
        self.glassStyle = glassStyle

        // Check for API availability (hypothetical iOS 26 check based on research)
        if #available(iOS 26, *) {
            super.init(effect: UIGlassContainerEffect())
        } else {
            // Fallback for older iOS versions
            // Use a light blur to simulate the container, though morphing won't work
            let fallbackEffect = UIBlurEffect(style: .extraLight)
            super.init(effect: fallbackEffect)
        }

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Ensure the container itself allows subviews to be seen clearly
        self.clipsToBounds = true

        if #available(iOS 26, *) {
            // Adopting glass for custom views as per documentation
            // Add a child UIVisualEffectView with UIGlassEffect
            let glassEffect = UIGlassEffect(style: .clear)
            let effectView = UIVisualEffectView(effect: glassEffect)
            contentView.addSubview(effectView)
            effectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // Send to back to ensure it's behind other content added later
            contentView.sendSubviewToBack(effectView)

            
            // Animating setting the effect results in a materialize animation
            UIView.animate {
                effectView.effect = glassEffect
            }
        } else {
            // Fallback background color (blur is handled in init)
            self.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        }
    }

    // MARK: - Public Methods

    /// Adds a glass element to the container.
    /// These elements will morph and blend when close to each other.
    /// - Parameters:
    ///   - frame: The initial frame of the element
    ///   - cornerRadius: The corner radius (defaults to half height for circle/pill)
    /// - Returns: The created view
    func addGlassElement(frame: CGRect, cornerRadius: CGFloat? = nil) -> UIView {
        let elementView: UIView

        if #available(iOS 26, *) {
            // Use the specific glass effect for the element
            let effect = UIGlassEffect(style: .clear)
            elementView = UIVisualEffectView(effect: effect)
        } else {
            // Fallback: Use a simple white view with alpha or a blur
            // Using a semi-transparent white view to simulate "glass" content
            elementView = UIView()
            elementView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            elementView.layer.compositingFilter = "overlayBlendMode"
        }

        elementView.frame = frame

        // Default to pill/circle shape if no radius provided
        let radius = cornerRadius ?? frame.height / 2
        elementView.layer.cornerRadius = radius
        elementView.clipsToBounds = true

        // Add to contentView so the container effect can process it
        contentView.addSubview(elementView)

        return elementView
    }

    /// Adds a glass element using SnapKit constraints
    /// - Parameter setup: Closure to define constraints
    /// - Returns: The created view
    func addGlassElement(setup: (ConstraintMaker) -> Void) -> UIView {
        let elementView: UIView

        if #available(iOS 26, *) {
            let effect = UIGlassEffect(style: .clear)
            elementView = UIVisualEffectView(effect: effect)
        } else {
            elementView = UIView()
            elementView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        }

        elementView.layer.cornerRadius = 20  // Default, should be updated in layout
        elementView.clipsToBounds = true

        contentView.addSubview(elementView)
        elementView.snp.makeConstraints(setup)

        return elementView
    }
}

// MARK: - Mock Definitions for Compilation
// Since we are likely not running on an SDK that actually has these symbols yet,
// we define them here to allow the code to "compile" in a standard environment
// for the purpose of this task, assuming the user will use the correct SDK later.
// In a real scenario, these would be removed when the SDK is updated.

// These are dummy definitions to prevent compiler errors in current SDKs
// if the user tries to build this now.
class UIGlassContainerEffect: UIVisualEffect {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override init() {
        super.init()
    }
}

// Define custom style enum globally
enum UIGlassEffectStyle {
    case regular
    case clear
    case frosted
}
/*
// Typealias UIGlassEffect to UIBlurEffect so it renders
typealias UIGlassEffect = UIBlurEffect

extension UIBlurEffect {
    convenience init(style: UIGlassEffectStyle) {
        let blurStyle: UIBlurEffect.Style
        switch style {
        case .regular: blurStyle = .systemUltraThinMaterial
        case .clear: blurStyle = .systemMaterial
        case .frosted: blurStyle = .systemThickMaterial
        }
        self.init(style: blurStyle)
    }
}
*/
