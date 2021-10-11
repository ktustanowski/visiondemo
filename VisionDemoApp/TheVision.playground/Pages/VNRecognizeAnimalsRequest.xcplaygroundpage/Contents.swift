//: [Previous](@previous)

import UIKit
import Vision

struct ImageProcessor {
    func process(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let animalsRequest = VNRecognizeAnimalsRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])
        
        do {
            try requestHandler.perform([animalsRequest])
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        guard let results = animalsRequest.results as? [VNRecognizedObjectObservation] else { return nil }
        
        let boxesAndNames = results
            .map { (box: $0.boundingBox.rectangle(in: image),
                    name: $0.labels.first?.identifier ?? "n/a") }
        
        let rectangles = boxesAndNames.map { $0.box }
            .map { CGRect(origin: $0.origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - $0.size.height),
                          size: $0.size) }
        
        let displayableTexts = zip(rectangles,
                                   boxesAndNames.map { $0.name })
            .map { DisplayableText(frame: $0.0,
                                   text: $0.1) }
        
        return image.draw(rectangles: rectangles,
                          displayableTexts: displayableTexts)
    }
}

extension UIImage {
    func draw(rectangles: [CGRect],
              displayableTexts: [DisplayableText],
              strokeColor: UIColor = .primary,
              lineWidth: CGFloat = 20) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            
            context.cgContext.setStrokeColor(strokeColor.cgColor)
            context.cgContext.setLineWidth(lineWidth)
            rectangles.forEach { context.cgContext.addRect($0) }
            context.cgContext.drawPath(using: .stroke)
            
            let textAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: lineWidth * 10, weight: .bold),
                                  NSAttributedString.Key.foregroundColor: strokeColor,
                                  NSAttributedString.Key.backgroundColor: UIColor.black]
            
            displayableTexts.forEach { displayableText in
                guard let frame = displayableText.frame else { return }
                displayableText.text.draw(with: frame,
                                          options: [],
                                          attributes: textAttributes,
                                          context: nil)
            }
        }
    }
}

let imageProcessor = ImageProcessor()

let cat = UIImage(named: "cat.jpg")!
let catRecognized = imageProcessor.process(cat)

let fanta = UIImage(named: "fanta.jpeg")!
let fantaRecognized = imageProcessor.process(fanta)

//: [Next](@next)
