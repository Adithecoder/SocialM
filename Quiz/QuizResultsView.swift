//
//  QuizResultsView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/15/25.
//


//
//  QuizResultsView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2023. 11. 21.
//

import SwiftUI

// MARK: - Quiz Results View
struct QuizResultsView: View {
    @ObservedObject var session: QuizSession
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfetti = false
    @State private var animatedScores = false
    @State private var showDetails = false
    @State private var pulseAnimation = false
    
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    
    private var sortedPlayers: [QuizPlayer] {
        session.players.sorted { $0.score > $1.score }
    }
    
    private var currentPlayer: QuizPlayer? {
        session.players.first
    }
    
    private var playerRank: Int {
        sortedPlayers.firstIndex { $0.id == currentPlayer?.id } ?? 0 + 1
    }
    
    private var correctAnswersCount: Int {
        guard let player = currentPlayer else { return 0 }
        var correctCount = 0
        for (index, question) in session.quiz.questions.enumerated() {
            // Itt a valós implementációban ellenőriznénk a válaszokat
            // Most szimuláljuk
            if index % 2 == 0 { // Minden második kérdés helyes
                correctCount += 1
            }
        }
        return correctCount
    }
    
    var body: some View {
        ZStack {
            // Háttér
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.08), .green.opacity(0.08)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Konfetti
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Fő eredmény kártya
                    mainResultCard
                    
                    // Ranglista
                    leaderboardSection
                    
                    // Statisztikák
                    statisticsSection
                    
                    // Részletes eredmények
                    if showDetails {
                        detailedResultsSection
                    }
                    
                    // Művelet gombok
                    actionButtonsSection
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Fő eredmény kártya
    private var mainResultCard: some View {
        VStack(spacing: 20) {
            // Rang ikon
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Group {
                    if playerRank == 1 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                    } else if playerRank <= 3 {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 45))
                    } else {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 40))
                    }
                }
                .foregroundColor(rankColor)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            }
            
            // Rang szöveg
            VStack(spacing: 8) {
                Text(rankTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(rankColor)
                
                Text(rankSubtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Pontszám
            VStack(spacing: 4) {
                Text("\(currentPlayer?.score ?? 0)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(animatedScores ? 1.0 : 0.5)
                    .opacity(animatedScores ? 1.0 : 0.0)
                
                Text("pont")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Teljesítmény mérő
            performanceGauge
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(rankColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Ranglista
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ranglista")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(session.players.count) játékos")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    LeaderboardRow(
                        player: player,
                        rank: index + 1,
                        isCurrentPlayer: player.id == currentPlayer?.id,
                        score: player.score
                    )
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Statisztikák
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statisztikák")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard4(
                    icon: "checkmark.circle.fill",
                    value: "\(correctAnswersCount)",
                    label: "helyes válasz",
                    color: .green
                )
                
                StatCard4(
                    icon: "xmark.circle.fill",
                    value: "\(session.quiz.questions.count - correctAnswersCount)",
                    label: "helytelen válasz",
                    color: .red
                )
                
                StatCard4(
                    icon: "clock.fill",
                    value: "\(calculateAverageTime())s",
                    label: "átlagos idő",
                    color: .orange
                )
                
                StatCard4(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(calculateAccuracy())%",
                    label: "pontosság",
                    color: .blue
                )
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Részletes eredmények
    private var detailedResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Kérdésenkénti eredmények")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showDetails = false }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(session.quiz.questions.enumerated()), id: \.offset) { index, question in
                    QuestionResultRow(
                        question: question,
                        questionNumber: index + 1,
                        isCorrect: index % 2 == 0, // Szimuláció
                        playerAnswer: index % 3, // Szimuláció
                        timeSpent: Double.random(in: 5...25)
                    )
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Művelet gombok
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: onPlayAgain) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Új játék")
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button(action: { showDetails.toggle() }) {
                HStack {
                    Image(systemName: showDetails ? "chevron.up" : "chart.bar.fill")
                    Text(showDetails ? "Részletek elrejtése" : "Részletes eredmények")
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
            }
            
            Button(action: onExit) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Vissza a főképernyőre")
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Teljesítmény mérő
    private var performanceGauge: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Teljesítmény")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(performanceLevel)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(performanceColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Háttér
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress
                    Rectangle()
                        .fill(performanceGradient)
                        .frame(width: geometry.size.width * performancePercentage, height: 8)
                        .cornerRadius(4)
                        .shadow(color: performanceColor.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Számított tulajdonságok
    private var rankColor: Color {
        switch playerRank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankTitle: String {
        switch playerRank {
        case 1: return "🏆 Győztes!"
        case 2: return "🥈 Második"
        case 3: return "🥉 Harmadik"
        case 4...5: return "Kiváló"
        case 6...8: return "Jó"
        default: return "Respekt"
        }
    }
    
    private var rankSubtitle: String {
        switch playerRank {
        case 1: return "Első helyezés! Gratulálunk!"
        case 2: return "Szép második hely!"
        case 3: return "Bronzérem, ügyes vagy!"
        case 4...5: return "A dobogó közelében!"
        case 6...8: return "Szolid teljesítmény!"
        default: return "Minden próbálkozás számít!"
        }
    }
    
    private var performancePercentage: Double {
        guard let maxScore = sortedPlayers.first?.score, maxScore > 0 else { return 0 }
        return Double(currentPlayer?.score ?? 0) / Double(maxScore)
    }
    
    private var performanceLevel: String {
        let percentage = performancePercentage
        switch percentage {
        case 0.9...1.0: return "Kiváló"
        case 0.7..<0.9: return "Nagyon jó"
        case 0.5..<0.7: return "Jó"
        case 0.3..<0.5: return "Átlagos"
        default: return "Fejlődő"
        }
    }
    
    private var performanceColor: Color {
        let percentage = performancePercentage
        switch percentage {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        case 0.3..<0.5: return .yellow
        default: return .red
        }
    }
    
    private var performanceGradient: LinearGradient {
        LinearGradient(
            colors: [performanceColor.opacity(0.8), performanceColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Műveletek
    private func startAnimations() {
        // Konfetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                showConfetti = true
            }
        }
        
        // Pontszám animáció
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedScores = true
            }
        }
        
        // Pulzáló animáció
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        
        // Konfetti időzített leállítás
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showConfetti = false
            }
        }
    }
    
    private func calculateAverageTime() -> Int {
        // Szimulált átlagos idő
        return Int.random(in: 8...18)
    }
    
    private func calculateAccuracy() -> Int {
        let totalQuestions = session.quiz.questions.count
        guard totalQuestions > 0 else { return 0 }
        return Int(Double(correctAnswersCount) / Double(totalQuestions) * 100)
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let player: QuizPlayer
    let rank: Int
    let isCurrentPlayer: Bool
    let score: Int
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rang
            Text(rankIcon)
                .font(.system(size: 20))
                .frame(width: 32)
            
            // Játékos információ
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isCurrentPlayer ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.username)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(isCurrentPlayer ? .blue : .primary)
                    
                    if isCurrentPlayer {
                        Text("Te")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Pontszám
            Text("\(score) pont")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(isCurrentPlayer ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentPlayer ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Stat Card
struct StatCard4: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Question Result Row
struct QuestionResultRow: View {
    let question: QuizQuestion
    let questionNumber: Int
    let isCorrect: Bool
    let playerAnswer: Int
    let timeSpent: Double

    // Extracted small views to reduce type-checker load
    private var headerView: some View {
        HStack {
            Text("\(questionNumber). kérdés")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color.primary)

            Spacer()

            scoreBadge
        }
    }

    private var scoreBadge: some View {
        let iconName: String = isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
        let scoreText: String = isCorrect ? "+10" : "0"
        let color: Color = isCorrect ? .green : .red

        return HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(scoreText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(color)
        }
    }

    private var subtitleView: some View {
        Text(question.question)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundColor(Color.secondary)
            .lineLimit(2)
    }

    private var footerView: some View {
        HStack {
            Label("\(Int(timeSpent))s", systemImage: "clock")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.secondary)

            Spacer()

            playerAnswerView
        }
    }

    private var playerAnswerView: some View {
        let answerText: String? = question.options[playerAnswer]
        return Group {
            if let text = answerText {
                Text("Válaszod: \(text)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.secondary)
                    .lineLimit(1)
            } else {
                EmptyView()
            }
        }
    }

    private var backgroundColor: Color {
        isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
    }

    private var strokeColor: Color {
        isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            subtitleView
            footerView
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
        let color: Color
        let size: Double
        let rotation: Double
        let speed: Double
    }
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<50 {
            let particle = Particle(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: Double.random(in: -100...UIScreen.main.bounds.height),
                color: colors.randomElement() ?? .blue,
                size: Double.random(in: 4...10),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 2...6)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleQuiz = Quiz(
        id: 1,
        title: "Általános tudás",
        description: "Teszteld általános tudásodat",
        category: "Tudomány",
        difficulty: .medium,
        questions: [
            QuizQuestion(id: 1, question: "Mi a Föld legnagyobb óceánja?", options: ["A", "B", "C", "D"], correctAnswer: 2),
            QuizQuestion(id: 2, question: "Hány kontinens van a Földön?", options: ["A", "B", "C", "D"], correctAnswer: 2)
        ],
        timeLimit: 30,
        maxPlayers: 4,
        createdBy: 1
    )
    
    let players = [
        QuizPlayer(id: 1, userId: 100, username: "Te", score: 85),
        QuizPlayer(id: 2, userId: 101, username: "Játékos 2", score: 92),
        QuizPlayer(id: 3, userId: 102, username: "Játékos 3", score: 78),
        QuizPlayer(id: 4, userId: 103, username: "Játékos 4", score: 65)
    ]
    
    let session = QuizSession(id: 1, quiz: sampleQuiz, players: players)
    
    return QuizResultsView(
        session: session,
        onPlayAgain: {
            print("Új játék!")
        },
        onExit: {
            print("Kilépés!")
        }
    )
}

