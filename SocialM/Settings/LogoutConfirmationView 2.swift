import SwiftUI
import DesignSystem


struct LogoutView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedReason: String?
    @State private var customReason: String = ""
    @State private var showAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private let logoutReasons = [
        "Personal reasons",
        "Not using the app",
        "Switching to another app",
        "Don't like the app",
        "Other reason"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.purple, .purple.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )                            .symbolRenderingMode(.hierarchical)
                        
                        Text("We're sorry to see you go")
                            .font(.custom("Jellee", size:20))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Please help us improve by sharing your reason for leaving")
                            .font(.lexend2())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Reasons list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why are you logging out?")
                            .font(.custom("Jellee", size:20))
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 1) {
                            ForEach(logoutReasons, id: \.self) { reason in
                                ReasonRow(
                                    reason: reason,
                                    isSelected: selectedReason == reason,
                                    hasCustomField: reason == "Other reason" && selectedReason == "Other reason",
                                    customReason: $customReason
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        if reason == "Other reason" {
                                            selectedReason = selectedReason == "Other reason" ? nil : "Other reason"
                                        } else {
                                            selectedReason = reason
                                            customReason = ""
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Logout button
                    VStack(spacing: 12) {
                        Button(action: {
                            showAlert = true
                        }) {
                            HStack {
                                Text("Log Out")
                                    .fontWeight(.semibold)
                                    .font(.lexend())
                                Image(systemName: "arrow.right.circle")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackground)
                            .cornerRadius(20)
                            .shadow(color: buttonShadowColor, radius: 4, y: 2)
                        }
                        .disabled(!hasSelectedReason)
                        .opacity(hasSelectedReason ? 1 : 0.6)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.lexend2())

                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)

            .alert("Confirm Log Out", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to log out? You'll need to sign in again to access your account.")

            }
            
        }
    }
    
    private var hasSelectedReason: Bool {
        selectedReason != nil && (selectedReason != "Other reason" || !customReason.isEmpty)
    }
    
    private var buttonBackground: some View {
        Group {
            if hasSelectedReason {
                LinearGradient(
                    colors: [.purple, .purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color.gray
            }
        }
    }
    
    private var buttonShadowColor: Color {
        hasSelectedReason ? .purple.opacity(0.3) : .gray.opacity(0.3)
    }
    
    private func performLogout() {
        // Log logout reason (you could send this to analytics)
        let finalReason = selectedReason == "Other reason" ? "Custom: \(customReason)" : selectedReason ?? "No reason"
        print("Logout reason: \(finalReason)")
        
        // Clear user data
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "username")
        
        // Update auth state
        isLoggedIn = false
    }
}

struct ReasonRow: View {
    let reason: String
    let isSelected: Bool
    let hasCustomField: Bool
    @Binding var customReason: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(reason)
                        .foregroundColor(.primary)
                        .font(.lexend2())

                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.system(size: 20))
                    } else {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if hasCustomField {
                Divider()
                    .padding(.leading)
                
                TextField("Please describe your reason...", text: $customReason)
                    .font(.lexend2())
                    .padding()
                    .background(Color(.systemGray6))
            }
        }
        .background(Color(.systemBackground))
    }
}

struct PlainTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 8)
    }
}

struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutView(isLoggedIn: .constant(true))
    }
}
