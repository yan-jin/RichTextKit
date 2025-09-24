//
//  RichTextKeyboardToolbar+Config.swift
//  RichTextKit
//
//  Created by Ryan Jarvis on 2024-02-24.
//  Copyright © 2023-2024 Daniel Saidi. All rights reserved.
//

#if iOS || macOS || os(visionOS)
import SwiftUI

/// This struct can configure a ``RichTextKeyboardToolbar``.
public struct RichTextKeyboardToolbarConfig {

    /// Create a custom keyboard toolbar configuration.
    ///
    /// - Parameters:
    ///   - alwaysDisplayToolbar: Whether or not to always show the toolbar, by default `false`.
    ///   - displayFormatSheetButton: Whether to show the format sheet button, by default `true`.
    ///   - actions: The toolbar actions, by default `.undo`, `.redo`, and `.dismissKeyboard`.
    public init(
        alwaysDisplayToolbar: Bool = false,
        displayFormatSheetButton: Bool = true,
        actions: [RichTextAction] = [.undo, .redo, .dismissKeyboard]) {
        self.alwaysDisplayToolbar = alwaysDisplayToolbar
        self.displayFormatSheetButton = displayFormatSheetButton
        self.actions = actions
    }

    /// Whether or not to always show the toolbar.
    public var alwaysDisplayToolbar: Bool

    /// Whether to display the format sheet button.
    public var displayFormatSheetButton: Bool

    /// The toolbar actions.
    public var actions: [RichTextAction]
}

public extension RichTextKeyboardToolbarConfig {

    /// The standard rich text keyboard toolbar config.
    static var standard: Self { .init() }
}

public extension View {

    /// Apply a ``RichTextKeyboardToolbar`` configuration.
    func richTextKeyboardToolbarConfig(
        _ config: RichTextKeyboardToolbarConfig
    ) -> some View {
        self.environment(\.richTextKeyboardToolbarConfig, config)
    }
}

private extension RichTextKeyboardToolbarConfig {

    struct Key: EnvironmentKey {

        public static var defaultValue: RichTextKeyboardToolbarConfig {
            .standard
        }
    }
}

public extension EnvironmentValues {

    /// This value can bind to a keyboard toolbar config.
    var richTextKeyboardToolbarConfig: RichTextKeyboardToolbarConfig {
        get { self [RichTextKeyboardToolbarConfig.Key.self] }
        set { self [RichTextKeyboardToolbarConfig.Key.self] = newValue }
    }
}
#endif
