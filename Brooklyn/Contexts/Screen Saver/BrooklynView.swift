//
//  BrooklynView.swift
//  Brooklyn
//
//  Created by Pedro Carrasco on 30/10/2018.
//  Copyright © 2018 Pedro Carrasco. All rights reserved.
//

import Foundation
import ScreenSaver
import AVKit

// MARK: - BrooklynView
final class BrooklynView: ScreenSaverView {

    // MARK: Constant
    private enum Constant {
        static let backgroundColor = NSColor(red: 0.00, green: 0.01, blue: 0.00, alpha: 1.0)
    }

    // MARK: Properties
    private var videoLayer: AVPlayerLayer?
    private var manager: BrooklynManager?
    private lazy var preferences: PreferencesWindowController = {
        let bundle = Bundle(for: BrooklynView.self)
        let nibName = PreferencesWindowController.identifier
        let controller = PreferencesWindowController()

        let nib = NSNib(nibNamed: nibName, bundle: bundle)!
        var topLevelObjects: NSArray?
        nib.instantiate(withOwner: controller, topLevelObjects: &topLevelObjects)

        if let objects = topLevelObjects {
            for obj in objects {
                if let window = obj as? NSWindow {
                    controller.window = window
                    window.delegate = controller
                    break
                }
            }
        }
        controller.configureIfNeeded()
        return controller
    }()

    // MARK: Initialization
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        configure()
    }

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        configure()
    }

    // MARK: ScreenSaverView overrides
    override func startAnimation() {
        super.startAnimation()
        if !isPreview {
            if manager == nil {
                manager = BrooklynManager(mode: .screensaver)
                videoLayer?.player = manager!.player
                // Listen for screen wake/unlock to tear down playback,
                // since stopAnimation is not reliably called on modern macOS.
                DistributedNotificationCenter.default().addObserver(self,
                    selector: #selector(screenDidUnlock),
                    name: NSNotification.Name("com.apple.screenIsUnlocked"),
                    object: nil)
                NotificationCenter.default.addObserver(self,
                    selector: #selector(screenDidUnlock),
                    name: NSWorkspace.screensDidWakeNotification,
                    object: nil)
            }
            manager?.player.play()
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        tearDownPlayer()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            tearDownPlayer()
        }
    }

    @objc private func screenDidUnlock() {
        tearDownPlayer()
    }

    private func tearDownPlayer() {
        manager?.player.pause()
        manager?.player.removeAllItems()
        videoLayer?.player = nil
        manager = nil
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    override func layout() {
        super.layout()
        guard let videoLayer = videoLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        videoLayer.frame = bounds
        CATransaction.commit()
    }

    // MARK: Preferences
    override var hasConfigureSheet: Bool {
        return true
    }

    override var configureSheet: NSWindow? {
        return preferences.window
    }
}

// MARK: - Configuration
private extension BrooklynView {

    func configure() {
        animationTimeInterval = 60.0
        wantsLayer = true
        layer?.backgroundColor = Constant.backgroundColor.cgColor

        if isPreview {
            let bundle = Bundle(for: BrooklynView.self)
            if let image = bundle.image(forResource: "thumbnail") {
                let imageLayer = CALayer()
                imageLayer.contents = image
                imageLayer.contentsGravity = .resizeAspect
                imageLayer.frame = bounds
                imageLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                layer?.addSublayer(imageLayer)
            }
        } else {
            let vLayer = AVPlayerLayer()
            vLayer.videoGravity = .resizeAspect
            vLayer.backgroundColor = Constant.backgroundColor.cgColor
            vLayer.frame = bounds
            layer?.addSublayer(vLayer)
            videoLayer = vLayer
        }
    }
}
