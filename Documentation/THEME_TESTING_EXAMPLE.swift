//
//  THEME_TESTING_EXAMPLE.swift
//  Soulverse
//
//  This file contains example code for testing the theming system.
//  You can copy these snippets into your view controllers for testing.
//

import UIKit

/*
 EXAMPLE 1: Add a theme toggle button to any view controller

 This is useful for testing theme switching during development.
 Copy this code into any view controller's viewDidLoad method.
 */

class ThemeTestViewController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add theme toggle button (only in debug builds)
        #if DEBUG
        addThemeToggleButton()
        addAutoThemeSwitch()
        #endif
    }

    private func addThemeToggleButton() {
        let toggleButton = UIButton(type: .system)
        toggleButton.setTitle("Toggle Theme", for: .normal)
        toggleButton.backgroundColor = .themePrimary
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.layer.cornerRadius = 8
        toggleButton.addTarget(self, action: #selector(toggleTheme), for: .touchUpInside)

        view.addSubview(toggleButton)
        toggleButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }

    @objc private func toggleTheme() {
        ThemeManager.shared.toggleTheme()

        // Show current theme
        let themeName = ThemeManager.shared.currentTheme.displayName
        print("✅ Switched to theme: \(themeName)")
    }

    private func addAutoThemeSwitch() {
        let autoSwitch = UISwitch()
        autoSwitch.isOn = ThemeManager.shared.themeMode == .automatic
        autoSwitch.addTarget(self, action: #selector(autoSwitchChanged), for: .valueChanged)

        let label = UILabel()
        label.text = "Auto Theme"
        label.textColor = .themeTextPrimary
        label.font = .projectFont(ofSize: 14, weight: .medium)

        let stackView = UIStackView(arrangedSubviews: [label, autoSwitch])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-90)
            make.centerX.equalToSuperview()
        }
    }

    @objc private func autoSwitchChanged(_ sender: UISwitch) {
        ThemeManager.shared.themeMode = sender.isOn ? .automatic : .manual
        print(sender.isOn ? "✅ Auto theme enabled" : "✅ Manual theme mode")
    }
}

/*
 EXAMPLE 2: Triple-tap gesture to toggle theme

 Add this to any view controller for a hidden theme toggle.
 Triple-tap anywhere on the screen to switch themes.
 */

extension UIViewController {

    func addDebugThemeGesture() {
        #if DEBUG
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(debugToggleTheme))
        tapGesture.numberOfTaps = 3
        view.addGestureRecognizer(tapGesture)
        #endif
    }

    @objc private func debugToggleTheme() {
        ThemeManager.shared.toggleTheme()
    }
}

/*
 EXAMPLE 3: Custom themed view component

 This shows how to create a custom view that responds to theme changes.
 */

class ThemedCardView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        return label
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        subtitleLabel.text = subtitle

        setupView()
        updateThemeColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update colors in case theme changed
        updateThemeColors()
    }

    private func setupView() {
        layer.cornerRadius = 12

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
    }

    private func updateThemeColors() {
        backgroundColor = .themeCardBackground
        titleLabel.textColor = .themeTextPrimary
        subtitleLabel.textColor = .themeTextSecondary

        // Add shadow based on theme
        layer.shadowColor = ThemeManager.shared.currentTheme.cardShadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
    }
}

/*
 EXAMPLE 4: Using theme colors in table view cells
 */

class ThemedTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupThemeColors()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupThemeColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupThemeColors()
    }

    private func setupThemeColors() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        textLabel?.textColor = .themeTextPrimary
        detailTextLabel?.textColor = .themeTextSecondary

        // Update separator color
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

/*
 EXAMPLE 5: Theme information display

 This creates a view that shows current theme information.
 Useful for debugging and demos.
 */

class ThemeInfoView: UIView {

    private let themeLabel = UILabel()
    private let modeLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setupView()
        updateInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateInfo()
    }

    private func setupView() {
        backgroundColor = .themeCardBackground
        layer.cornerRadius = 8

        themeLabel.font = .projectFont(ofSize: 12, weight: .medium)
        modeLabel.font = .projectFont(ofSize: 10, weight: .regular)

        addSubview(themeLabel)
        addSubview(modeLabel)

        themeLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(8)
        }

        modeLabel.snp.makeConstraints { make in
            make.top.equalTo(themeLabel.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview().inset(8)
        }
    }

    private func updateInfo() {
        let theme = ThemeManager.shared.currentTheme
        let mode = ThemeManager.shared.themeMode

        themeLabel.text = "Theme: \(theme.displayName)"
        themeLabel.textColor = .themeTextPrimary

        modeLabel.text = "Mode: \(mode == .automatic ? "Automatic" : "Manual")"
        modeLabel.textColor = .themeTextSecondary
    }
}

/*
 HOW TO USE THESE EXAMPLES:

 1. Theme Toggle Button:
    - Copy addThemeToggleButton() into your view controller's viewDidLoad
    - Tap the button to switch between Soul and Universe themes

 2. Triple-tap Gesture:
    - Call addDebugThemeGesture() in viewDidLoad
    - Triple-tap anywhere to toggle theme

 3. Custom Themed View:
    - Use ThemedCardView as a template for your own themed components
    - Always update colors in layoutSubviews()

 4. Themed Table Cells:
    - Use ThemedTableViewCell as base class for table view cells
    - Colors automatically update when theme changes

 5. Theme Info Display:
    - Add ThemeInfoView to any screen to show current theme status
    - Useful for demos and debugging
 */
