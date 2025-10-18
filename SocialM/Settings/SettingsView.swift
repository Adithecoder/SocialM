import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool // Bejelentkezési állapot
    @State private var showDeleteAccountConfirmation = false // Fiók törlése megerősítés
    @State private var selectedReason: String = "" // Kijelentkezési ok
    let reasons = ["Személyes okok", "Nem használom", "Másik alkalmazásra váltok", "Egyéb"] // Kijelentkezési okok

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Fiók")
                    .font(.custom("Jellee", size: 18))) {
                    NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn)) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text(NSLocalizedString("Fiók kezelése", comment: ""))
                                
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.gray, .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }

                    Button(action: {
                        // Jelszó megváltoztatás logika
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Jelszó megváltoztatása")
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.gray, .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }

                Section(header: Text("Alapbeállítások")
                    .font(.custom("Jellee", size: 18))) {
                    Button(action: {
                        // Értesítések beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Értesítések")
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.gray, .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }

                    Button(action: {
                        // Nyelv beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            
                            Text("Nyelv")
                            
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.gray, .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }

                    Button(action: {
                        // Témák beállításai logika
                    }) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                            Text("Téma")
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.gray, .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                
                // Fiók törlése szekció
                Section(header: Text("Dokumentumok és adatkezelés")
                    .font(.custom("Jellee", size: 18))) {
                        NavigationLink(destination: TermsAndConditionsView()) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .font(.system(size: 20))
                                Text("Terms and Conditions")
                                    
                            }
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.gray, .gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        
                        NavigationLink(destination: GDPRView()) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .font(.system(size: 20))
                                Text("GDPR")
                                    
                            }
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.gray, .gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                }

                // Kijelentkezés szekció
                Section(header: Text("Fiókod állapota")
                    .font(.custom("Jellee", size: 18))) {
                    NavigationLink(destination: LogoutView(isLoggedIn: $isLoggedIn)) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 20))
                            Text("Kijelentkezés")
                                
                        }
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.red, .red.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                        Button(action: {
                            showDeleteAccountConfirmation = true // Fiók törlése megerősítés megjelenítése
                        }) {
                            HStack {
                                Image(systemName: "trash.circle")
                                    .font(.system(size: 20))
                                Text("Fiók törlése")
                                    
                            }
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.red, .red.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                }

            }
            .font(.lexend())
            .navigationTitle("Beállítások")
            .alert(isPresented: $showDeleteAccountConfirmation) {
                Alert(title: Text("Fiók törlése"),
                      message: Text("Biztosan törölni szeretnéd a fiókodat? Ez a művelet visszafordíthatatlan."),
                      primaryButton: .destructive(Text("Fiók törlése")) {
                        deleteAccount() // Fiók törlése logika
                      },
                      secondaryButton: .cancel())
            }
        }
    }

    private func deleteAccount() {
        // Itt implementáld a fiók törlésének logikáját
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // Bejelentkezési állapot törlése
        UserDefaults.standard.removeObject(forKey: "username") // Felhasználónév törlése (opcionális)
        // További fiók törlési logika, pl. adatbázisból való törlés
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isLoggedIn: .constant(true)) // Példa a bejelentkezési állapotra
    }
}
