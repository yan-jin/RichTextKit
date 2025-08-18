//
//  RichTextImagePickerManager.swift
//  RichTextKit
//
//  Created by AI Assistant on 2024-12-28.
//  Copyright © 2024 Daniel Saidi. All rights reserved.
//

#if iOS
import UIKit

/// A manager that handles configuring image pickers for insertion.
public class RichTextImagePickerManager {
    
    /// Create an image picker manager.
    public init() {}
    
    public var insertMode: InsertMode = .single
    
    /// The mode for inserting images
    public enum InsertMode {
        /// Insert a single image
        case single
        /// Insert multiple images (note: UIImagePickerController only supports single selection)
        case multiple
    }
    
    /// Configure the picker for the given mode and context.
    public func configure(for mode: InsertMode, context: RichTextContext) {
        self.insertMode = mode
    }
}



#endif
