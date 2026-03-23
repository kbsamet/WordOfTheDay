//
//  WordOfTheDayWidget.swift
//  WordOfTheDayWidget
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WordEntry {
        WordEntry(
            date: Date(),
            data: WordEntryData(
                word: "Example",
                definition: "A representative form or pattern.",
                language: "English",
                level: "Beginner"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        completion(loadEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.kbsamet.WordCache")!
        let selectedLevel: LanguageLevel = LanguageLevel(rawValue: defaults.string(forKey: "selectedLevel") ?? "") ?? .beginner
        let selectedLanguage: WiktionaryLanguage = WiktionaryLanguage(rawValue: defaults.string(forKey: "selectedLanguage") ?? "") ?? .english

        let words = WordPoolLoader.loadWords(language: selectedLanguage, level: selectedLevel)

        Task {
            // Prefetch the week so future refreshes hit cache even if offline
            await WordOfTheDayEngine.generateWeeklyEntries(
                words: words,
                language: selectedLanguage,
                level: selectedLevel.rawValue
            )

            let entry = await WordOfTheDayEngine.loadWordOfTheDay(
                words: words,
                language: selectedLanguage,
                level: selectedLevel.rawValue
            )

            let widgetEntry = WordEntry(date: Date(), data: WordEntryData(
                word: entry.word,
                definition: entry.definition,
                language: entry.language,
                level: entry.level
            ))

            let nextUpdate = Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 0),
                matchingPolicy: .nextTime
            )!

            completion(Timeline(entries: [widgetEntry], policy: .after(nextUpdate)))
        }
    }

    private func loadEntry() -> WordEntry {
        if let cached = WordCache.shared.load(for: WordOfTheDayEngine.todayKey()) {
            return WordEntry(date: Date(), data: WordEntryData(word: cached.word, definition: cached.definition, language: cached.language, level: cached.level))
        }
        return WordEntry(date: Date(), data: WordEntryData(
            word: "Loading...",
            definition: "Fetching today's word",
            language: "",
            level: ""
        ))
    }
}

// ── Shared colors ────────────────────────────────────────────────────────────
private let oxfordBlue    = AppColor.color("oxfordBlue")
private let cardBlue      = AppColor.color("cardBlue")
private let cardBlueDark  = AppColor.color("cardBlueDark")
private let gold          = AppColor.color("gold")

struct WordWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var definitions: [String] {
        entry.data?.definition
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? []
    }

    var body: some View {
        if let data = entry.data {
            switch family {

            case .accessoryInline:
                Text(DefinitionWithLinks(from: data.definition).plainText)
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

            case .accessoryCircular:
                ZStack {
                    Circle()
                        .stroke(gold.opacity(0.35), lineWidth: 0.5)

                    VStack(spacing: 1) {
                        Text(data.word.prefix(4))
                            .font(.system(size: 13, weight: .semibold, design: .serif).italic())
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
                .containerBackground(for: .widget) { oxfordBlue }

            // ── Lock screen: rectangular ──────────────────────────────────
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(data.word)
                        .font(.system(size: 14, weight: .semibold, design: .serif).italic())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(DefinitionWithLinks(from: data.definition
                        .components(separatedBy: "\n")
                        .first ?? data.definition).plainText)
                        .font(.system(size: 9, weight: .regular).monospaced())
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }
                .containerBackground(for: .widget) { oxfordBlue }

            // ── Home screen: medium / large ───────────────────────────────
            default:
                homeWidgetView(data: data)
            }
        } else {
            Text("No word yet")
                .font(.system(size: 13, weight: .regular, design: .serif).italic())
                .foregroundStyle(.white.opacity(0.4))
                .containerBackground(for: .widget) { oxfordBlue }
        }
    }

    @ViewBuilder
    private func homeWidgetView(data: WordEntryData) -> some View {
        // Calculate how many definitions can fit based on widget family
        let definitionsToShow: Int = {
            switch family {
            case .systemMedium:
                // Medium: limit to 2 definitions with multiline support
                return min(definitions.count, 2)
            case .systemLarge:
                // Large: limit to 5 definitions with multiline support
                return min(definitions.count, 5)
            default:
                return definitions.count
            }
        }()
        
        let visibleDefinitions = Array(definitions.prefix(definitionsToShow))
        
        ZStack {

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {

                    HStack(spacing: 6) {
                        Text("word of the day")
                            .font(.system(size: 7, weight: .regular).monospaced())
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.28))
                            .textCase(.uppercase)

                        Spacer()

                        Text(data.language.isEmpty ? "" : data.language)
                            .font(.system(size: 7, weight: .regular).monospaced())
                            .tracking(2)
                            .foregroundStyle(gold.opacity(0.6))
                            .textCase(.uppercase)
                    }
                    .padding(.bottom, 8)

                    Text(data.word.capitalized)
                        .font(.system(size: 28, weight: .semibold, design: .serif).italic())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .padding(.bottom, 4)

                    Rectangle()
                        .fill(gold.opacity(0.5))
                        .frame(width: 28, height: 0.75)
                        .padding(.bottom, 10)

                     VStack(alignment: .leading, spacing: 6) {
                         ForEach(Array(visibleDefinitions.enumerated()), id: \.offset) { index, def in
                             HStack(alignment: .top, spacing: 8) {
                                 ZStack {
                                     Circle()
                                         .fill(.white.opacity(0.08))
                                         .frame(width: 18, height: 18)
                                     Text("\(index + 1)")
                                         .font(.system(size: 8, weight: .regular).monospaced())
                                         .foregroundStyle(.white.opacity(0.6))
                                 }
                                 .padding(.top, 0.5)
                                 
                                 // Display definition text with links preserved as plain text
                                 // (widgets don't support interactive links)
                                 Text(DefinitionWithLinks(from: def).plainText)
                                     .font(.system(size: 10, weight: .regular, design: .serif))
                                     .foregroundStyle(.white.opacity(0.68))
                                     .lineSpacing(2)
                                     .fixedSize(horizontal: false, vertical: true)
                                 
                                 Spacer()
                            }
                         }
                     }

                    Spacer()
                }
                Spacer()
            }
            .padding(18)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [cardBlueDark, cardBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct WordOfTheDayWidget: Widget {
    let kind = "WordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WordWidgetView(entry: entry)
        }
        .configurationDisplayName("Word of the Day")
        .description("Learn a new word every day.")
        .supportedFamilies([
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    WordOfTheDayWidget()
} timeline: {
    WordEntry(
        date: .now,
        data: WordEntryData(
            word: "Anleihe",
            definition: "An interest-bearing security; a company or state borrows money from the public.\nA sum of money that is borrowed.\nA sum of money that is borrowed.\nA sum of money that is borrowed.\nA sum of money that is borrowed.\nA sum of money that is borrowed.",
            language: "German",
            level: "Intermediate"
        )
    )
}
