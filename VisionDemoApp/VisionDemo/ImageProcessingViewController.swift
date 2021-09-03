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
    @IBOutlet private weak var bodyPoseButton: UIButton!
    @IBOutlet private weak var handPoseButton: UIButton!
    @IBOutlet private weak var faceLandmarksButton: UIButton!
    @IBOutlet private weak var durationLabel: UILabel!
    private var originalImage: UIImage?
    
    private let visionQueue = DispatchQueue.global(qos: .userInitiated)

    @IBAction func didTapSaveImageButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    @IBAction func didTapLoadImageButton(_ sender: UIButton) {
        saveImageButton.isHidden = true
        presentImagePicker(source: .photoLibrary)
    }
    
    @IBAction func didTapTakePictureButton(_ sender: UIButton) {
        saveImageButton.isHidden = true
        presentImagePicker(source: .camera)
    }

    @IBAction func didTapSelectRequestButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        imageView.image = originalImage
        guard let image = imageView.image else { return }
        process(image)
    }

    private func presentImagePicker(source:  UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = source
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
        let pickedImage = info[.originalImage] as? UIImage
        originalImage = downsized(image: pickedImage)
        imageView.image = originalImage
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = imageView.image else { return }
        process(image)
    }
    
    private func downsized(image: UIImage?, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let image = image else { return nil }
        let newWidth = view.frame.width * scale
        let newHeight = view.frame.width * image.size.height * scale / image.size.width
        
        return image.resizeImage(to: CGSize(width: newWidth, height: newHeight))
    }
}

private extension ImageProcessingViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let isBodyPoseRequired = self.bodyPoseButton.isSelected
        let isHandPoseRequired = self.handPoseButton.isSelected
        let isFaceLandmarksRequired = self.faceLandmarksButton.isSelected

        guard isBodyPoseRequired || isHandPoseRequired || isFaceLandmarksRequired else {
            imageView.image = originalImage
            return
        }
        
        activityIndicator.startAnimating()

        visionQueue.async { [weak self] in
            guard let self = self else { return }
            let bodyPoseRequest = isBodyPoseRequired ? VNDetectHumanBodyPoseRequest() : nil
            let handPoseRequest = isHandPoseRequired ? VNDetectHumanHandPoseRequest() : nil
            let faceLandmarks = isFaceLandmarksRequired ? VNDetectFaceLandmarksRequest() : nil

            let horizonRequest = VNDetectContoursRequest()
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                      orientation: .init(image.imageOrientation),
                                                      options: [:])            

            let requests = [faceLandmarks, handPoseRequest, bodyPoseRequest].compactMap { $0 }
            
            var processingTime: Double = 0.0
            
            do {
                let startProcessingDate = Date()
                try requestHandler.perform(requests)
                processingTime = (Date().timeIntervalSince(startProcessingDate) * 100).rounded() / 100
            } catch {
                self.activityIndicator.stopAnimating()
                print("Can't make the request due to \(error)")
            }
            
            var points = [CGPoint]()

            if let results = horizonRequest.results {
                print(results)
            }
            
            if let results = faceLandmarks?.results as? [VNFaceObservation] {
                let faceLandmarks = results.flatMap { result in
                    result.landmarks?.allPoints?.pointsInImage(imageSize: image.size) ?? []
                }
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }

                points.append(contentsOf: faceLandmarks)
            }
            
            if let results = bodyPoseRequest?.results {
                let bodyJointsPoints = results.flatMap { result in
                    result.availableJointNames
                        .compactMap { try? result.recognizedPoint($0) }
                        .filter { $0.confidence > 0.1 }
                }
                .map { $0.location(in: image) }
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }

                points.append(contentsOf: bodyJointsPoints)
            }
            
            if let results = handPoseRequest?.results {
                let handJointsPoints = results.flatMap { result in
                    result.availableJointNames
                        .compactMap { try? result.recognizedPoint($0) }
                        .filter { $0.confidence > 0.1 }
                }
                .map { $0.location(in: image) }
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }

                points.append(contentsOf: handJointsPoints)
            }
            
            DispatchQueue.main.async {
                self.durationLabel.text = "\(processingTime)"
                self.activityIndicator.stopAnimating()
                self.imageView.image = image.draw(points:  points,
                                                  fillColor: .primary,
                                                  strokeColor: .white)
                self.saveImageButton.isHidden = false
            }
        }
    }
}

extension UIImage {
    func draw(points: [CGPoint],
              fillColor: UIColor = .white,
              strokeColor: UIColor = .black,
              radius: CGFloat = 5,
              lineWidth: CGFloat = 1) -> UIImage? {
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
            path.lineWidth = lineWidth
            
            path.fill()
            path.stroke()
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func draw(openPaths: [CGPoint],
              closedPaths: [CGPoint],
              points: [CGPoint],
              fillColor: UIColor = .white,
              strokeColor: UIColor = .black,
              radius: CGFloat = 5,
              lineWidth: CGFloat = 2) -> UIImage? {
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
            path.lineWidth = lineWidth
            
            path.fill()
            path.stroke()
        }

        let path = UIBezierPath()
        points.enumerated().forEach { iterator in
            let index = iterator.offset
            let point = iterator.element
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
                path.move(to: point)
            }
        }
        
        fillColor.setFill()
        strokeColor.setStroke()
        path.lineWidth = lineWidth
        
        path.fill()
        path.stroke()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIImage {
  func resizeImage(to newSize: CGSize) -> UIImage? {
    let size = self.size
    let widthRatio  = newSize.width  / size.width
    let heightRatio = newSize.height / size.height
    let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
                                           : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    self.draw(in: rect)
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
