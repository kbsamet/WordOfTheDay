//
//  PronunciationPlayer.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 23.03.2026.
//


import AVFoundation

class PronunciationPlayer: NSObject, ObservableObject,AVSpeechSynthesizerDelegate{
    @Published var isLoading: Bool = false
    private var player: AVPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isLoading = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
          Task { @MainActor in
              isLoading = false
          }
      }
    
    func play(word: String, language: WiktionaryLanguage) async {
        if isLoading{
            return
        }
        guard let audioURL = await fetchAudioURL(word: word, language: language) else {
            isLoading = true
            await speakFallback(word: word, language: language)
            return
        }

        await MainActor.run {
            player = AVPlayer(url: audioURL)
            player?.play()

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.isLoading = false
            }
        }
    }

    private func fetchAudioURL(word: String, language: WiktionaryLanguage) async -> URL? {
        isLoading = true
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://en.wiktionary.org/w/api.php?action=parse&page=\(encoded)&prop=wikitext&format=json"

        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let parse = json["parse"] as? [String: Any],
              let wikitext = parse["wikitext"] as? [String: Any],
              let content = wikitext["*"] as? String
        else { return nil }

        let pattern = #"\{\{[Aa]udio\|[a-z-]+\|([^}|]+\.(?:ogg|OGG|mp3|MP3|wav|WAV))"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let fileRange = Range(match.range(at: 1), in: content)
        else { return nil }

        let filename = String(content[fileRange])
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")

        return URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(filename)")
    }
    
    @MainActor
    private func speakFallback(word: String, language: WiktionaryLanguage) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: language.localeCode)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
        
    }
}
