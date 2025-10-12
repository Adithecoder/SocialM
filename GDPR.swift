import SwiftUI
import WebKit
import DesignSystem

struct GDPRView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Háttér
            Color(Color.DesignSystem.fokekszin.opacity(0.1))
                .edgesIgnoringSafeArea(.all)
                .cornerRadius(20)
                .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                )

            VStack(spacing: 0) {
                // Fejléc
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                            .font(.lexend())
                            .padding()
                    }


                    Text("Adatvédelmi irányelvek")
                        .font(.custom("Jellee-Roman", size: 22))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 20)

                }

                Divider()

                // WebView biztonságos betöltése
                if let url = Bundle.main.url(forResource: "gdprfull", withExtension: "html") {
                    WebView(url: url, isLoading: $isLoading)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("Az adatvédelmi irányelveket nem sikerült betölteni.")
                            .font(.custom("Jellee", size:18))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                }

                if isLoading {
                    ProgressView("Betöltés folyamatban…")
                        .font(.lexend())
                        .padding()
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    var url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
    }
}


// Alternatív megoldás: HTML string betöltése
struct GDPRInlineView: View {
    @Environment(\.presentationMode) var presentationMode
    let htmlContent: String
    
    init() {
        // Itt lehetne betölteni fájlból vagy stringként
        self.htmlContent = GDPRHTMLContent.htmlString
    }
    
    var body: some View {
            WebViewFromString(htmlString: htmlContent)
                .navigationBarTitle("Adatvédelmi irányelvek", displayMode: .inline)
                .navigationBarItems(
                    trailing: Button("Kész") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        
    }
}

struct WebViewFromString: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}

