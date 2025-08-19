//
//  RichTextImagePickerViewController.swift
//  RichTextKit
//
//  Created by AI Assistant on 2024-12-28.
//  Copyright © 2024 Daniel Saidi. All rights reserved.
//

#if iOS
import UIKit
import Photos

/// A view controller that presents the system UIImagePickerController for image selection.
class RichTextImagePickerViewController: UIImagePickerController {
    
    private let manager: RichTextImagePickerManager
    private let context: RichTextContext
    
    init(manager: RichTextImagePickerManager, context: RichTextContext) {
        self.manager = manager
        self.context = context
        super.init(nibName: nil, bundle: nil)
        setupImagePicker()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupImagePicker() {
        // Configure UIImagePickerController
        sourceType = .photoLibrary
        mediaTypes = ["public.image"]
        allowsEditing = false
        delegate = self
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension RichTextImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var image: UIImage?
        
        // Try to get the image from different sources in order of preference
        if let originalImage = info[.originalImage] as? UIImage {
            image = originalImage
        } else if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let imageURL = info[.imageURL] as? URL {
            // Load image from local file URL
            image = UIImage(contentsOfFile: imageURL.path)
        } else if let referenceURL = info[.referenceURL] as? URL {
            // Load image from Photos library reference URL
            loadImageFromReferenceURL(referenceURL) { [weak self] loadedImage in
                guard let self = self, let loadedImage = loadedImage else {
                    self?.dismiss(animated: true)
                    return
                }
                self.insertImage(loadedImage)
                self.dismiss(animated: true)
            }
            return // Early return since we're loading asynchronously
        }
        
        guard let selectedImage = image else {
            dismiss(animated: true)
            return
        }
        
        // Insert the selected image
        insertImage(selectedImage)
        
        // Dismiss the picker
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    private func insertImage(_ image: UIImage) {
        let index = context.selectedRange.location
        let insertion = RichTextInsertion<ImageRepresentable>.image(image, at: index, moveCursor: true)
        context.handle(.pasteImage(insertion))
    }
    
    private func loadImageFromReferenceURL(_ referenceURL: URL, completion: @escaping (UIImage?) -> Void) {
        // Get the asset from the reference URL
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
        guard let asset = fetchResult.firstObject else {
            completion(nil)
            return
        }
        
        // Request the image from the asset
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}



#endif
