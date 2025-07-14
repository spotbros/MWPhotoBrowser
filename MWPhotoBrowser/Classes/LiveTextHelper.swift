//
//  LiveTextHelper.swift
//  SpotBros
//
//  Created by Alvaro Marcos on 14/7/25.
//  Copyright © 2025 SpotBros. All rights reserved.
//

import UIKit
import VisionKit

private class NoOpLiveTextDelegate: NSObject, ImageAnalysisInteractionDelegate {
    
}

@available(iOS 16.0, *)
@objc class LiveTextHelper: NSObject {
    @objc static func isSupported() -> Bool {
        return ImageAnalyzer.isSupported
    }

    @MainActor @objc static func addLiveText(
        to imageView: UIImageView,
        delegate: AnyObject?
    ) {
        let del = (delegate as? ImageAnalysisInteractionDelegate) ?? NoOpLiveTextDelegate()
        let interaction = ImageAnalysisInteraction(del)
        imageView.isUserInteractionEnabled = true
        imageView.addInteraction(interaction)
        
        Task {
            guard let img = imageView.image else { return }
            let config = ImageAnalyzer.Configuration([.text])
            let analysis = try await ImageAnalyzer().analyze(img, configuration: config)
            interaction.analysis = analysis
            interaction.preferredInteractionTypes = .automatic
        }
    }
}
