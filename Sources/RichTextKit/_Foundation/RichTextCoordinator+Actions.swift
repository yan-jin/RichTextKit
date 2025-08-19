//
//  RichTextCoordinator+Actions.swift
//  RichTextKit
//
//  Created by Daniel Saidi on 2022-05-22.
//  Copyright © 2022-2024 Daniel Saidi. All rights reserved.
//

#if iOS || macOS || os(tvOS) || os(visionOS)
import SwiftUI
#if iOS
import Photos
#endif

extension RichTextCoordinator {

    func handle(_ action: RichTextAction?) {
        guard let action else { return }
        switch action {
        case .copy: textView.copySelection()
        case .deleteSelectedText: textView.deleteText(in: textView.selectedRange)
        case .deleteText(let range): textView.deleteText(in: range)
        case .dismissKeyboard: textView.resignFirstResponder()
        case .pasteImage(let image): pasteImage(image)
        case .pasteImages(let images): pasteImages(images)
        case .pasteText(let text): pasteText(text)
        case .insertImage: handleInsertImage()
        case .insertImages: handleInsertImages()
        case .print: break
        case .redoLatestChange:
            textView.redoLatestChange()
            syncContextWithTextView()
        case .replaceSelectedText(let text): textView.replaceText(in: textView.selectedRange, with: text)
        case .replaceText(let range, let text): textView.replaceText(in: range, with: text)
        case .selectRange(let range): setSelectedRange(to: range)
        case .setAlignment(let alignment): textView.setRichTextParagraphStyleValue(\.alignment, alignment)
        case .setAttributedString(let string): setAttributedString(to: string)
        case .setColor(let color, let newValue): setColor(color, to: newValue)
        case .setHighlightedRange(let range): setHighlightedRange(to: range)
        case .setHighlightingStyle(let style): textView.highlightingStyle = style
        case .setParagraphStyle(let style): textView.setRichTextParagraphStyle(style)
        case .setStyle(let style, let newValue): setStyle(style, to: newValue)
        case .stepFontSize(let points):
            textView.stepRichTextFontSize(points: points)
            syncContextWithTextView()
        case .stepIndent(let points): textView.stepRichTextParagraphStyleValue(\.firstLineHeadIndent, points)
            textView.stepRichTextParagraphStyleValue(\.headIndent, points)
        case .stepLineSpacing(let points): textView.stepRichTextParagraphStyleValue(\.lineSpacing, points)
        case .stepSuperscript(let points): textView.stepRichTextSuperscriptLevel(points: points)
        case .toggleStyle(let style): textView.toggleRichTextStyle(style)
        case .undoLatestChange:
            textView.undoLatestChange()
            syncContextWithTextView()
        }
    }
}

extension RichTextCoordinator {

    func paste<T: RichTextInsertable>(_ data: RichTextInsertion<T>) {
        if let data = data as? RichTextInsertion<ImageRepresentable> {
            pasteImage(data)
        } else if let data = data as? RichTextInsertion<[ImageRepresentable]> {
            pasteImages(data)
        } else if let data = data as? RichTextInsertion<String> {
            pasteText(data)
        } else {
            print("Unsupported media type")
        }
    }

    func pasteImage(_ data: RichTextInsertion<ImageRepresentable>) {
        textView.pasteImage(
            data.content,
            at: data.index,
            moveCursorToPastedContent: data.moveCursor
        )
    }

    func pasteImages(_ data: RichTextInsertion<[ImageRepresentable]>) {
        textView.pasteImages(
            data.content,
            at: data.index,
            moveCursorToPastedContent: data.moveCursor
        )
    }

    func pasteText(_ data: RichTextInsertion<String>) {
        textView.pasteText(
            data.content,
            at: data.index,
            moveCursorToPastedContent: data.moveCursor
        )
    }

    func setAttributedString(to newValue: NSAttributedString?) {
        guard let newValue else { return }
        textView.setRichText(newValue)
    }

