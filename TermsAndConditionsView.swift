import SwiftUI
import WebKit

struct TermsAndConditionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentLanguage: Language = .english
    @State private var hasScrolledToBottom = false
    @State private var showAcceptanceAlert = false
    @State private var scrollStates: [Language: Bool] = [:]
    @State private var showMain = false
    
    enum Language: String, CaseIterable {
        case english = "en"
        case hungarian = "hu"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .hungarian: return "Magyar"
            }
        }
        
        var closeButtonText: String {
            switch self {
            case .english: return "Close"
            case .hungarian: return "Bezárás"
            }
        }
        
        var acceptButtonText: String {
            switch self {
            case .english: return "Accept Terms"
            case .hungarian: return "Feltételek elfogadása"
            }
        }
        
        var scrollToBottomText: String {
            switch self {
            case .english: return "Please read to the end to accept"
            case .hungarian: return "Olvassa el a végéig az elfogadáshoz"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Language Picker
                HStack {
                    Text(currentLanguage == .english ? "Language:" : "Nyelv:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Language", selection: $currentLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: currentLanguage) { oldLanguage, newLanguage in
                        hasScrolledToBottom = scrollStates[newLanguage] ?? false
                    }
                }
                .padding()
                
                // WebView
                TermsWebView(
                    language: currentLanguage,
                    hasScrolledToBottom: $hasScrolledToBottom,
                    onScrollStateChange: { reachedBottom in
                        scrollStates[currentLanguage] = reachedBottom
                    }
                )
                
                // Accept Button
                VStack(spacing: 8) {
                    if !hasScrolledToBottom {
                        Text(currentLanguage.scrollToBottomText)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        showAcceptanceAlert = true
                    }) {
                        HStack {
                            Text(currentLanguage.acceptButtonText)
                                .font(.custom("Jellee", size: 18))
                            Image(systemName: "checkmark.circle.fill")

                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            hasScrolledToBottom ? AnyView(LinearGradient(gradient: Gradient(colors: [.orange, .blue]), startPoint: .top, endPoint: .bottom)) : AnyView(LinearGradient(gradient: Gradient(colors: [.gray]), startPoint: .top, endPoint: .bottom))
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(!hasScrolledToBottom)
                    .animation(.easeInOut(duration: 0.3), value: hasScrolledToBottom)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(currentLanguage.closeButtonText) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Accept Terms", isPresented: $showAcceptanceAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Accept") {
                    acceptTermsAndConditions()
                }
            } message: {
                Text("Do you accept our Terms and Conditions?")
            }
        }
        .fullScreenCover(isPresented: $showMain) {
            ContentView()
        }
    }
    
    private func acceptTermsAndConditions() {
        UserDefaults.standard.set(true, forKey: "hasAcceptedTerms")
        UserDefaults.standard.set(Date(), forKey: "termsAcceptanceDate")
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "acceptedTermsLanguage")
        
        print("Terms accepted in \(currentLanguage.displayName)")
        showMain = true
    }
}

// MARK: - WebView with Scroll Detection
struct TermsWebView: UIViewRepresentable {
    let language: TermsAndConditionsView.Language
    @Binding var hasScrolledToBottom: Bool
    var onScrollStateChange: ((Bool) -> Void)? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        let contentController = webView.configuration.userContentController
        contentController.add(context.coordinator, name: "scrollHandler")
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Mindig töltsd be a tartalmat, de csak ha tényleg változott a nyelv
        let filename = "termsandconditions-\(language.rawValue)"
        if let currentURL = uiView.url?.absoluteString, currentURL.contains(filename) {
            // Ha már betöltötte ezt a nyelvet, ne töltsd újra
            return
        }
        
