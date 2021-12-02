//: [Previous](@previous)

import AVFoundation

print(AVSpeechSynthesisVoice.speechVoices())

let englishUtterance = AVSpeechUtterance(string: "Bake the chicken in the oven for fifteen minutes")
englishUtterance.prefersAssistiveTechnologySettings = true

// You can experiment to hear the difference
//englishUtterance.rate = 0.8
//englishUtterance.pitchMultiplier = 0.1
//englishUtterance.postUtteranceDelay = 0.2
//englishUtterance.preUtteranceDelay = 0.2
//englishUtterance.volume = 1.0

//let englishVoice = AVSpeechSynthesisVoice(language: "en-US")
//englishUtterance.voice = englishVoice
let synthesizer = AVSpeechSynthesizer()
synthesizer.usesApplicationAudioSession = false
synthesizer.speak(englishUtterance)

let polishUtterance = AVSpeechUtterance(string: "Piecz kurczaka w piekarniku przez piętnaście minut")
polishUtterance.prefersAssistiveTechnologySettings = true

let polishVoice = AVSpeechSynthesisVoice(language: "pl-PL")
polishUtterance.voice = polishVoice
//let synthesizer = AVSpeechSynthesizer()
synthesizer.usesApplicationAudioSession = false
synthesizer.speak(polishUtterance)


//: [Next](@next)
