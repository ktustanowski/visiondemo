//
//  ViewController.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 21/08/2021.
//

import UIKit
import Vision

final class ImageProcessingViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var saveImageButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private let visionQueue = DispatchQueue.global(qos: .userInitiated)

    @IBAction func didTapSaveImageButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    @IBAction func didTapLoadImageButton(_ sender: UIButton) {
        saveImageButton.isHidden = true
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveImageButton.isHidden = true
    }
}

extension ImageProcessingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = imageView.image else { return }
        process(image)
    }
}

private extension ImageProcessingViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        activityIndicator.startAnimating()
        
        visionQueue.async { [weak self] in
            let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

            let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                      orientation: .init(image.imageOrientation),
                                                      options: [:])            
            do {
                try requestHandler.perform([bodyPoseRequest])
            } catch {
                self?.activityIndicator.stopAnimating()
                print("Can't make the request due to \(error)")
            }
            
            guard let results = bodyPoseRequest.results else { return }
                    
            let normalizedPoints = results.flatMap { result in
                result.availableJointNames
                    .compactMap { try? result.recognizedPoint($0) }
                    .filter { $0.confidence > 0.1 }
            }
            
            let upsideDownPoints = normalizedPoints.map { $0.location(in: image) }
            let points = upsideDownPoints
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
            
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.imageView.image = image.draw(points:  points,
                                                   fillColor: .primary,
                                                   strokeColor: .white)
                self?.saveImageButton.isHidden = false
            }
        }
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
            let path = UIBezierPath(arcCenter: point,
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
    func translateFromCoreImageToUIKitCoordinateSpace(using height: CGFloat) -> CGPoint {
        let transform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -height);
        
        return self.applying(transform)
    }
}

extension VNRecognizedPoint {
    func location(in image: UIImage) -> CGPoint {
        VNImagePointForNormalizedPoint(location,
                                       Int(image.size.width),
                                       Int(image.size.height))
    }
}
