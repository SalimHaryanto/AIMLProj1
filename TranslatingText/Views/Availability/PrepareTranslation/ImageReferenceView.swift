//
//  ImageReferenceView.swift
//  TranslatingText
//
//  Created by Haryanto on 27/10/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import ImagePlayground

struct ImagePlaygroundView: View {
    @State var generatedImages: [CGImage]?
    @State var isGenerationStarted: Bool = false
    @State var prompt: String = ""

    var body: some View {
        VStack(alignment: .center) {


            if let image = generatedImages {
                VStack(){
                    ForEach(image, id: \.self){ selectedImage in
                        Image(uiImage: UIImage(cgImage: selectedImage))
                            .resizable()
                            .frame(width: 200, height: 200)
                    }
                }
            } else if isGenerationStarted {
                ProgressView()
            } else {
                ContentUnavailableView {
                    Label("Start creating beautiful images", systemImage: "apple.intelligence")
                } actions: {
                    TextField("Prompt:", text: $prompt)
                    Button("Generate"){
                        isGenerationStarted.toggle()
                        Task {
                            try await generateImage()
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .padding()
                }
            }
        }
    }

    func generateImage() async throws {
        do {
            let imageCreator = try await ImageCreator()
            let generationStyle = ImagePlaygroundStyle.sketch


            let images = imageCreator.images(
                for: [.text("\(prompt)")],
                style: generationStyle,
                limit: 3)

            for try await image in images {
                if let generatedImages = generatedImages {
                    self.generatedImages = generatedImages + [image.cgImage]
                }
                else {
                    self.generatedImages = [image.cgImage]
                }
            }

        }
        catch ImageCreator.Error.notSupported {
            print("Image creation not supported on the current device.")
        }
    }
}

#Preview {
    ContentView()
}
