//
//  MemeView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2024. 11. 20..
//

import SwiftUI
import PhotosUI

// Your Meme structure remains the same
struct Meme: Identifiable {
    let id = UUID()
    var image: UIImage
    var caption: String
}

struct MemeView: View {
    // Your @State properties remain the same
    @State private var memes: [Meme] = []
    @State private var selectedImage: UIImage?
    @State private var caption: String = ""
    @State private var showImagePicker: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var memeToDelete: Meme?

    var body: some View {
        NavigationView {
            VStack {
                // Title remains the same
                Text("Mémek")
                    .font(.largeTitle)
                    .padding()

                // Caption TextField remains the same
                TextField("Írj egy feliratot...", text: $caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Image upload button
                Button("Kép feltöltése") {
                    showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                // Share button
                Button(action: addMeme) {
                    Text("Megosztás")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // Meme list
                List {
                    ForEach(memes) { meme in
                        MemeItemView(meme: meme, deleteMeme: {
                            memeToDelete = meme
                            showDeleteConfirmation = true
                        })
                    }
                }
            }
            .navigationTitle("MemeView")
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                deleteConfirmationAlert
            }
        }
    }

    // MARK: - Alert

    private var deleteConfirmationAlert: Alert {
        Alert(title: Text("Mém törlése"),
              message: Text("Biztosan törölni szeretnéd a mém feliratát: \(memeToDelete?.caption ?? "")?"),
              primaryButton: .destructive(Text("Törlés")) {
                if let meme = memeToDelete {
                    deleteMeme(meme)
                }
              },
              secondaryButton: .cancel())
    }

    // MARK: - Helper Methods

    private func addMeme() {
        if let image = selectedImage, !caption.isEmpty {
            let meme = Meme(image: image, caption: caption)
            memes.append(meme)
            selectedImage = nil
            caption = ""
        }
    }

    private func deleteMeme(_ meme: Meme) {
        if let index = memes.firstIndex(where: { $0.id == meme.id }) {
            memes.remove(at: index)
        }
    }
}

struct MemeItemView: View {
    let meme: Meme
    let deleteMeme: () -> Void

    var body: some View {
        VStack {
            Image(uiImage: meme.image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
            Text(meme.caption)
                .font(.subheadline)

            Button(action: deleteMeme) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    MemeView()
}

// End of file. No additional code.
