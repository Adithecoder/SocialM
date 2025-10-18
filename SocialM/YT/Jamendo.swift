// MusicSearchView.swift - MŰKÖDŐ PREVIEW
import SwiftUI
import AVFoundation

struct MusicSearchView: View {
    @Binding var selectedAudioURL: URL?
    @Binding var selectedAudioTitle: String?
    @Binding var selectedAudioArtist: String?
    @Binding var selectedAudioDuration: Double?
    @Binding var isPresented: Bool
    @Binding var selectedAudioCoverURL: URL? // 👈 ÚJ: Borítókép binding
    @State private var searchText = ""
    @State private var searchResults: [MusicTrack] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Minta adatok - működik API nélkül is
    private let sampleTracks = [
        MusicTrack(
            id: "1",
            title: "Epic Adventure",
            artist: "Audio Library",
            album: "Royalty Free Music",
            duration: 180,
            audioURL: URL(string: "https://www.soundjay.com/misc/sounds/fail-buzzer-02.mp3")!, // Minta hang
            coverURL: URL(string: "https://via.placeholder.com/150")
        ),
        MusicTrack(
            id: "2",
            title: "Summer Vibes",
            artist: "No Copyright Sounds",
            album: "NCS Releases",
            duration: 210,
            audioURL: URL(string: "https://www.soundjay.com/misc/sounds/fail-buzzer-02.mp3")!,
            coverURL: URL(string: "https://via.placeholder.com/150")
        ),
        MusicTrack(
            id: "3",
            title: "Chill Lo-Fi",
            artist: "Lofi Girl",
            album: "Study Beats",
            duration: 240,
            audioURL: URL(string: "https://www.soundjay.com/misc/sounds/fail-buzzer-02.mp3")!,
            coverURL: URL(string: "https://via.placeholder.com/150")
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Kereső mező
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 30)
                        .symbolEffect(.breathe)
                        .foregroundStyle( searchText.isEmpty ? (LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.4)]), startPoint: .leading, endPoint: .trailing))
                    :
                    
                    (LinearGradient(gradient: Gradient(colors: [.mint.opacity(0.4), .blue]), startPoint: .leading, endPoint: .trailing)))
                        .symbolEffect(.bounce.down.wholeSymbol, options: .nonRepeating)
                        .padding(.horizontal,5)
                    
                    TextField("Keress zenét!", text: $searchText)
                        .font(.custom("Jellee", size: 16))
                        .padding(10)
                        .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke( searchText.isEmpty ? (LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.4)]), startPoint: .leading, endPoint: .trailing))
                        :
                        
                        (LinearGradient(gradient: Gradient(colors: [.mint.opacity(0.4), .blue]), startPoint: .leading, endPoint: .trailing)), lineWidth: 3)
                        )
                    Button("Keresés")
                    {
                        searchMusic()
                    }
                    .padding(10)
                    .font(.custom("Jellee", size:16))

                    .disabled(searchText.isEmpty)
                    .foregroundStyle(searchText.isEmpty ? Color.white : .white)
                    .background( searchText.isEmpty ? LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing) :
                                    
                                    LinearGradient(gradient: Gradient(colors: [.mint.opacity(0.4), .blue]), startPoint: .leading, endPoint: .trailing))
                    
                    .cornerRadius(15)
                }
                .padding()
                
                if isLoading {
                        ProgressView("Zenék keresése...")
                            .font(.lexend())
                    
                }
                
                if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                        Text(error)
                            .font(.custom("Jellee", size:16))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        // Minta zenék megjelenítése hibánál
                        Text("Most trendi:")
                            .font(.lexend())
                            .padding(.top, 5)
                    }
                }
                
                // Eredmények listája
                List(searchResults.isEmpty && !isLoading ? sampleTracks : searchResults) { track in
                    MusicTrackRow(track: track) {
                        selectTrack(track)
                    }
                }
                

                
                Spacer()
            }
            .navigationTitle("Zene Keresés")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Mégse") {
                    isPresented = false
                },
                trailing: Button("Demo") {
                    // Demo keresés
                    searchText = "electronic"
                    searchMusic()
                }
            )
            .onAppear {
                // Automatikus demo betöltés
                searchResults = sampleTracks
            }
        }
    }
    
    private func searchMusic() {
        isLoading = true
        errorMessage = nil
        
        // Először próbáljuk meg a valódi API-t
        MusicAPIManager.shared.searchTracks(query: searchText) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let tracks):
                    if tracks.isEmpty {
                        self.errorMessage = "Nincs találat a(z) '\(self.searchText)' kifejezésre"
                        self.searchResults = self.sampleTracks
                    } else {
                        self.searchResults = tracks
                    }
                    
                case .failure(let error):
                    // Ha az API nem működik, mutassuk a mintákat
                    self.errorMessage = "Demo mód: \(error.localizedDescription)"
                    self.searchResults = self.sampleTracks
                }
            }
        }
    }
    
    private func selectTrack(_ track: MusicTrack) {
        selectedAudioURL = track.audioURL
        selectedAudioTitle = track.title
        selectedAudioArtist = track.artist
        selectedAudioDuration = Double(track.duration)
        selectedAudioCoverURL = track.coverURL
        isPresented = false
        
        print("✅ Zene kiválasztva: \(track.title) - \(track.artist)")
    }
}

