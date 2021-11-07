//: [Previous](@previous)

var readThisFirst = "⚠️ Playgrounds are dependent on the project so you need to build the project first before using them."
var readThisSecond = "⚠️ If you are using M1 and run Xcode using Rosetta playgrounds won't work https://twitter.com/kwcodes/status/1451275902772461571"

import UIKit
import SoundAnalysis

/*
 
 Uncomment if you want to see list of identifiers
 
(try? SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1))?.knownClassifications
    .enumerated()
    .forEach { index, identifier in print("\(index). \(identifier)") }
*/

final class AudioAnalysisObserver: NSObject, SNResultsObserving {
    func requestDidComplete(_ request: SNRequest) {
        print("Processing completed!")
    }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let bestClassification = result.classifications.first else  { return }
        let timeStart = result.timeRange.start.seconds
        
        print("Found \(bestClassification.identifier) at \(Int((bestClassification.confidence) * 100))% at \(timeStart)s")
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Failed with \(error)")
    }
}

enum FileError: Error {
    case notFound
}

do {
    //Sound from Zapsplat.com - https://www.zapsplat.com/music/approaching-thunderstorm-with-light-rain/
    guard let fileUrl = Bundle.main.url(forResource: "storm", withExtension: "mp3") else { throw FileError.notFound }
    let soundClassifyRequest = try SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1)

    let audioFileAnalyzer = try SNAudioFileAnalyzer(url: fileUrl)
    let resultsObserver = AudioAnalysisObserver()
    try audioFileAnalyzer.add(soundClassifyRequest, withObserver: resultsObserver)
    
    audioFileAnalyzer.analyze()
} catch {
    print("Something went terribly wrong!")
}

//: [Next](@next)
