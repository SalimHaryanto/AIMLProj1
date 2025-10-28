/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view that creates all the demos for the app.
*/

import SwiftUI

struct ContentView: View {
    @State private var showImageGenerator = false
    @State private var sampleEmojis: [String] = ["😀", "🐶", "🌸"]

    var body: some View {
        NavigationStack {
            List {
//                Section {
//                    NavigationLink {
//                        ViewTranslationView()
//                    } label: {
//                        RowView(title: "Translate Text",
//                                subtitle: "Translate a single phrase.",
//                                imageName: "arrow.left.arrow.right")
//                    }
//
//                    NavigationLink {
//                        ReplaceTranslationView()
//                    } label: {
//                        RowView(title: "Replace Text",
//                                subtitle: "Replace text with the translated result.",
//                                imageName: "arrow.circlepath")
//                    }
//                } header: {
//                    Text("System UI Translations")
//                }
//
//                Section {
//                    NavigationLink {
//                        SingleStringView()
//                    } label: {
//                        RowView(title: "Single String",
//                                subtitle: "Translate a single string of text.",
//                                imageName: "arrow.left.arrow.right")
//                    }
//                    
//                    NavigationLink {
//                        BatchOfStringsView()
//                    } label: {
//                        RowView(title: "Batch All at Once",
//                                subtitle: "Translate a batch of strings.",
//                                imageName: "line.3.horizontal")
//                    }
//
//                    NavigationLink {
//                        BatchAsSequenceView()
//                    } label: {
//                        RowView(title: "Batch as a Sequence",
//                                subtitle: "Translate strings as a sequence.",
//                                imageName: "line.3.horizontal.decrease")
//                    }
//                } header: {
//                    Text("Custom UI Translations")
//                }
//                
//                Section {
//                    NavigationLink {
//                        LanguageAvailabilityView()
//                    } label: {
//                        RowView(title: "Language Availability",
//                                subtitle: "Check whether a translation can occur.",
//                                imageName: "lightswitch.on")
//                    }
//
//                    NavigationLink {
//                        PrepareTranslationView()
//                    } label: {
//                        RowView(title: "Prepare for Translation",
//                                subtitle: "Initiate a language download.",
//                                imageName: "arrow.down.circle")
//                    }
//                } header: {
//                    Text("Availability")
//                }
//                
//                Section {
//                    NavigationLink {
//                        BahasaToEnglishTranslationView()
//                    } label: {
//                        RowView(title: "Bahasa ➔ English",
//                                subtitle: "Type Bahasa Indonesia and translate to English",
//                                imageName: "character.cursor.ibeam")
//                    }
//                } header: {
//                    Text("Manual Translation")
//                }

                Section {
                    NavigationLink {
                        EmojiSelectionView()
                    } label: {
                        RowView(title: "Emoji Picker",
                                subtitle: "Select and view your favorite emoji",
                                imageName: "face.smiling")
                    }
                    Button {
                        showImageGenerator = true
                    } label: {
                        RowView(title: "Generate Images",
                                subtitle: "Create 2 images per emoji in a sheet",
                                imageName: "photo.on.rectangle")
                    }
                    .sheet(isPresented: $showImageGenerator) {
                        EmojiImageGeneratorView(emojis: sampleEmojis)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                } header: {
                    Text("Fun")
                }
            }
            .navigationTitle("Translation Demos")
        }
    }
}

#Preview {
    ContentView()
}
