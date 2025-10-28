//
//  EmojiSelectionView.swift
//  TranslatingText
//
//  Created by Haryanto on 28/10/25.
//  Copyright © 2025 Apple. All rights reserved.
//
import SwiftUI
import Translation
import Foundation
import AVFoundation

struct EmojiSelectionView: View {
    private let allEmojis: [String] = ["😀","😂","😍","🥺","😎","🥶","🤩","😜","🤔","😇","🥳","😡","😭","😱","🤠","🐶","🐱","🐭","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🦄","🐔","🐧","🐦","🐤","🐣","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦓","🦍","🦧","🦥","🦦","🦨","🦘","🦡","🐢","🐍","🦎","🦂","🕷","🕸","🦗","🕊","🐝","🐞","🦋","🐌","🐚","🐠","🐟","🐬","🐳","🦈","🐊","🐅","🐆"]
    private let languages: [(name: String, id: String, locale: String)] = [
        ("Indonesian", "id", "id-ID"),
        ("Korean", "ko", "ko-KR"),
        ("Portuguese", "pt", "pt-PT")
    ]
    @State private var emojis: [String] = []
    @State private var selected: Set<String> = []
    @State private var selectedLanguageIndex: Int = 0
    @State private var configuration: TranslationSession.Configuration?
    @State private var translatedText: String = ""
    @State private var isTranslating = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var showTranslation = false
    @State private var displayItems: [(text: String, languageCode: String)] = []
    
    @State private var pendingTextToTranslate: String = ""
    
    @State private var showImageGenerator = false
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Language", selection: $selectedLanguageIndex) {
                ForEach(0..<languages.count, id: \.self) { idx in
                    Text(languages[idx].name)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        toggleSelection(emoji)
                    }) {
                        Text(emoji)
                            .font(.system(size: 40))
                            .frame(width: 56, height: 56)
                            .background(selected.contains(emoji) ? Color.accentColor.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(selected.contains(emoji) ? Color.accentColor : Color.secondary, lineWidth: selected.contains(emoji) ? 3 : 1)
                            )
                    }
                    .disabled(!selected.contains(emoji) && selected.count >= 3)
                }
            }
            Button("Translate Names") {
                translateSelectedEmojis()
            }
            .disabled(selected.isEmpty)
            Text(translatedText)
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
            Button("Read Aloud") {
                // Present the system translation sheet first, similar to ViewTranslationView
                showTranslation = true
            }
            .disabled(translatedText.isEmpty)
            Button("Generate Images") {
                showImageGenerator = true
            }
            .disabled(selected.isEmpty)
            .sheet(isPresented: $showImageGenerator) {
                EmojiImageGeneratorView(emojis: Array(selected))
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear { generateRandomEmojis() }
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(pendingTextToTranslate)
                await MainActor.run {
                    translatedText = response.targetText
                    // Optionally split to show per-item play buttons
                    let parts = response.targetText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    let voice = voiceCodeForSelectedLanguage()
                    displayItems = parts.prefix(3).map { (text: String($0), languageCode: voice) }
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    translatedText = "Translation failed."
                    displayItems = []
                    isTranslating = false
                }
            }
        }
        .translationPresentation(isPresented: $showTranslation, text: translatedText)
        .padding()
        .navigationTitle("Pick up to 3 Emoji")
    }
    
    private func toggleSelection(_ emoji: String) {
        if selected.contains(emoji) {
            selected.remove(emoji)
        } else if selected.count < 3 {
            selected.insert(emoji)
        }
    }
    
    private func generateRandomEmojis() {
        emojis = Array(allEmojis.shuffled().prefix(15))
    }
    
    private func emojiName(for emoji: String) -> String {
        let scalars = emoji.unicodeScalars
        if let name = scalars.first?.properties.name {
            return name.capitalized
        } else {
            return emoji
        }
    }
    
    private func translateSelectedEmojis() {
        isTranslating = true
        translatedText = ""
        configuration?.invalidate()
        let names = selected.map { emojiName(for: $0) }
        pendingTextToTranslate = names.joined(separator: ", ")
        configuration = .init(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: languages[selectedLanguageIndex].id)
        )
    }
    
    private func voiceCodeForSelectedLanguage() -> String {
        switch languages[selectedLanguageIndex].id {
        case "id": return "id-ID"
        case "ko": return "ko-KR"
        case "pt": return "pt-PT" // or "pt-BR" if desired
        default: return "en-US"
        }
    }
    
    private func speakText(_ text: String, languageCode: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}


#Preview {
    EmojiSelectionView()
}