// HTML tartalom stringként
struct GDPRHTMLContent {
    static let htmlString = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Privacy Policy - SkillStream</title>
        <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&family=Lexend:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <style>
            :root {
                --primary: #4361ee;
                --primary-dark: #3a56d4;
                --secondary: #7209b7;
                --light: #f8f9fa;
                --dark: #212529;
                --gray: #6c757d;
                --border: #dee2e6;
                --success: #4bb543;
            }
            
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                background-color: #f5f7fb;
                color: var(--dark);
                line-height: 1.6;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                padding: 0 20px;
            }
            
            header {
                background: linear-gradient(135deg, var(--primary), var(--secondary));
                color: white;
                padding: 2rem 0;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            }
            
            .header-content {
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .logo {
                display: flex;
                align-items: center;
                gap: 10px;
            }
            
            .logo-icon {
                font-size: 2rem;
            }
            
            .logo-text {
                font-size: 1.8rem;
                font-weight: 800;
                font-family: 'Nunito', sans-serif;
            }
            
            .last-updated {
                background-color: rgba(255, 255, 255, 0.2);
                padding: 8px 15px;
                border-radius: 20px;
                font-size: 0.9rem;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .policy-container {
                display: flex;
                gap: 30px;
                margin: 30px 0;
            }
            
            .sidebar {
                flex: 0 0 280px;
                background: white;
                border-radius: 10px;
                padding: 25px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
                height: fit-content;
                position: sticky;
                top: 20px;
            }
            
            .sidebar h3 {
                margin-bottom: 20px;
                padding-bottom: 10px;
                border-bottom: 2px solid var(--primary);
                color: var(--primary);
                font-family: 'Nunito', sans-serif;
                font-size: 1.5rem;
                font-weight: 700;
            }
            
            .nav-links {
                list-style: none;
            }
            
            .nav-links li {
                margin-bottom: 12px;
            }
            
            .nav-links a {
                text-decoration: none;
                color: var(--dark);
                display: block;
                padding: 8px 12px;
                border-radius: 5px;
                transition: all 0.3s ease;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .nav-links a:hover, .nav-links a.active {
                background-color: #e9ecef;
                color: var(--primary);
                font-weight: 600;
            }
            
            .content {
                flex: 1;
                background: white;
                border-radius: 10px;
                padding: 35px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
            }
            
            h1 {
                color: var(--primary);
                margin-bottom: 10px;
                font-size: 2.5rem;
                font-family: 'Nunito', sans-serif;
                font-weight: 800;
            }
            
            h2 {
                color: var(--primary-dark);
                margin: 40px 0 20px;
                padding-bottom: 8px;
                border-bottom: 1px solid var(--border);
                font-family: 'Nunito', sans-serif;
                font-size: 1.8rem;
                font-weight: 700;
            }
            
            h3 {
                color: var(--secondary);
                margin: 25px 0 15px;
                font-family: 'Nunito', sans-serif;
                font-size: 1.4rem;
                font-weight: 600;
            }
            
            h4 {
                color: var(--dark);
                margin: 20px 0 10px;
                font-family: 'Lexend', sans-serif;
                font-size: 1.2rem;
                font-weight: 500;
            }
            
            p {
                margin-bottom: 15px;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            ul, ol {
                margin-left: 20px;
                margin-bottom: 20px;
            }
            
            li {
                margin-bottom: 8px;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .data-table {
                width: 100%;
                border-collapse: collapse;
                margin: 25px 0;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
                font-family: 'Lexend', sans-serif;
                border-radius: 8px;
                overflow: hidden;
            }
            
            .data-table th {
                background-color: var(--primary);
                color: white;
                text-align: left;
                padding: 12px 15px;
                font-family: 'Nunito', sans-serif;
                font-weight: 600;
            }
            
            .data-table td {
                padding: 12px 15px;
                border-bottom: 1px solid var(--border);
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .data-table tr:nth-child(even) {
                background-color: #f8f9fa;
            }
            
            .data-table tr:hover {
                background-color: #e9ecef;
            }
            
            .highlight-box {
                background-color: #e7f1ff;
                border-left: 4px solid var(--primary);
                padding: 20px;
                margin: 25px 0;
                border-radius: 0 5px 5px 0;
                font-family: 'Lexend', sans-serif;
            }
            
            .contact-card {
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                color: white;
                padding: 25px;
                border-radius: 10px;
                margin: 25px 0;
                box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1);
                font-family: 'Lexend', sans-serif;
            }
            
            .contact-card h3 {
                color: white;
                margin-top: 0;
                font-family: 'Nunito', sans-serif;
            }
            
            footer {
                background-color: var(--dark);
                color: white;
                text-align: center;
                padding: 25px 0;
                margin-top: 50px;
                font-family: 'Lexend', sans-serif;
            }
            
            .footer-content {
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .footer-links {
                display: flex;
                gap: 20px;
            }
            
            .footer-links a {
                color: white;
                text-decoration: none;
                font-family: 'Lexend', sans-serif;
                font-weight: 400;
            }
            
            .footer-links a:hover {
                text-decoration: underline;
            }
            
            .consent-bar {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                background-color: var(--dark);
                color: white;
                padding: 15px 0;
                box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
                z-index: 1000;
                font-family: 'Lexend', sans-serif;
            }
            
            .consent-content {
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .consent-buttons {
                display: flex;
                gap: 10px;
            }
            
            .btn {
                padding: 8px 20px;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-weight: 600;
                transition: all 0.3s ease;
                font-family: 'Nunito', sans-serif;
            }
            
            .btn-primary {
                background-color: var(--primary);
                color: white;
            }
            
            .btn-primary:hover {
                background-color: var(--primary-dark);
            }
            
            .btn-outline {
                background-color: transparent;
                color: white;
                border: 1px solid white;
            }
            
            .btn-outline:hover {
                background-color: rgba(255, 255, 255, 0.1);
            }
            
            .toggle-content {
                max-height: 0;
                overflow: hidden;
                transition: max-height 0.3s ease-out;
            }
            
            .toggle-content.expanded {
                max-height: 1000px;
            }
            
            .toggle-btn {
                background: none;
                border: none;
                color: var(--primary);
                cursor: pointer;
                font-weight: 600;
                display: flex;
                align-items: center;
                gap: 5px;
                margin: 10px 0;
                font-family: 'Nunito', sans-serif;
            }
            
            @media (max-width: 768px) {
                .policy-container {
                    flex-direction: column;
                }
                
                .sidebar {
                    position: static;
                }
                
                .footer-content {
                    flex-direction: column;
                    gap: 15px;
                }
                
                .header-content {
                    flex-direction: column;
                    gap: 15px;
                    text-align: center;
                }
                
                .consent-content {
                    flex-direction: column;
                    gap: 15px;
                    text-align: center;
                }
                
                h1 {
                    font-size: 2rem;
                }
                
                h2 {
                    font-size: 1.6rem;
                }
            }
        </style>
    </head>
    <body>
        <header>
            <div class="container">
                <div class="header-content">
                    <div class="logo">
                        <div class="logo-icon">⚡</div>
                        <div class="logo-text">SkillStream</div>
                    </div>
                    <div class="last-updated">Last Updated: October 15, 2023</div>
                </div>
            </div>
        </header>
        
        <div class="container">
            <div class="policy-container">
                <aside class="sidebar">
                    <h3>Privacy Policy</h3>
                    <ul class="nav-links">
                        <li><a href="#intro" class="active">Introduction</a></li>
                        <li><a href="#data-collection">Data We Collect</a></li>
                        <li><a href="#cookies">Cookies & Tracking</a></li>
                        <li><a href="#data-sharing">Data Sharing</a></li>
                        <li><a href="#rights">Your Rights</a></li>
                        <li><a href="#retention">Data Retention</a></li>
                        <li><a href="#security">Data Security</a></li>
                        <li><a href="#international">International Transfers</a></li>
                        <li><a href="#contact">Contact Us</a></li>
                    </ul>
                </aside>
                
                <main class="content">
                    <h1>Privacy Policy</h1>
                    <p>This Privacy Policy explains how SkillStream Ltd. ("we," "our," or "us") collects, uses, discloses, and safeguards your information when you use our SkillStream application and services.</p>
                    
                    <section id="intro">
                        <h2>1. Data Controller and Contact Information</h2>
                        <p>The controller of your personal data is <strong>SkillStream Ltd.</strong>, the operator of the SkillStream application.</p>
                        
                        <div class="contact-card">
                            <h3>Our Contact Details</h3>
                            <p><strong>Company Name:</strong> SkillStream Ltd.</p>
                            <p><strong>Registered Office:</strong> 123 Tech Avenue, Budapest, Hungary, 1011</p>
                            <p><strong>E-mail:</strong> privacy@skillstream.com</p>
                            <p><strong>Phone:</strong> +36 1 234 5678</p>
                        </div>
                    </section>
                    
                    <section id="data-collection">
                        <h2>2. What Personal Data We Collect and Why</h2>
                        <p>We collect various types of information for several purposes to provide and improve our Service to you.</p>
                        
                        <h3>Data Collection Overview</h3>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Data Category</th>
                                    <th>Specific Data</th>
                                    <th>Purpose of Processing</th>
                                    <th>Legal Basis</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td><strong>Registration Data</strong></td>
                                    <td>Email address, username, password (hashed), date of birth</td>
                                    <td>To create and identify your account</td>
                                    <td>Performance of a contract</td>
                                </tr>
                                <tr>
                                    <td><strong>Profile Data</strong></td>
                                    <td>Profile picture, full name, bio, location, skills, expertise</td>
                                    <td>To personalize your profile and enable networking features</td>
                                    <td>Your consent</td>
                                </tr>
                                <tr>
                                    <td><strong>User Content</strong></td>
                                    <td>Posts, images, videos, comments, likes, shares</td>
                                    <td>To provide the core functionality of content sharing</td>
                                    <td>Performance of contract and consent</td>
                                </tr>
                                <tr>
                                    <td><strong>Social Data</strong></td>
                                    <td>Connections, followers, following lists</td>
                                    <td>To enable networking and build your professional community</td>
                                    <td>Performance of contract</td>
                                </tr>
                                <tr>
                                    <td><strong>Technical Data</strong></td>
                                    <td>IP address, device type, OS, browser, unique identifiers</td>
                                    <td>To ensure security, prevent abuse, diagnose problems</td>
                                    <td>Legitimate interest</td>
                                </tr>
                                <tr>
                                    <td><strong>Usage Data</strong></td>
                                    <td>App activity, features used, time spent, search queries</td>
                                    <td>To analyze and improve our service, personalize experience</td>
                                    <td>Your consent</td>
                                </tr>
                                <tr>
                                    <td><strong>Location Data</strong></td>
                                    <td>Geographic location (if permission granted)</td>
                                    <td>To provide location-specific features</td>
                                    <td>Your explicit consent</td>
                                </tr>
                            </tbody>
                        </table>
                        
                        <h4>Additional Data Processing Information</h4>
                        <p>We process your data with the utmost care and in compliance with applicable data protection regulations.</p>
                    </section>
                    
                    <section id="cookies">
                        <h2>3. Cookies and Similar Tracking Technologies</h2>
                        <p>We use cookies and similar technologies to provide, secure, and improve our Service.</p>
                        
                        <button class="toggle-btn" onclick="toggleContent('cookies-content')">
                            <span>View Cookie Details</span>
                            <span>▼</span>
                        </button>
                        
                        <div class="toggle-content" id="cookies-content">
                            <h3>Types of Cookies We Use</h3>
                            <ul>
                                <li><strong>Essential Cookies:</strong> Necessary for the app to function. Cannot be switched off.</li>
                                <li><strong>Analytical/Performance Cookies:</strong> Help us understand how users interact with SkillStream.</li>
                                <li><strong>Marketing Cookies:</strong> Used by third parties to show relevant ads on other platforms.</li>
                            </ul>
                            
                            <h4>Managing Your Cookie Preferences</h4>
                            <p>You can manage your cookie preferences within the app under <strong>Profile / Settings</strong>.</p>
                        </div>
                    </section>
                    
                    <section id="data-sharing">
                        <h2>4. Data Sharing with Third Parties</h2>
                        <p>We may share your personal data in a limited and secure manner with:</p>
                        
                        <h3>Third Party Categories</h3>
                        <ul>
                            <li><strong>Processors:</strong> Trusted service providers who process data on our behalf (e.g., cloud hosting, analytics, email delivery).</li>
                            <li><strong>Legal Requirements:</strong> When required by law, court order, or regulatory authority.</li>
                            <li><strong>Business Transfers:</strong> In connection with a merger, sale, or transfer of assets.</li>
                        </ul>
                        
                        <div class="highlight-box">
                            <strong>Important Note:</strong> Your public profile information and posts are visible to other users according to the privacy settings you choose.
                        </div>
                    </section>
                    
                    <section id="rights">
                        <h2>5. Your Data Protection Rights</h2>
                        <p>Under the GDPR, you have the following rights:</p>
                        
                        <button class="toggle-btn" onclick="toggleContent('rights-content')">
                            <span>View Your Rights in Detail</span>
                            <span>▼</span>
                        </button>
                        
                        <div class="toggle-content" id="rights-content">
                            <h3>Detailed Rights Explanation</h3>
                            <ol>
                                <li><strong>Right of Access:</strong> To request a copy of your personal data.</li>
                                <li><strong>Right to Rectification:</strong> To correct inaccurate or incomplete data.</li>
                                <li><strong>Right to Erasure:</strong> To request deletion of your data in certain circumstances.</li>
                                <li><strong>Right to Restriction of Processing:</strong> To request we stop processing some of your data.</li>
                                <li><strong>Right to Data Portability:</strong> To receive your data in a machine-readable format.</li>
                                <li><strong>Right to Object:</strong> To object to processing of your personal data.</li>
                                <li><strong>Right to Withdraw Consent:</strong> To withdraw consent at any time.</li>
                            </ol>
                            
                            <h4>Exercising Your Rights</h4>
                            <p>To exercise any of these rights, please contact us at <strong>privacy@skillstream.com</strong>. We will respond within <strong>30 days</strong>.</p>
                        </div>
                    </section>
                    
                    <section id="retention">
                        <h2>6. Data Retention Periods</h2>
                        <p>We retain your personal data only for as long as necessary:</p>
                        
                        <h3>Retention Guidelines</h3>
                        <ul>
                            <li><strong>Account Data:</strong> Retained while your account is active. Deleted after a 30-day grace period post-account deletion.</li>
                            <li><strong>Technical Data:</strong> Typically retained for up to 12 months.</li>
                            <li>We comply with legal obligations for retaining certain data.</li>
                        </ul>
                    </section>
                    
                    <section id="security">
                        <h2>7. Data Security</h2>
                        <p>We implement robust security measures to protect your data:</p>
                        
                        <h3>Security Measures</h3>
                        <ul>
                            <li>Encryption of data in transit (SSL/TLS)</li>
                            <li>Secure hashing of passwords</li>
                            <li>Regular security reviews and audits</li>
                            <li>Staff training on data protection</li>
                        </ul>
                    </section>
                    
                    <section id="international">
                        <h2>8. International Data Transfers</h2>
                        <p>Currently, we store and process your data within the European Economic Area (EEA). If we transfer data outside the EEA, we will ensure appropriate safeguards are in place.</p>
                        
                        <h3>Safeguard Mechanisms</h3>
                        <p>These may include Standard Contractual Clauses, Binding Corporate Rules, or adequacy decisions.</p>
                    </section>
                    
                    <section id="contact">
                        <h2>9. Contact Us</h2>
                        <p>If you have any questions about this Privacy Policy, please contact us:</p>
                        
                        <h3>Contact Information</h3>
                        <ul>
                            <li><strong>Email:</strong> privacy@skillstream.com</li>
                            <li><strong>Phone:</strong> +36 1 234 5678</li>
                            <li><strong>Address:</strong> SkillStream Ltd., 123 Tech Avenue, Budapest, Hungary, 1011</li>
                        </ul>
                        
                        <div class="highlight-box">
                            <h4>Complaints</h4>
                            <p>You have the right to lodge a complaint with a supervisory authority, in particular in your EU member state. In Hungary, this is the National Authority for Data Protection and Freedom of Information (NAIH).</p>
                        </div>
                    </section>
                    
                    <div class="highlight-box">
                        <p><strong>Disclaimer:</strong> This privacy policy supplements, but does not replace, our Terms of Service.</p>
                    </div>
                </main>
            </div>
        </div>
        
        <div class="consent-bar" id="consentBar">
            <div class="container">
                <div class="consent-content">
                    <p>We use cookies to enhance your experience. By continuing to visit this site you agree to our use of cookies.</p>
                    <div class="consent-buttons">
                        <button class="btn btn-primary" onclick="acceptCookies()">Accept All</button>
                        <button class="btn btn-outline" onclick="managePreferences()">Manage Preferences</button>
                    </div>
                </div>
            </div>
        </div>
        
        <footer>
            <div class="container">
                <div class="footer-content">
                    <div class="copyright">© 2023 SkillStream Ltd. All rights reserved.</div>
                    <div class="footer-links">
                        <a href="#">Terms of Service</a>
                        <a href="#">Privacy Policy</a>
                        <a href="#">Cookie Policy</a>
                        <a href="#">Contact Us</a>
                    </div>
                </div>
            </div>
        </footer>
        
        <script>
            // Toggle expandable content sections
            function toggleContent(id) {
                const content = document.getElementById(id);
                const button = content.previousElementSibling;
                
                content.classList.toggle('expanded');
                
                if (content.classList.contains('expanded')) {
                    button.querySelector('span:last-child').textContent = '▲';
                } else {
                    button.querySelector('span:last-child').textContent = '▼';
                }
            }
            
            // Cookie consent functions
            function acceptCookies() {
                document.getElementById('consentBar').style.display = 'none';
                // In a real implementation, you would set a cookie here
                console.log('Cookies accepted');
            }
            
            function managePreferences() {
                // In a real implementation, this would open a cookie preferences modal
                alert('Cookie preferences would open here. In a real implementation, this would be a modal with granular controls.');
            }
            
            // Smooth scrolling for navigation links
            document.querySelectorAll('.nav-links a').forEach(anchor => {
                anchor.addEventListener('click', function(e) {
                    e.preventDefault();
                    
                    const targetId = this.getAttribute('href');
                    const targetElement = document.querySelector(targetId);
                    
                    window.scrollTo({
                        top: targetElement.offsetTop - 20,
                        behavior: 'smooth'
                    });
                    
                    // Update active link
                    document.querySelectorAll('.nav-links a').forEach(link => {
                        link.classList.remove('active');
                    });
                    this.classList.add('active');
                });
            });
            
            // Update active link on scroll
            window.addEventListener('scroll', function() {
                const sections = document.querySelectorAll('section');
                const navLinks = document.querySelectorAll('.nav-links a');
                
                let current = '';
                sections.forEach(section => {
                    const sectionTop = section.offsetTop;
                    const sectionHeight = section.clientHeight;
                    if (pageYOffset >= sectionTop - 60) {
                        current = section.getAttribute('id');
                    }
                });
                
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === '#' + current) {
                        link.classList.add('active');
                    }
                });
            });
        </script>
    </body>
    </html>
    """
}


struct GDPRContent: View {
    @State private var showingGDPR = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SkillStream")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Adatvédelmi irányelvek megtekintése") {
                showingGDPR = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingGDPR) {
            GDPRView()
            // vagy: GDPRInlineView()
        }
    }
}

// Alternatív megoldás: WebKit nélküli, natív SwiftUI megjelenítés
struct GDPRNativeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView()
                    
                    SectionView(title: "1. Adatkezelő és elérhetőségei") {
                        Text("Az Ön személyes adatainak kezelője a **SkillStream Kft.**, mint a SkillStream alkalmazás üzemeltetője.")
                        
                        ContactCardView()
                    }
                    
                    // További szekciók...
                    
                    DisclaimerView()
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Kész") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("SkillStream")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Adatvédelmi irányelvek")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Utoljára frissítve: 2023. október 15.")
                .font(.caption)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(15)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 5)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct ContactCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elérhetőségeink")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("**Cég neve:** SkillStream Kft.")
                Text("**Székhely:** 123 Tech Avenue, Budapest")
                Text("**E-mail:** privacy@skillstream.com")
                Text("**Telefon:** +36 1 234 5678")
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.pink, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
    }
}

struct DisclaimerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fontos megjegyzés")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Ez az adatvédelmi irányelv kiegészíti, de nem helyettesíti az Általános Szerződési Feltételeinket.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}
import SwiftUI

#Preview("Quick Test") {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GDPRView()
                


            }
            .padding()
    }
}
