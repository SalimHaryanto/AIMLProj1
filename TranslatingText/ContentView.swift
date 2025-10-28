/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view that creates all the demos for the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            EmojiSelectionView()
        }
    }
}

#Preview {
    ContentView()
}
