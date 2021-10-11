//
//  ImageProcessingViewController+AnimalsDetection.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 16/09/2021.
//

import UIKit
import Vision

extension ImageProcessingViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNClassifyImageRequest()
        
        if #available(iOS 15, *) {
            let supportedIdentifiers = try! request.supportedIdentifiers()
        } else {
            let supportedIdentifiers = try? VNClassifyImageRequest.knownClassifications(forRevision: VNClassifyImageRequestRevision1)
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Can't make the request due to \(error)")
            }
            
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            results
                .filter { $0.confidence > 0.7 }
                .forEach { print("\($0.identifier) - \((Int($0.confidence * 100)))%") }
        }
    }
}
