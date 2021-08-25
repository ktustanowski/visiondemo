//
//  ViewController.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 21/08/2021.
//

import UIKit
import Vision

class PickerViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapLoadImageButton(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
}


extension PickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = imageView.image else { return }
        process(image)
    }
}

private extension PickerViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let detectBodyPose = VNDetectHumanBodyPoseRequest()
        // TODOKT: Add also hand pose
        let visionRequest = VNImageRequestHandler(cgImage: cgImage, orientation: .init(image.imageOrientation), options: [:])
        
        do {
            try visionRequest.perform([detectBodyPose])
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        guard let results = detectBodyPose.results else { return }
                
        let pointsToDraw = results.flatMap { result in
            result.availableJointNames
                .compactMap { try? result.recognizedPoint($0) }
                .filter { $0.confidence > 0.1 }
        }
        
        imageView.image = image.draw(points: pointsToDraw.map { $0.location(in: image) },
                                        fillColor: .white,
                                        strokeColor: .black)
    }
}

extension UIImage {
    func draw(points: [CGPoint],
              fillColor: UIColor = .white,
              strokeColor: UIColor = .black,
              radius: CGFloat = 15) -> UIImage? {
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero)

        points.forEach { point in
            let path = UIBezierPath(arcCenter: point.reversedY(using: size.height),
                                    radius: radius,
                                    startAngle: CGFloat(0),
                                    endAngle: CGFloat(Double.pi * 2),
                                    clockwise: true)
            
            fillColor.setFill()
            strokeColor.setStroke()
            path.lineWidth = 3.0
            
            path.fill()
            path.stroke()
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default:
                self = .up
        }
    }
}

extension CGPoint {
    func reversedY(using height: CGFloat) -> CGPoint {
        CGPoint(x: x, y: height - y)
    }
}

extension VNRecognizedPoint {
    func location(in image: UIImage) -> CGPoint {
        VNImagePointForNormalizedPoint(location,
                                       Int(image.size.width),
                                       Int(image.size.height))
    }
}
