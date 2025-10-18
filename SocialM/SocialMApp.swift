import SwiftUI

@main
struct SocialMApp: App {
    @State private var isLoggedIn = false

    @State private var selectedAudioURL: URL? = nil
    @State private var selectedAudioTitle: String = ""
    @State private var selectedAudioArtist: String = ""
    @State private var selectedAudioDuration: Double = 0
    @State private var isPresented: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