    func handleInsertImage() {
        #if iOS
        presentImagePicker(for: .single)
        #endif
    }

    func handleInsertImages() {
        #if iOS
        presentImagePicker(for: .multiple)
        #endif
    }
    
    #if iOS
    private func presentImagePicker(for mode: RichTextImagePickerManager.InsertMode) {
        // Request photo library permission first
        requestPhotoLibraryPermission { [weak self] granted in
            guard granted else { return }
            self?.showImagePicker(for: mode)
        }
    }
    
    private func showImagePicker(for mode: RichTextImagePickerManager.InsertMode) {
        // Configure the picker manager
        imagePickerManager.configure(for: mode, context: context)
        
        // Get the hosting view controller from the text view
        guard let viewController = textView.findViewController() else { return }
        
        // Create and present the image picker
        let pickerViewController = RichTextImagePickerViewController(
            manager: imagePickerManager,
            context: context
        )
        
        viewController.present(pickerViewController, animated: true)
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        case .denied, .restricted:
            self.showPhotoPermissionDeniedAlert {
                completion(false)
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func showPhotoPermissionDeniedAlert(completion: @escaping () -> Void) {
        guard let viewController = textView.findViewController() else {
            completion()
            return
        }
        
        let alert = UIAlertController(
            title: "Photo Access Required",
            message: "To insert images, please allow access to your photo library in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion()
        })
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            // Open app settings
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            completion()
        })
        
        viewController.present(alert, animated: true)
    }
    #endif

    // TODO: This code should be handled by the component
    func setColor(_ color: RichTextColor, to val: ColorRepresentable) {
        var applyRange: NSRange?
        if textView.hasSelectedRange {
            applyRange = textView.selectedRange
        }
        guard let attribute = color.attribute else { return }
        if let applyRange {
            textView.setRichTextColor(color, to: val, at: applyRange)
        } else {
            textView.setRichTextAttribute(attribute, to: val)
        }
    }

    func setHighlightedRange(to range: NSRange?) {
        resetHighlightedRangeAppearance()
        guard let range = range else { return }
        setHighlightedRangeAppearance(for: range)
    }

    func setHighlightedRangeAppearance(for range: NSRange) {
        let back = textView.richTextColor(.background, at: range) ?? .clear
        let fore = textView.richTextColor(.foreground, at: range) ?? .textColor
        highlightedRangeOriginalBackgroundColor = back
        highlightedRangeOriginalForegroundColor = fore
        let style = textView.highlightingStyle
        let background = ColorRepresentable(style.backgroundColor)
        let foreground = ColorRepresentable(style.foregroundColor)
        textView.setRichTextColor(.background, to: background, at: range)
        textView.setRichTextColor(.foreground, to: foreground, at: range)
    }

    func setIsEditable(to newValue: Bool) {
        #if iOS || macOS || os(visionOS)
        if newValue == textView.isEditable { return }
        textView.isEditable = newValue
        #endif
    }

    func setIsEditing(to newValue: Bool) {
        if newValue == textView.isFirstResponder { return }
        if newValue {
            #if iOS || os(visionOS)
            textView.becomeFirstResponder()
            #else
            print("macOS currently doesn't resign first responder.")
            #endif
        } else {
            #if iOS || os(visionOS)
            textView.resignFirstResponder()
            #else
            print("macOS currently doesn't resign first responder.")
            #endif
        }
    }

    func setSelectedRange(to range: NSRange) {
        if range == textView.selectedRange { return }
        textView.selectedRange = range
    }

    func setStyle(_ style: RichTextStyle, to newValue: Bool) {
        let hasStyle = textView.richTextStyles.hasStyle(style)
        if newValue == hasStyle { return }
        textView.setRichTextStyle(style, to: newValue)
    }
}

extension ColorRepresentable {

    #if iOS || os(tvOS) || os(visionOS)
    public static var textColor: ColorRepresentable { .label }
    #endif
}
#endif