struct MusicTrackRow: View {
    let track: MusicTrack
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Album borító
                AsyncImage(url: track.coverURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [.mint.opacity(0.4), .blue]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.custom("Lexend", size: 16))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    //                    Text(track.artist)
                    //                        .font(.custom("Lexend", size: 14))
                    //                        .foregroundColor(.secondary)
                    
                    HStack {
                        if let album = track.album {
                            Text(album)
                                .font(.custom("Jellee", size:10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                HStack{
                    Text(formatTime(Double(track.duration)))
                        .font(.custom("Jellee", size:14))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.mint.opacity(0.4), .blue]), startPoint: .leading, endPoint: .trailing))
                        .font(.title2)
                    
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MusicAPIManager.swift - TELJESEN CSERÉLD LE EZZEL:
class MusicAPIManager {
    static let shared = MusicAPIManager()
    
    // 👇 IDE JD A TE KULCSOD - BIZTOSAN
    private let jamendoClientID = "e324aa7e"
    
    private init() {}
    
    func searchTracks(query: String, completion: @escaping (Result<[MusicTrack], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(MusicError.invalidQuery))
            return
        }
        
        // 👇 JAVÍTOTT URL - egyszerűbb verzió
        let urlString = "https://api.jamendo.com/v3.0/tracks/?client_id=\(jamendoClientID)&format=json&search=\(encodedQuery)&limit=10"
        
        print("🔍 API hívás: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(.failure(MusicError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Hálózati hiba: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ Nincs adat")
                completion(.failure(MusicError.noData))
                return
            }
            
            // Debug: nézzük meg mit kapunk
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 API válasz: \(responseString)")
            }
            
            do {
                let jamendoResponse = try JSONDecoder().decode(JamendoResponse.self, from: data)
                print("✅ \(jamendoResponse.results.count) zene betöltve")
                
                let tracks = jamendoResponse.results.map { jamendoTrack in
                    MusicTrack(
                        id: jamendoTrack.id,
                        title: jamendoTrack.name,
                        artist: jamendoTrack.artist_name,
                        album: jamendoTrack.album_name,
                        duration: jamendoTrack.duration,
                        audioURL: URL(string: jamendoTrack.audio)!,
                        coverURL: URL(string: jamendoTrack.album_image ?? jamendoTrack.image)
                    )
                }
                
                completion(.success(tracks))
                
            } catch {
                print("❌ JSON hiba: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// MARK: - Modellek
struct MusicTrack: Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: Int
    let audioURL: URL
    let coverURL: URL?
}

struct JamendoResponse: Codable {
    let results: [JamendoTrack]
}

struct JamendoTrack: Codable {
    let id: String
    let name: String
    let artist_name: String
    let album_name: String?
    let duration: Int
    let audio: String
    let image: String
    let album_image: String?
}

enum MusicError: Error, LocalizedError {
    case noAPIKey
    case invalidQuery
    case invalidURL
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Jamendo API kulcs nincs beállítva"
        case .invalidQuery:
            return "Érvénytelen keresési kifejezés"
        case .invalidURL:
            return "Érvénytelen URL"
        case .noData:
            return "Nincs adat a szervertől"
        }
    }
}

// MARK: - Preview
//#Preview("Music Search") {
//    MusicSearchView(
//        selectedAudioURL: .constant(nil),
//        selectedAudioTitle: .constant(nil),
//        selectedAudioArtist: .constant(nil),
//        selectedAudioDuration: .constant(nil),
//        isPresented: .constant(true)
//    )
//}

#Preview("Music Track Row") {
    List {
        MusicTrackRow(
            track: MusicTrack(
                id: "1",
                title: "Epic Adventure Music",
                artist: "Audio Library",
                album: "Royalty Free",
                duration: 180,
                audioURL: URL(string: "https://example.com/track.mp3")!,
                coverURL: URL(string: "https://via.placeholder.com/150")
            )
        ) {
            print("Track selected!")
        }
    }
}
