/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to initiate the downloading of languages
 necessary to perform a translation.
*/

import SwiftUI
import Translation


struct PrepareTranslationView: View {

    // Define the pairing of languages you want to download.
    @State private var configuration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "pt_BR"),
        target: Locale.Language(identifier: "ko_KR")
    )

    @State private var buttonTapped = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap the button to start downloading languages before offering a translation.")
            Button("Prepare") {
                configuration.invalidate()
                buttonTapped = true
            }
        }
        .translationTask(configuration) { session in
            if buttonTapped {
                do {
                    // Display a sheet asking the user's permission
                    // to start downloading the language pairing.
                    try await session.prepareTranslation()
                } catch {
                    // Handle any errors.
                }
            }
        }
        .padding()
        .navigationTitle("Prepare translation")
    }
}

struct BahasaToEnglishTranslationView: View {
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var configuration: TranslationSession.Configuration?
    @State private var isTranslating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Type in Bahasa Indonesia", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                Button("Translate to English") {
                    triggerTranslation()
                }
                .disabled(inputText.isEmpty || isTranslating)
                if !translatedText.isEmpty {
                    Text("Translated: \n\(translatedText)")
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Bahasa to English")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(inputText)
                translatedText = response.targetText
            } catch {
                translatedText = "Translation failed."
            }
            isTranslating = false
        }
    }

    func triggerTranslation() {
        isTranslating = true
        translatedText = ""
        // This sets the language pairing: id (Indonesian) to en (English)
        configuration = .init(source: Locale.Language(identifier: "id"), target: Locale.Language(identifier: "en"))
    }
}



#Preview {
    PrepareTranslationView()
}
