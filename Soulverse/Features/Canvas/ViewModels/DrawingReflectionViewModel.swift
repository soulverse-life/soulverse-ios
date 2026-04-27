//
//  DrawingReflectionViewModel.swift
//  Soulverse
//

import UIKit

/// Inputs needed to display the reflection screen. `drawingImage` is used
/// when the screen is opened right after save (image already in memory);
/// `drawingImageURL` is used when re-entering from a list view.
struct DrawingReflectionViewModel {
    let drawingId: String
    let drawingImage: UIImage?
    let drawingImageURL: String?
    let reflectiveQuestion: String
    let reflectiveAnswer: String?
}
