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
    @IBOutlet private weak var stopwatchImage: UIImageView!
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
        durationLabel.isHidden = true
        stopwatchImage.isHidden = true
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
        
        updateUI(isProcessing: true)
        durationLabel.text = "0.0"
        
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            let requests = [isBodyPoseRequired ? VNDetectHumanBodyPoseRequest() : nil,
                            isHandPoseRequired ? VNDetectHumanHandPoseRequest(maximumHandCount: 10) : nil,
                            isFaceLandmarksRequired ? VNDetectFaceLandmarksRequest() : nil].compactMap { $0 }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                       orientation: .init(image.imageOrientation),
                                                       options: [:])
            
            var processingTime: Double = 0.0
            
            do {
                let startProcessingDate = Date()
                try requestHandler.perform(requests)
                processingTime = (Date().timeIntervalSince(startProcessingDate) * 100).rounded() / 100
            } catch {
                self.updateUI(isProcessing: true)
                print("Can't make the request due to \(error)")
            }

            let resultPointsProviders = requests.compactMap { $0 as? ResultPointsProviding }
            
            let openPointsGroups = resultPointsProviders
                .flatMap { $0.openPointGroups(projectedOnto: image) }
            
            let closedPointsGroups = resultPointsProviders
                .flatMap { $0.closedPointGroups(projectedOnto: image) }

            var points: [CGPoint]?
            let isDetectingFaceLandmarks = requests.filter { ($0 as? VNDetectFaceLandmarksRequest)?.results?.isEmpty == false }.isEmpty == false

            points = resultPointsProviders
                .filter { !isDetectingFaceLandmarks || isDetectingFaceLandmarks && !($0 is VNDetectHumanBodyPoseRequest) }
                .flatMap { $0.pointsProjected(onto: image) }

            
            DispatchQueue.main.async {
                self.durationLabel.text = "\(processingTime)s"
                self.updateUI(isProcessing: false)
                self.imageView.image = image.draw(openPaths: openPointsGroups,
                                                  closedPaths: closedPointsGroups,
                                                  points: points)

                self.saveImageButton.isHidden = false
            }
        }
    }
}

private extension ImageProcessingViewController {
    func updateUI(isProcessing: Bool) {
        durationLabel.isHidden = isProcessing
        stopwatchImage.isHidden = isProcessing
        
        if isProcessing {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }
}

extension UIImage {
    func draw(openPaths: [[CGPoint]]? = nil,
              closedPaths: [[CGPoint]]? = nil,
              points: [CGPoint]? = nil,
              fillColor: UIColor = .primary,
              strokeColor: UIColor = .primary,
              radius: CGFloat = 5,
              lineWidth: CGFloat = 2) -> UIImage? {
        let scale: CGFloat = 0

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero)

// Uncomment to draw gray background
//        let rect = CGRect(origin: .zero, size: size)
//        UIColor.background.setFill()
//        UIRectFill(rect)
        
        points?.forEach { point in
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

        openPaths?.forEach { points in
            draw(points: points, isClosed: false, color: strokeColor, lineWidth: lineWidth)
        }

        closedPaths?.forEach { points in
            draw(points: points, isClosed: true, color: strokeColor, lineWidth: lineWidth)
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func draw(points: [CGPoint], isClosed: Bool, color: UIColor, lineWidth: CGFloat) {
        let bezierPath = UIBezierPath()
        bezierPath.drawLinePath(for: points, isClosed: isClosed)
        color.setStroke()
        bezierPath.lineWidth = lineWidth
        bezierPath.stroke()
    }
}

extension UIBezierPath {
    func drawLinePath(for points: [CGPoint], isClosed: Bool) {
        points.enumerated().forEach { [unowned self] iterator in
            let index = iterator.offset
            let point = iterator.element

            let isFirst = index == 0
            let isLast = index == points.count - 1
            
            if isFirst {
                move(to: point)
            } else if isLast {
                addLine(to: point)
                move(to: point)
                
                guard isClosed, let firstItem = points.first else { return }
                addLine(to: firstItem)
            } else {
                addLine(to: point)
                move(to: point)
            }
        }
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

protocol ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint]
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
}

extension VNDetectHumanHandPoseRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
                            [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip],
                            [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip],
                            [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip],
                            [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip]],
                            projectedOnto: image)
    }
    
    func point(jointGroups: [[VNHumanHandPoseObservation.JointName]], projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results else { return [] }
        let pointGroups = results.map { result in
            jointGroups
                .compactMap { joints in
                    joints.compactMap { joint in
                        try? result.recognizedPoint(joint)
                    }
                    .filter { $0.confidence > 0.1 }
                    .map { $0.location(in: image) }
                    .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
                }
        }
        
        return pointGroups.flatMap { $0 }
    }
    
    convenience init(maximumHandCount: Int) {
        self.init()
        self.maximumHandCount = maximumHandCount
    }
}

extension VNDetectHumanBodyPoseRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] {
        point(jointGroups: [[.nose, .leftEye, .leftEar, .rightEye, .rightEar]], projectedOnto: image).flatMap { $0 }
    }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.neck, .leftShoulder, .leftHip, .root, .rightHip, .rightShoulder]], projectedOnto: image)
    }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.leftShoulder, .leftElbow, .leftWrist],
                            [.rightShoulder, .rightElbow, .rightWrist],
                            [.leftHip, .leftKnee, .leftAnkle],
                            [.rightHip, .rightKnee, .rightAnkle]], projectedOnto: image)
    }
    
    func point(jointGroups: [[VNHumanBodyPoseObservation.JointName]], projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results else { return [] }
        let pointGroups = results.map { result in
            jointGroups
                .compactMap { joints in
                    joints.compactMap { joint in
                        try? result.recognizedPoint(joint)
                    }
                    .filter { $0.confidence > 0.1 }
                    .map { $0.location(in: image) }
                    .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
                }
        }
        
        return pointGroups.flatMap { $0 }
    }
}

extension VNDetectFaceLandmarksRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results as? [VNFaceObservation] else { return [] }
        let landmarks = results.compactMap { [$0.landmarks?.leftEyebrow,
                                              $0.landmarks?.rightEyebrow,
                                              $0.landmarks?.faceContour,
                                              $0.landmarks?.noseCrest,
                                              $0.landmarks?.medianLine].compactMap { $0 } }
        
        return points(landmarks: landmarks, projectedOnto: image)
    }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results as? [VNFaceObservation] else { return [] }
        let landmarks = results.compactMap { [$0.landmarks?.leftEye,
                                              $0.landmarks?.rightEye,
                                              $0.landmarks?.outerLips,
                                              $0.landmarks?.innerLips,
                                              $0.landmarks?.nose].compactMap { $0 } }
        
        return points(landmarks: landmarks, projectedOnto: image)
    }
    
    func points(landmarks: [[VNFaceLandmarkRegion2D]], projectedOnto image: UIImage) -> [[CGPoint]] {
        let faceLandmarks = landmarks.flatMap { $0 }
            .compactMap { landmark in
                landmark.pointsInImage(imageSize: image.size)
                    .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
            }
        
        return faceLandmarks
    }
}
