//
//  RichTextImagePicker.swift
//  RichTextKit
//
//  Created by AI Assistant on 2024-12-28.
//  Copyright © 2024 Daniel Saidi. All rights reserved.
//

#if iOS || os(visionOS)
import SwiftUI
import PhotosUI

/// A SwiftUI view that provides image selection functionality
/// for inserting images into rich text.
@available(iOS 16.0, *)
@available(visionOS 1.0, *)
public struct RichTextImagePicker: View {
    
    private let context: RichTextContext
    private let insertMode: InsertMode
    private let onDismiss: (() -> Void)?
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPresented = false
    
    /// The mode for inserting images
    public enum InsertMode {
        /// Insert a single image
        case single
        /// Insert multiple images
        case multiple
    }
    
    /// Create a rich text image picker.
    ///
    /// - Parameters:
    ///   - context: The rich text context to use.
    ///   - insertMode: The insert mode (single or multiple).
    ///   - onDismiss: Optional callback when picker should dismiss.
    public init(
        context: RichTextContext,
        insertMode: InsertMode = .single,
        onDismiss: (() -> Void)? = nil
    ) {
        self.context = context
        self.insertMode = insertMode
        self.onDismiss = onDismiss
    }
    
    @State private var isPickerPresented = false
    
    public var body: some View {
        // Modal mode: Auto-present system photo picker
        Color.clear
            .onAppear {
                isPickerPresented = true
            }
            .photosPicker(
                isPresented: $isPickerPresented,
                selection: $selectedItems,
                maxSelectionCount: insertMode == .single ? 1 : nil,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItems) { items in
                loadAndInsertImages(from: items)
                if !items.isEmpty {
                    onDismiss?()
                }
            }
            .onChange(of: isPickerPresented) { presented in
                if !presented && selectedItems.isEmpty {
                    // User cancelled without selecting
                    onDismiss?()
                }
            }
    }
    
    private func loadAndInsertImages(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        Task {
            var images: [ImageRepresentable] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = ImageRepresentable(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                insertImages(images)
                selectedItems.removeAll()
            }
        }
    }
    
    private func insertImages(_ images: [ImageRepresentable]) {
        guard !images.isEmpty else { return }
        let index = context.selectedRange.location
        
        // Insert images directly using the paste infrastructure
        if images.count == 1 {
            let insertion = RichTextInsertion<ImageRepresentable>.image(images[0], at: index, moveCursor: true)
            context.handle(.pasteImage(insertion))
        } else {
            let insertion = RichTextInsertion<[ImageRepresentable]>.images(images, at: index, moveCursor: true)
            context.handle(.pasteImages(insertion))
        }
    }
}

/// A button that presents an image picker for inserting images.
@available(iOS 16.0, *)
@available(visionOS 1.0, *)
public struct RichTextImagePickerButton: View {
    
    private let context: RichTextContext
    private let insertMode: RichTextImagePicker.InsertMode
    
    /// Create a rich text image picker button.
    ///
    /// - Parameters:
    ///   - context: The rich text context to use.
    ///   - insertMode: The insert mode (single or multiple).
    public init(
        context: RichTextContext,
        insertMode: RichTextImagePicker.InsertMode = .single
    ) {
        self.context = context
        self.insertMode = insertMode
    }
    
    public var body: some View {
        RichTextImagePicker(context: context, insertMode: insertMode)
    }
}



#endif
