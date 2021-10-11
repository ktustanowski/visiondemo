//
//  ViewController.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 21/08/2021.
//

import UIKit
import Vision

final class ImageProcessingViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveImageButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var bodyPoseButton: UIButton!
    @IBOutlet private weak var handPoseButton: UIButton!
    @IBOutlet private weak var faceLandmarksButton: UIButton!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var barcodeButton: UIButton!
    @IBOutlet private weak var faceBodyRectangles: UIButton!
    @IBOutlet private weak var textButton: UIButton!
    @IBOutlet private weak var stopwatchImage: UIImageView!
    @IBOutlet private weak var animalsButton: UIButton!
    @IBOutlet private weak var attentionButton: UIButton!
    @IBOutlet private weak var objectnessButton: UIButton!
    @IBOutlet private weak var classifyImageButton: UIButton!
    
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    private var originalImage: UIImage?
    
    let visionQueue = DispatchQueue.global(qos: .userInitiated)
    
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
        #if targetEnvironment(simulator)
        imagePicker.sourceType = .photoLibrary
        #else
        imagePicker.sourceType = source
        #endif
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

struct DisplayableText {
    let frame: CGRect?
    let text: String
}

private extension ImageProcessingViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let isBodyPoseRequired = self.bodyPoseButton.isSelected
        let isHandPoseRequired = self.handPoseButton.isSelected
        let isFaceLandmarksRequired = self.faceLandmarksButton.isSelected
        let isBarcodesRequired = self.barcodeButton.isSelected
        let isFaceBodyRectanglesRequired = self.faceBodyRectangles.isSelected
        let isTextRectanglesRequired = self.textButton.isSelected
        let isAnimalsRequired = self.animalsButton.isSelected
        let isAttentionRequired = self.attentionButton.isSelected
        let isObjectnessRequired = self.objectnessButton.isSelected
        let isClassifyImageRequired = self.classifyImageButton.isSelected
        
        let requiredRequests = [isBodyPoseRequired,
                                isHandPoseRequired,
                                isFaceLandmarksRequired,
                                isBarcodesRequired,
                                isFaceBodyRectanglesRequired,
                                isTextRectanglesRequired,
                                isAnimalsRequired,
                                isAttentionRequired,
                                isObjectnessRequired,
                                isClassifyImageRequired]
        let isProcessingRequired = requiredRequests.filter { $0 == true }.isEmpty == false
        
        guard isProcessingRequired else {
            imageView.image = originalImage
            return
        }
        
        updateUI(isProcessing: true)
        durationLabel.text = "0.0"
                
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let requests = [isBodyPoseRequired ? VNDetectHumanBodyPoseRequest() : nil,
                            isHandPoseRequired ? VNDetectHumanHandPoseRequest(maximumHandCount: 10) : nil,
                            isFaceLandmarksRequired ? VNDetectFaceLandmarksRequest() : nil,
                            isBarcodesRequired ? VNDetectBarcodesRequest() : nil,
                            isFaceBodyRectanglesRequired ? VNDetectFaceRectanglesRequest() : nil,
                            isFaceBodyRectanglesRequired ? VNDetectHumanRectanglesRequest() : nil,
                            isTextRectanglesRequired ? VNDetectTextRectanglesRequest(reportCharacterBoxes: true) : nil,
                            isAnimalsRequired ? VNRecognizeAnimalsRequest() : nil,
                            isAttentionRequired ? VNGenerateAttentionBasedSaliencyImageRequest() : nil,
                            isObjectnessRequired ? VNGenerateObjectnessBasedSaliencyImageRequest() : nil,
                            isClassifyImageRequired ? VNClassifyImageRequest() : nil].compactMap { $0 }

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

            let texts = resultPointsProviders
                .flatMap { $0.displayableTextPoints(projectedOnto: image) }
            
            var points: [CGPoint]?
            let isDetectingFaceLandmarks = requests.filter { ($0 as? VNDetectFaceLandmarksRequest)?.results?.isEmpty == false }.isEmpty == false

            points = resultPointsProviders
                .filter { !isDetectingFaceLandmarks || isDetectingFaceLandmarks && !($0 is VNDetectHumanBodyPoseRequest) }
                .flatMap { $0.pointsProjected(onto: image) }
            
            let images = resultPointsProviders.flatMap { $0.generatedImages }

            let framedTexts = texts.filter { $0.frame != nil }
            let printableTexts = texts.filter { $0.frame == nil }.map { $0.text }
            
            DispatchQueue.main.async {
                self.durationLabel.text = "\(processingTime)s"
                self.updateUI(isProcessing: false)
                self.imageView.image = image.draw(openPaths: openPointsGroups,
                                                  closedPaths: closedPointsGroups,
                                                  points: points,
                                                  displayableTexts: framedTexts,
                                                  images: images)
                
                self.descriptionLabel.text = printableTexts.joined(separator: ", ")
                
                self.saveImageButton.isHidden = false
            }
        }
    }
}
