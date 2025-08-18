//
//  UIView+ViewController.swift
//  RichTextKit
//
//  Created by AI Assistant on 2024-12-28.
//  Copyright © 2024 Daniel Saidi. All rights reserved.
//

#if iOS || os(visionOS)
import UIKit

extension UIView {
    /// Find the view controller that contains this view.
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController {
                return vc
            }
            responder = r.next
        }
        return nil
    }
}

#endif
