//
//  ContentView 2.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/4/25.
//
import SwiftUI

struct Probadesign: View {

    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(1 ... 50, id: \.self) { index in
                    Text("Index: \(index)")
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Large title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    BarContent()
                }
            }
        }
    }
}

struct Probadesign_Preview: PreviewProvider {
    static var previews: some View {
        Probadesign()
    }
}
struct BarContent: View {
    var body: some View {
        Button {
            print("Profile tapped")
        } label: {
            ProfilePicture()
        }
    }
}

struct ProfilePicture: View {
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.red, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        
            .frame(width: 40, height: 40)
            .padding(.horizontal)
    }
}
