//
//  VisionRequestsExtensions.swift
//  VisionDemo
//
//  Created by Semerkchet on 09/10/2021.
//

import Foundation
import Vision
import UIKit

protocol ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint]
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText]
    var generatedImages: [UIImage] { get }
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
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    var generatedImages: [UIImage] { [] }
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
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    var generatedImages: [UIImage] { [] }
}

extension VNDetectFaceLandmarksRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNFaceObservation] else { return [] }
        let landmarks = results.compactMap { [$0.landmarks?.leftEyebrow,
                                              $0.landmarks?.rightEyebrow,
                                              $0.landmarks?.faceContour,
                                              $0.landmarks?.noseCrest,
                                              $0.landmarks?.medianLine].compactMap { $0 } }
        
        return points(landmarks: landmarks, projectedOnto: image)
    }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
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
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    var generatedImages: [UIImage] { [] }
}

extension VNDetectBarcodesRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        return uniqueObservations.map { $0.boundingBox.rectangle(in: image).points
            .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
        }
    }
    
    var uniqueObservations: [VNBarcodeObservation] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNBarcodeObservation] else { return [] }
        let payloads = results.compactMap { $0.payloadStringValue }
        let uniquePayloads = Set(payloads)
        
        return uniquePayloads.compactMap { payload in
            results.filter { $0.payloadStringValue == payload }
                .sorted(by: { observationOne, observationTwo in
                    observationOne.boundingBox.area > observationTwo.boundingBox.area
                }).first
        }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] {
        uniqueObservations.compactMap { observation in
            guard let text = observation.payloadStringValue else { return nil }
            let projectedFrame = observation.boundingBox.rectangle(in: image)
            let origin = CGPoint(x: projectedFrame.origin.x,
                                 y: projectedFrame.origin.y)
            
            let frame = CGRect(origin: origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - projectedFrame.height),
                               size: projectedFrame.size)

            return DisplayableText(frame: frame,
                                   text: text)
        }
    }
    var generatedImages: [UIImage] { [] }
}

extension VNDetectFaceRectanglesRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNFaceObservation] else { return [] }
        
        return results.map { result in
            result.boundingBox.rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
        }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    var generatedImages: [UIImage] { [] }
}

extension VNDetectHumanRectanglesRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNDetectedObjectObservation] else { return [] }
        
        return results.map { result in
            result.boundingBox.rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
        }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    var generatedImages: [UIImage] { [] }
}

extension VNDetectTextRectanglesRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNTextObservation] else { return [] }
        
        return results.flatMap { result -> [[CGPoint]] in
            let textPoints = result.boundingBox.rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
            
            let charactersPoints = result.characterBoxes?
                .compactMap { observation in
                    observation.points
                        .map { $0.location(in: image) }
                        .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
                } ?? []
            
            return [textPoints] + charactersPoints
        }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    
    convenience init(reportCharacterBoxes: Bool = false) {
        self.init()
        self.reportCharacterBoxes = reportCharacterBoxes
    }
    
    var generatedImages: [UIImage] { [] }
}

extension VNRecognizeAnimalsRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNRecognizedObjectObservation] else { return [] }
        
        return results.map { result in
            result.boundingBox.rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
        }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNRecognizedObjectObservation] else { return [] }
        
        return results.map { result in
            let name = result.labels.map { $0.identifier }.first ?? "n/a"
            let projectedFrame = result.boundingBox.rectangle(in: image)
            let origin = CGPoint(x: projectedFrame.origin.x,
                                 y: projectedFrame.origin.y)
            
            let frame = CGRect(origin: origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - projectedFrame.height),
                               size: projectedFrame.size)

            return DisplayableText(frame: frame,
                                   text: name)
        }
    }
    
    var generatedImages: [UIImage] { [] }
}

extension VNGenerateAttentionBasedSaliencyImageRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNSaliencyImageObservation] else { return [] }
        
        return results.compactMap { result in
            result.salientObjects?.compactMap {
                $0.boundingBox
                .rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
            }
        }.flatMap { $0 }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    
    var generatedImages: [UIImage] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let result = results?.first as? VNSaliencyImageObservation,
              let image = result.pixelBuffer.makeImage() else { return [] }

        return [image]
    }
}

extension VNGenerateObjectnessBasedSaliencyImageRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNSaliencyImageObservation] else { return [] }
        
        return results.compactMap { result in
            result.salientObjects?.compactMap {
                $0.boundingBox
                .rectangle(in: image).points
                .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
            }
        }.flatMap { $0 }
    }
    
    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] { [] }
    
    var generatedImages: [UIImage] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let result = results?.first as? VNSaliencyImageObservation,
              let image = result.pixelBuffer.makeImage() else { return [] }

        return [image]
    }
}

extension VNClassifyImageRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    var generatedImages: [UIImage] { [] }

    func displayableTextPoints(projectedOnto image: UIImage) -> [DisplayableText] {
        // On iOS 15 and up this mapping is not needed anymore
        guard let results = results as? [VNClassificationObservation] else { return [] }
        
        return results.filter { $0.confidence > 0.7 }.map { result in
            return DisplayableText(frame: nil,
                                   text: result.identifier)
        }
    }
}

