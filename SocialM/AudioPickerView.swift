//
//  AudioPickerView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/17/25.
//


// AudioPickerView.swift - BŐVÍTETT VERZIÓ
import SwiftUI
import MobileCoreServices
import AVFoundation

struct AudioData2: Codable {
    let url: String
    let title: String?
    let artist: String?
    let duration: Double?
}

struct AudioPickerView: UIViewControllerRepresentable {
    @Binding var audioURL: URL?
    @Binding var audioTitle: String?
    @Binding var audioArtist: String?
    @Binding var audioDuration: Double?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            documentTypes: [kUTTypeAudio as String],
            in: .import
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioPickerView
        
        init(_ parent: AudioPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            let fileManager = FileManager.default
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: url, to: destinationURL)
                
                parent.audioURL = destinationURL
                extractMetadata(from: destinationURL)
                
            } catch {
                print("Hiba a fájl másolásakor: \(error)")
            }
        }
        
        private func extractMetadata(from url: URL) {
            let asset = AVAsset(url: url)
            let metadata = asset.commonMetadata
            
            var title = url.deletingPathExtension().lastPathComponent
            var artist = "Ismeretlen előadó"
            var duration: Double = 0
            
            // Duration kinyerése
            duration = CMTimeGetSeconds(asset.duration)
            parent.audioDuration = duration
            
            for item in metadata {
                if let commonKey = item.commonKey {
                    switch commonKey {
                    case .commonKeyTitle:
                        title = item.stringValue ?? title
                    case .commonKeyArtist:
                        artist = item.stringValue ?? artist
                    case .commonKeyAlbumName:
                        // Album neve is érdekes lehet
                        break
                    default:
                        break
                    }
                }
            }
            
            parent.audioTitle = title
            parent.audioArtist = artist
        }
    }
}

struct AudioPlayerView: View {
    let audioURL: URL
    let title: String?
    let artist: String?
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Zene információk
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title ?? "Ismeretlen zene")
                        .font(.lexend(fontWeight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(artist ?? "Ismeretlen előadó")
                        .font(.lexend2(fontWeight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Vezérlő gombok
            HStack(spacing: 20) {
                // Vissza gomb
                Button(action: skipBackward) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Play/Pause gomb
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Előre gomb
                Button(action: skipForward) {
                    Image(systemName: "goforward.30")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            
            // Timer a progress frissítéséhez
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                updateProgress()
            }
            
        } catch {
            print("Hiba az audio player betöltésekor: \(error)")
        }
    }
    
    private func togglePlay() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func skipBackward() {
        guard let player = player else { return }
        player.currentTime = max(0, player.currentTime - 15)
        updateProgress()
    }
    
    private func skipForward() {
        guard let player = player else { return }
        player.currentTime = min(player.duration, player.currentTime + 30)
        updateProgress()
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
        
        if !player.isPlaying {
            isPlaying = false
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
    }
}

