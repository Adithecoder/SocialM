//
//  MusicShareView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20.
//

//import SwiftUI
//import AVKit
//
//// MARK: - Enhanced Music Models
//struct SharedSong: Identifiable {
//    let id = UUID()
//    let title: String
//    let artist: String
//    let album: String
//    let albumArt: String
//    let previewURL: URL?
//    let spotifyURL: URL?
//    let appleMusicURL: URL?
//    let sharedBy: String
//    let sharedAt: Date
//    let likes: Int
//    let userLiked: Bool
//    let genre: String
//    let mood: MusicMood
//    let duration: String
//    let bpm: Int? // 👈 ÚJ: Ütem
//}
//
//enum MusicMood: String, CaseIterable {
//    case energetic = "⚡ Energetikus"
//    case chill = "😌 Chill"
//    case focused = "🎯 Fókuszált"
//    case workout = "💪 Edzés"
//    case gaming = "🎮 Gaming"
//    case driving = "🚗 Útizene"
//    case party = "🎉 Party"
//    case nostalgic = "🕰️ Nosztalgikus"
//}
//struct SongShareView: View {
//    @Environment(\.dismiss) private var dismiss
//    let onShare: (SharedSong) -> Void
//    @State private var songTitle = ""
//    @State private var artist = ""
//    @State private var album = ""
//    @State private var selectedMood: MusicMood = .chill
//    @State private var genre = ""
//    @State private var youtubeURL = ""
//    @State private var showYouTubeFields = false
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Alap információk")) {
//                    TextField("Szám címe", text: $songTitle)
//                    TextField("Előadó", text: $artist)
//                    TextField("Album", text: $album)
//                    TextField("Műfaj", text: $genre)
//                }
//
//                Section(header: Text("YouTube Link (opcionális)")) {
//                    Toggle("YouTube videó hozzáadása", isOn: $showYouTubeFields)
//
//                    if showYouTubeFields {
//                        TextField("YouTube URL", text: $youtubeURL)
//                            .keyboardType(.URL)
//                            .autocapitalization(.none)
//
//                        if !youtubeURL.isEmpty {
//                            Text("A YouTube videó megjelenik a megosztásban")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                        }
//                    }
//                }
//
//                Section(header: Text("Hangulat")) {
//                    Picker("Hangulat", selection: $selectedMood) {
//                        ForEach(MusicMood.allCases, id: \.self) { mood in
//                            Text(mood.rawValue).tag(mood)
//                        }
//                    }
//                    .pickerStyle(.navigationLink)
//                }
//            }
//            .navigationTitle("Zene megosztása")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Mégse") {
//                        dismiss()
//                    }
//                }
//
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Megosztás") {
//                        let youtubeID = extractYouTubeID(from: youtubeURL)
//
//                        let newSong = SharedSong(
//                            title: songTitle,
//                            artist: artist,
//                            album: album,
//                            albumArt: "",
//                            previewURL: nil,
//                            spotifyURL: nil,
//                            appleMusicURL: nil,
//                            sharedBy: UserDefaults.standard.string(forKey: //"username") ?? "Felhasználó",
//                            sharedAt: Date(),
//                            likes: 0,
//                            userLiked: false,
//                            genre: genre,
//                            mood: selectedMood,
//                            duration: "",
//                            bpm: nil
//                        )
//                        onShare(newSong)
//                        dismiss()
//                    }
//                    .disabled(songTitle.isEmpty || artist.isEmpty)
//                }
//            }
//        }
//    }
//
//    private func extractYouTubeID(from url: String) -> String? {
//        // Simple YouTube ID extraction
//        let patterns = [
//            "youtube.com/watch?v=([a-zA-Z0-9_-]+)",
//            "youtu.be/([a-zA-Z0-9_-]+)",
//            "youtube.com/embed/([a-zA-Z0-9_-]+)"
//        ]
//
//        for pattern in patterns {
//            if let regex = try? NSRegularExpression(pattern: pattern),
//               let match = regex.firstMatch(in: url, range: //NSRange(url.startIndex..., in: url)),
//               let range = Range(match.range(at: 1), in: url) {
//                return String(url[range])
//            }
//        }
//        return nil
//    }
//}
//struct MusicSearchView: View {
//    @Binding var sharedSongs: [SharedSong]
//    @Environment(\.dismiss) private var dismiss
//    @State private var searchText = ""
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Search implementation would go here
//                // This would integrate with Spotify/Apple Music API
//                Text("Zene keresés - Spotify/Apple Music integráció")
//                    .font(.lexend())
//                    .foregroundColor(.secondary)
//                    .padding()
//
//                Spacer()
//            }
//            .navigationTitle("Zene keresés")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Kész") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//// MARK: - Main Music View
//struct MusicShareView: View {
//    @State private var sharedSongs: [SharedSong] = []
//    @State private var currentPlayingSong: SharedSong?
//    @State private var isPlaying = false
//    @State private var showShareSheet = false
//    @State private var showSearch = false
//    @State private var searchText = ""
//    @State private var selectedMood: MusicMood?
//    @State private var player: AVPlayer?
//    @State private var showNowPlaying = false
//
//    // Mock data - csak zenei tartalom
//    private let mockSongs = [
//        SharedSong(
//            title: "Blinding Lights",
//            artist: "The Weeknd",
//            album: "After Hours",
//            albumArt: "weeknd_after_hours",
//            previewURL: URL(string: "https://p.scdn.co/mp3-preview/1"),
//            spotifyURL: URL(string: //"https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b"),
//            appleMusicURL: URL(string: "https://music.apple.com/track/1495895123"),
//            sharedBy: "Márk",
//            sharedAt: Date().addingTimeInterval(-3600),
//            likes: 24,
//            userLiked: false,
//            genre: "Synthwave",
//            mood: .energetic,
//            duration: "3:20",
//            bpm: 108
//        ),
//        SharedSong(
//            title: "Sicko Mode",
//            artist: "Travis Scott",
//            album: "ASTROWORLD",
//            albumArt: "travis_astroworld",
//            previewURL: URL(string: "https://p.scdn.co/mp3-preview/2"),
//            spotifyURL: URL(string: //"https://open.spotify.com/track/2xLMifQCjDGFmkHkpNLD9h"),
//            appleMusicURL: URL(string: "https://music.apple.com/track/1435413215"),
//            sharedBy: "Bence",
//            sharedAt: Date().addingTimeInterval(-7200),
//            likes: 18,
//            userLiked: true,
//            genre: "Hip-Hop",
//            mood: .gaming,
//            duration: "5:12",
//            bpm: 85
//        ),
//        SharedSong(
//            title: "Take What You Want",
//            artist: "Post Malone ft. Ozzy Osbourne",
//            album: "Hollywood's Bleeding",
//            albumArt: "post_malone_bleeding",
//            previewURL: URL(string: "https://p.scdn.co/mp3-preview/3"),
//            spotifyURL: URL(string: //"https://open.spotify.com/track/2GYBs4dL6kvyBO9ysB9TqL"),
//            appleMusicURL: URL(string: "https://music.apple.com/track/1478300591"),
//            sharedBy: "Dávid",
//            sharedAt: Date().addingTimeInterval(-10800),
//            likes: 32,
//            userLiked: false,
//            genre: "Rock",
//            mood: .workout,
//            duration: "3:49",
//            bpm: 120
//        ),
//        SharedSong(
//            title: "God's Plan",
//            artist: "Drake",
//            album: "Scorpion",
//            albumArt: "drake_scorpion",
//            previewURL: URL(string: "https://p.scdn.co/mp3-preview/4"),
//            spotifyURL: URL(string: //"https://open.spotify.com/track/6DCZcSspjsKoFjzjrWoCdn"),
//            appleMusicURL: URL(string: "https://music.apple.com/track/1349263507"),
//            sharedBy: "Gábor",
//            sharedAt: Date().addingTimeInterval(-14400),
//            likes: 45,
//            userLiked: true,
//            genre: "Hip-Hop",
//            mood: .driving,
//            duration: "3:18",
//            bpm: 78
//        )
//    ]
//
//    // 👇 FIÚSABB GRADIENTEK
//    private let primaryGradient = LinearGradient(
//        colors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.8, green: //0.2, blue: 0.1)],
//        startPoint: .topLeading,
//        endPoint: .bottomTrailing
//    )
//
//    private let secondaryGradient = LinearGradient(
//        colors: [Color(red: 0.2, green: 0.1, blue: 0.4), Color(red: 0.9, green: //0.4, blue: 0.0)],
//        startPoint: .top,
//        endPoint: .bottom
//    )
//
//    private let cardGradient = LinearGradient(
//        colors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.3, green: //0.2, blue: 0.1)],
//        startPoint: .topLeading,
//        endPoint: .bottomTrailing
//    )
//
//    var filteredSongs: [SharedSong] {
//        var songs = sharedSongs
//
//        if let mood = selectedMood {
//            songs = songs.filter { $0.mood == mood }
//        }
//
//        if !searchText.isEmpty {
//            songs = songs.filter {
//                $0.title.localizedCaseInsensitiveContains(searchText) ||
//                $0.artist.localizedCaseInsensitiveContains(searchText) ||
//                $0.genre.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//
//        return songs
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // 👇 Sötét, fiús háttér
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color(red: 0.05, green: 0.05, blue: 0.1),
//                        Color(red: 0.1, green: 0.05, blue: 0.05)
//                    ]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//
//                VStack(spacing: 0) {
//                    // Header
//                    headerSection
//
//                    // Main Content
//                    ScrollView {
//                        LazyVStack(spacing: 20) {
//                            // Quick Stats
//                            quickStatsSection
//
//                            // Mood Filter Chips
//                            moodFilterSection
//
//                            // Featured Songs
//                            featuredSongsSection
//
//                            // Recent Shares
//                            recentSharesSection
//                        }
//                        .padding()
//                    }
//                }
//
//                // Now Playing View
//                if showNowPlaying, let currentSong = currentPlayingSong {
//                    NowPlayingView(
//                        song: currentSong,
//                        isPlaying: $isPlaying,
//                        isPresented: $showNowPlaying
//                    )
//                    .transition(.move(edge: .bottom))
//                }
//            }
//            .navigationBarHidden(true)
//            .sheet(isPresented: $showSearch) {
//                MusicSearchView(sharedSongs: $sharedSongs)
//            }
//            .sheet(isPresented: $showShareSheet) {
//                SongShareView(onShare: { song in
//                    sharedSongs.insert(song, at: 0)
//                })
//            }
//            .onAppear {
//                loadMusicData()
//            }
//        }
//    }
//
//    // MARK: - Subviews
//
//    private var headerSection: some View {
//        VStack(spacing: 16) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text("BEATSHARE")
//                        .font(.custom("OrelegaOne-Regular", size: 28))
//                        .foregroundStyle(primaryGradient)
//
//                    Text("Férfiak zenéje")
//                        .font(.lexend2())
//                        .foregroundColor(.gray)
//                }
//
//                Spacer()
//
//                HStack(spacing: 20) {
//                    Button(action: { showSearch.toggle() }) {
//                        Image(systemName: "magnifyingglass")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                            .padding(8)
//                            .background(Color.white.opacity(0.1))
//                            .clipShape(Circle())
//                    }
//
//                    Button(action: { showShareSheet.toggle() }) {
//                        Image(systemName: "plus")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                            .padding(8)
//                            .background(primaryGradient)
//                            .clipShape(Circle())
//                    }
//                }
//            }
//            .padding(.horizontal)
//        }
//        .padding(.top, 60)
//        .padding(.bottom, 8)
//    }
//
//    private var quickStatsSection: some View {
//        HStack(spacing: 15) {
//            StatCard(
//                title: "Összes szám",
//                value: "\(sharedSongs.count)",
//                icon: "music.note.list",
//                gradient: primaryGradient
//            )
//
//            StatCard(
//                title: "Legtöbb like",
//                value: "\(sharedSongs.map { $0.likes }.max() ?? 0)",
//                icon: "heart.fill",
//                gradient: secondaryGradient
//            )
//
//            StatCard(
//                title: "Aktív",
//                value: "\(Set(sharedSongs.map { $0.sharedBy }).count)",
//                icon: "person.2.fill",
//                gradient: cardGradient
//            )
//        }
//    }
//
//    private var moodFilterSection: some View {
//        VStack(alignment: .leading) {
//            Text("HANGULAT")
//                .font(.lexend3())
//                .foregroundColor(.gray)
//                .padding(.horizontal, 4)
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 12) {
//                    ForEach(MusicMood.allCases, id: \.self) { mood in
//                        MoodChip(
//                            mood: mood,
//                            isSelected: selectedMood == mood,
//                            gradient: primaryGradient,
//                            onTap: {
//                                withAnimation(.spring()) {
//                                    selectedMood = selectedMood == mood ? nil : mood
//                                }
//                            }
//                        )
//                    }
//                }
//                .padding(.horizontal, 4)
//            }
//        }
//    }
//
//    private var featuredSongsSection: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text("KIEMELT SZÁMOK")
//                    .font(.lexend(fontWeight: .bold))
//                    .foregroundColor(.white)
//
//                Spacer()
//
//                Image(systemName: "crown.fill")
//                    .foregroundColor(.yellow)
//            }
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack(spacing: 16) {
//                    ForEach(Array(filteredSongs.prefix(5))) { song in
//                        FeaturedSongCard(
//                            song: song,
//                            gradient: primaryGradient
//                        ) {
//                            playSong(song)
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    private var recentSharesSection: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text("LEGÚJABB MEGOSZTÁSOK")
//                    .font(.lexend(fontWeight: .bold))
//                    .foregroundColor(.white)
//
//                Spacer()
//
//                Text("\(sharedSongs.count)")
//                    .font(.lexend2())
//                    .foregroundColor(.gray)
//            }
//
//            LazyVStack(spacing: 12) {
//                ForEach(filteredSongs) { song in
//                    SongRow(
//                        song: song,
//                        gradient: primaryGradient
//                    ) {
//                        playSong(song)
//                    }
//                    .padding(.vertical, 4)
//                }
//            }
//        }
//    }
//
//    // MARK: - Music Functions
//
//    private func loadMusicData() {
//        sharedSongs = mockSongs
//    }
//
//    private func playSong(_ song: SharedSong) {
//        currentPlayingSong = song
//        isPlaying = true
//        withAnimation(.spring()) {
//            showNowPlaying = true
//        }
//        print("Playing: \(song.title) by \(song.artist)")
//    }
//}
//
//// MARK: - Supporting Views
//
//struct StatCard: View {
//    let title: String
//    let value: String
//    let icon: String
//    let gradient: LinearGradient
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.title3)
//                .foregroundStyle(gradient)
//
//            Text(value)
//                .font(.lexend(fontWeight: .bold))
//                .foregroundColor(.white)
//
//            Text(title)
//                .font(.lexend3())
//                .foregroundColor(.gray)
//        }
//        .frame(maxWidth: .infinity)
//        .padding()
//        .background(Color.white.opacity(0.05))
//        .cornerRadius(12)
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.white.opacity(0.1), lineWidth: 1)
//        )
//    }
//}
//
//struct MoodChip: View {
//    let mood: MusicMood
//    let isSelected: Bool
//    let gradient: LinearGradient
//    let onTap: () -> Void
//
//    var body: some View {
//        Button(action: onTap) {
//            Text(mood.rawValue)
//                .font(.lexend3())
//                .padding(.horizontal, 16)
//                .padding(.vertical, 10)
//                .background(
//                    Group {
//                        if isSelected {
//                            gradient
//                        } else {
//                            Color.white.opacity(0.05)
//                        }
//                    }
//                )
//                .foregroundColor(isSelected ? .white : .gray)
//                .cornerRadius(20)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20)
//                        .stroke(
//                            isSelected ? Color.clear : Color.white.opacity(0.1),
//                            lineWidth: 1
//                        )
//                )
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//struct FeaturedSongCard: View {
//    let song: SharedSong
//    let gradient: LinearGradient
//    let onPlay: () -> Void
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            // Album Art Placeholder
//            ZStack(alignment: .bottomTrailing) {
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(
//                        LinearGradient(
//                            colors: [Color(red: 0.2, green: 0.2, blue: 0.3), //Color(red: 0.4, green: 0.2, blue: 0.1)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 160, height: 160)
//
//                Image(systemName: "music.note")
//                    .font(.largeTitle)
//                    .foregroundColor(.white.opacity(0.3))
//                    .padding(8)
//
//                // BPM Indicator
//                if let bpm = song.bpm {
//                    VStack {
//                        Text("BPM")
//                            .font(.caption2)
//                            .foregroundColor(.white.opacity(0.7))
//                        Text("\(bpm)")
//                            .font(.lexend3(fontWeight: .bold))
//                            .foregroundColor(.white)
//                    }
//                    .padding(6)
//                    .background(Color.black.opacity(0.6))
//                    .cornerRadius(6)
//                    .padding(8)
//                }
//
//                // Play Button Overlay
//                Button(action: onPlay) {
//                    Image(systemName: "play.circle.fill")
//                        .font(.title)
//                        .foregroundColor(.white)
//                        .padding(8)
//                        .background(gradient)
//                        .clipShape(Circle())
//                }
//                .padding(8)
//            }
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text(song.title)
//                    .font(.lexend2(fontWeight: .bold))
//                    .foregroundColor(.white)
//                    .lineLimit(1)
//
//                Text(song.artist)
//                    .font(.lexend3())
//                    .foregroundColor(.gray)
//                    .lineLimit(1)
//
//                HStack {
//                    Image(systemName: "clock")
//                        .font(.caption2)
//                        .foregroundColor(.gray)
//
//                    Text(song.duration)
//                        .font(.lexend3())
//                        .foregroundColor(.gray)
//
//                    Spacer()
//
//                    HStack(spacing: 4) {
//                        Image(systemName: "heart.fill")
//                            .font(.caption2)
//                            .foregroundColor(.red)
//
//                        Text("\(song.likes)")
//                            .font(.caption2)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//            .frame(width: 160)
//        }
//    }
//}
//
//struct SongRow: View {
//    let song: SharedSong
//    let gradient: LinearGradient
//    let onPlay: () -> Void
//    @State private var isLiked = false
//
//    var body: some View {
//        HStack(spacing: 16) {
//            // Album Art
//            ZStack {
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(
//                        LinearGradient(
//                            colors: [Color(red: 0.2, green: 0.2, blue: 0.3), //Color(red: 0.4, green: 0.2, blue: 0.1)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 50, height: 50)
//
//                Image(systemName: "music.note")
//                    .foregroundColor(.white.opacity(0.3))
//            }
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text(song.title)
//                    .font(.lexend2(fontWeight: .medium))
//                    .foregroundColor(.white)
//                    .lineLimit(1)
//
//                HStack {
//                    Text(song.artist)
//                        .font(.lexend3())
//                        .foregroundColor(.gray)
//                        .lineLimit(1)
//
//                    Text("•")
//                        .foregroundColor(.gray)
//
//                    Text(song.genre)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//
//                HStack {
//                    Text("\(song.duration)")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//
//                    if let bpm = song.bpm {
//                        Text("•")
//                            .foregroundColor(.gray)
//
//                        Text("\(bpm) BPM")
//                            .font(.caption)
//                            .foregroundColor(.orange)
//                    }
//
//                    Text("•")
//                        .foregroundColor(.gray)
//
//                    Text(song.sharedBy)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//            }
//
//            Spacer()
//
//            HStack(spacing: 12) {
//                Button(action: {
//                    withAnimation(.spring()) {
//                        isLiked.toggle()
//                    }
//                }) {
//                    Image(systemName: isLiked ? "heart.fill" : "heart")
//                        .foregroundColor(isLiked ? .red : .gray)
//                }
//
//                Button(action: onPlay) {
//                    Image(systemName: "play.circle.fill")
//                        .font(.title2)
//                        .foregroundStyle(gradient)
//                }
//            }
//        }
//        .padding()
//        .background(Color.white.opacity(0.03))
//        .cornerRadius(12)
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.white.opacity(0.05), lineWidth: 1)
//        )
//        .onAppear {
//            isLiked = song.userLiked
//        }
//    }
//}
//
//// MARK: - Now Playing View
//struct NowPlayingView: View {
//    let song: SharedSong
//    @Binding var isPlaying: Bool
//    @Binding var isPresented: Bool
//
//    private let gradient = LinearGradient(
//        colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: //0.1, blue: 0.05)],
//        startPoint: .top,
//        endPoint: .bottom
//    )
//
//    var body: some View {
//        ZStack {
//            // Background
//            gradient.ignoresSafeArea()
//
//            VStack(spacing: 30) {
//                // Header
//                HStack {
//                    Button(action: {
//                        withAnimation(.spring()) {
//                            isPresented = false
//                        }
//                    }) {
//                        Image(systemName: "chevron.down")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
//
//                    Spacer()
//
//                    Text("NOW PLAYING")
//                        .font(.lexend(fontWeight: .bold))
//                        .foregroundColor(.white)
//
//                    Spacer()
//
//                    // Placeholder for symmetry
//                    Image(systemName: "chevron.down")
//                        .font(.title2)
//                        .foregroundColor(.clear)
//                }
//                .padding(.horizontal)
//                .padding(.top, 60)
//
//                // Album Art
//                ZStack {
//                    Circle()
//                        .fill(
//                            LinearGradient(
//                                colors: [Color(red: 0.2, green: 0.2, blue: 0.4), //Color(red: 0.6, green: 0.2, blue: 0.1)],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .frame(width: 250, height: 250)
//
//                    Image(systemName: "music.note")
//                        .font(.system(size: 60))
//                        .foregroundColor(.white.opacity(0.3))
//                }
//
//                // Song Info
//                VStack(spacing: 8) {
//                    Text(song.title)
//                        .font(.lexend(fontWeight: .bold))
//                        .foregroundColor(.white)
//                        .multilineTextAlignment(.center)
//
//                    Text(song.artist)
//                        .font(.lexend2())
//                        .foregroundColor(.gray)
//
//                    if let bpm = song.bpm {
//                        Text("\(bpm) BPM • \(song.genre)")
//                            .font(.lexend3())
//                            .foregroundColor(.orange)
//                    } else {
//                        Text(song.genre)
//                            .font(.lexend3())
//                            .foregroundColor(.gray)
//                    }
//                }
//
//                // Progress Bar
//                VStack(spacing: 8) {
//                    // Progress bar would go here
//                    HStack {
//                        Text("0:00")
//                            .font(.lexend3())
//                            .foregroundColor(.gray)
//
//                        Spacer()
//
//                        Text(song.duration)
//                            .font(.lexend3())
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding(.horizontal, 40)
//
//                // Controls
//                HStack(spacing: 40) {
//                    Button(action: {}) {
//                        Image(systemName: "backward.fill")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
//
//                    Button(action: {
//                        isPlaying.toggle()
//                    }) {
//                        Image(systemName: isPlaying ? "pause.circle.fill" : //"play.circle.fill")
//                            .font(.system(size: 60))
//                            .foregroundStyle(
//                                LinearGradient(
//                                    colors: [Color(red: 0.1, green: 0.3, blue: //0.6), Color(red: 0.8, green: 0.2, blue: //0.1)],
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                    }
//
//                    Button(action: {}) {
//                        Image(systemName: "forward.fill")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
//                }
//
//                Spacer()
//            }
//        }
//    }
//}
//
//#Preview {
//    MusicShareView()
//}
//
//#Preview("Featured Song Card") {
//    FeaturedSongCard(
//        song: SharedSong(
//            title: "Blinding Lights",
//            artist: "The Weeknd",
//            album: "After Hours",
//            albumArt: "",
//            previewURL: nil,
//            spotifyURL: nil,
//            appleMusicURL: nil,
//            sharedBy: "Márk",
//            sharedAt: Date(),
//            likes: 24,
//            userLiked: false,
//            genre: "Synthwave",
//            mood: .energetic,
//            duration: "3:20",
//            bpm: 108
//        ),
//        gradient: LinearGradient(
//            colors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.8, green: //0.2, blue: 0.1)],
//            startPoint: .topLeading,
//            endPoint: .bottomTrailing
//        ),
//        onPlay: {}
//    )
//    .padding()
//    .background(Color(.systemGroupedBackground))
//}
//
//