        loadContent(in: uiView, for: language)
    }
    
    private func loadContent(in webView: WKWebView, for language: TermsAndConditionsView.Language) {
        let filename = "termsandconditions-\(language.rawValue)"
        
        if let filePath = Bundle.main.path(forResource: filename, ofType: "html") {
            let fileURL = URL(fileURLWithPath: filePath)
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
            print("Loading HTML file: \(filename).html")
        } else {
            print("HTML file not found: \(filename).html, using fallback content")
            let fallbackHTML = createFallbackHTML(for: language)
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }
    
    private func createFallbackHTML(for language: TermsAndConditionsView.Language) -> String {
        let title = language == .english ? "Terms and Conditions" : "Általános Szerződési Feltételek"
        let content = language == .english ? createEnglishContent() : createHungarianContent()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6; padding: 20px; margin: 0; 
                    background-color: #f5f5f5;
                }
                .container { 
                    background: white; 
                    border-radius: 12px; 
                    padding: 24px; 
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    max-width: 800px;
                    margin: 0 auto;
                }
                h1 { color: #007AFF; text-align: center; margin-bottom: 24px; }
                h2 { color: #007AFF; margin: 20px 0 12px 0; }
                p { margin-bottom: 16px; text-align: justify; }
                .section { margin-bottom: 24px; border-bottom: 1px solid #eee; padding-bottom: 16px; }
                .highlight { background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 6px; padding: 12px; margin: 16px 0; }
                .bottom-marker { 
                    height: 2px; 
                    background: transparent; 
                    margin: 20px 0; 
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>\(title)</h1>
                \(content)
                <div class="highlight">
                    <p><strong>\(language == .english ? "Important" : "Fontos"):</strong> \(language == .english ? "By using our service, you declare that you have read and accept these Terms and Conditions." : "A szolgáltatás igénybevételével a felhasználó kijelenti, hogy megismerte és elfogadja jelen Általános Szerződési Feltételeket.")</p>
                </div>
                <!-- Láthatatlan marker az alján -->
                <div class="bottom-marker" id="bottomMarker"></div>
            </div>

            <script>
                let hasNotified = false;
                
                function checkScroll() {
                    if (hasNotified) return;
                    
                    const bottomMarker = document.getElementById('bottomMarker');
                    if (bottomMarker) {
                        const rect = bottomMarker.getBoundingClientRect();
                        // Ha a marker látható a képernyőn
                        if (rect.top < window.innerHeight && rect.bottom >= 0) {
                            hasNotified = true;
                            window.webkit.messageHandlers.scrollHandler.postMessage("reachedBottom");
                            console.log("Bottom reached - notification sent");
                        }
                    }
                }
                
                // Csak egyszer indítsd el az intervalt
                let scrollInterval = setInterval(() => {
                    checkScroll();
                    if (hasNotified) {
                        clearInterval(scrollInterval);
                    }
                }, 100);
                
                window.addEventListener('scroll', checkScroll);
                window.addEventListener('load', checkScroll);
            </script>
        </body>
        </html>
        """
    }
    
    private func createEnglishContent() -> String {
        var content = ""
        for i in 1...15 {
            content += """
            <div class="section">
                <h2>Section \(i)</h2>
                <p>This is section \(i) of our terms and conditions. Please read all sections carefully before accepting.</p>
                <p>By accepting these terms, you agree to comply with all the provisions outlined in this document.</p>
            </div>
            """
        }
        return content
    }
    
    private func createHungarianContent() -> String {
        var content = ""
        for i in 1...15 {
            content += """
            <div class="section">
                <h2>\(i). szakasz</h2>
                <p>Ez a szerződési feltételek \(i). szakasza. Kérjük, olvassa el minden szakaszt figyelmesen az elfogadás előtt.</p>
                <p>A feltételek elfogadásával vállalja, hogy betartja a dokumentumban foglalt összes rendelkezést.</p>
            </div>
            """
        }
        return content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: TermsWebView
        private var hasReceivedScrollMessage = false
        
        init(_ parent: TermsWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "scrollHandler" && !hasReceivedScrollMessage {
                hasReceivedScrollMessage = true
                DispatchQueue.main.async {
                    if !self.parent.hasScrolledToBottom {
                        self.parent.hasScrolledToBottom = true
                        self.parent.onScrollStateChange?(true)
                        print("Bottom reached - accept button enabled")
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading \(parent.language.displayName)")
            // Reset scroll state when new content loads
            DispatchQueue.main.async {
                self.parent.hasScrolledToBottom = false
                self.hasReceivedScrollMessage = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView loading error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    TermsAndConditionsView()
}
