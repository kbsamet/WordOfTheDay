//
//  WordCache.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 27.01.2026.
//

import Foundation

final class WordCache {
    static let shared = WordCache()

    private let defaults = UserDefaults(suiteName: "group.kbsamet.WordCache")!

    func save(_ entry: WordEntryData, for key: String) {
        if let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: key)
        }
    }

    func load(for key: String) -> WordEntryData? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WordEntryData.self, from: data)
    }

    func reset() {
        defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
    }
}
