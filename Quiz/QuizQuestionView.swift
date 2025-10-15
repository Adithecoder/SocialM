//
//  QuizQuestionView.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 2023. 11. 21.
//

import SwiftUI

// MARK: - Quiz Question View
struct QuizQuestionView: View {
    @ObservedObject var session: QuizSession
    @State private var selectedAnswer: Int?
    @State private var progress: Double = 1.0
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var showTimeWarning = false
    @State private var pulseAnimation = false
    @State private var answerSubmitted = false
    @State private var showTimeUp = false

    let onAnswerSelected: (Int) -> Void
    let onTimeUp: () -> Void
    let onProceedToNextQuestion: () -> Void

    init(session: QuizSession,
          onAnswerSelected: @escaping (Int) -> Void,
          onTimeUp: @escaping () -> Void,
          onProceedToNextQuestion: @escaping () -> Void) {
         self.session = session
         self.onAnswerSelected = onAnswerSelected
         self.onTimeUp = onTimeUp
         self.onProceedToNextQuestion = onProceedToNextQuestion
         self._timeRemaining = State(initialValue: session.quiz.timeLimit)
     }
    
    var currentQuestion: QuizQuestion {
        session.quiz.questions[session.currentQuestionIndex]
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
            
            VStack(spacing: 0) {
                // Fejléc
                headerSection
                
                // Fő tartalom
                ScrollView {
                    VStack(spacing: 24) {
                        // Kérdés kártya
                        questionCard
                        
                        // Válaszlehetőségek
                        answerOptionsSection
                        
                        // Idő és játékos információk
                        infoSection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                
                // Művelet gomb
                if selectedAnswer != nil && !answerSubmitted {
                    submitButton
                }
                
               
            
            }
            if showTimeUp {
                TimeUpView(onContinue: {
                    // Következő kérdés vagy eredmények
                    showTimeUp = false
                    proceedToNextQuestion()
                })
            }
            
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: session.currentQuestionIndex) { _ in
            resetForNewQuestion()
        }
    }
    
    // MARK: - Fejléc
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Progress bar és idő
            HStack(spacing: 12) {
                // Timer circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timeColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    Text("\(timeRemaining)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(timeColor)
                }
                
                // Question progress
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kérdés")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(session.currentQuestionIndex + 1) / \(session.quiz.questions.count)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Nehézség
                DifficultyBadge(difficulty: session.quiz.difficulty)
                    .scaleEffect(0.9)
            }
            .padding(.horizontal)
            
            // Main progress bar
            ProgressView(value: Double(session.currentQuestionIndex + 1), total: Double(session.quiz.questions.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Kérdés kártya
    private var questionCard: some View {
        VStack(spacing: 20) {
            // Kérdés száma
            HStack {
                Text("KÉRDÉS #\(session.currentQuestionIndex + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.gradient)
                    )
                
                Spacer()
                
                // Pont érték
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("10 pont")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Kérdés szövege
            Text(currentQuestion.question)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Kategória
            HStack {
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(session.quiz.category)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Idő figyelmeztetés
                if showTimeWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text("Siess!")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Válaszlehetőségek
    private var answerOptionsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<currentQuestion.options.count, id: \.self) { index in
                AnswerOptionView(
                    option: currentQuestion.options[index],
                    index: index,
                    isSelected: selectedAnswer == index,
                    isDisabled: answerSubmitted,
                    action: { selectAnswer(index) }
                )
            }
        }
    }
    
    // MARK: - Információs szekció
    private var infoSection: some View {
        VStack(spacing: 16) {
            // Aktív játékosok
            if session.players.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Játékosok")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(session.players) { player in
                            PlayerStatusView(player: player, hasAnswered: player.currentAnswer != nil)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Játék tippek
            TipView(tip: getRandomTip())
        }
    }
    
    // MARK: - Beküldés gomb
    private var submitButton: some View {
        Button(action: submitAnswer) {
            HStack {
                Text("Válasz beküldése")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                Image(systemName: "paperplane.fill")
            }
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
            .scaleEffect(answerSubmitted ? 0.95 : 1.0)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .disabled(answerSubmitted)
    }
    
    // MARK: - Számított tulajdonságok
    private var timeColor: Color {
        if timeRemaining > session.quiz.timeLimit * 2/3 {
            return .green
        } else if timeRemaining > session.quiz.timeLimit * 1/3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Műveletek
    private func startTimer() {
            timeRemaining = session.quiz.timeLimit
            progress = 1.0
            timer?.invalidate()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    progress = Double(timeRemaining) / Double(session.quiz.timeLimit)
                    
                    // Figyelmeztetés mutatása
                    if timeRemaining <= 10 && !showTimeWarning {
                        showTimeWarning = true
                        pulseAnimation = true
                    }
                } else {
                    timer?.invalidate()
                    showTimeUp = true // 👈 EZ HIÁNYZOTT
                    onTimeUp()
                }
            }
        }
    
    private func selectAnswer(_ index: Int) {
        guard !answerSubmitted else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedAnswer = index
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func proceedToNextQuestion() {
         showTimeUp = false
         selectedAnswer = nil
         // A következő kérdésre lépés logikája itt történik
         // Ez a szülő komponens feladata lesz
     }
    
    private func submitAnswer() {
        guard let answer = selectedAnswer, !answerSubmitted else { return }
        
        answerSubmitted = true
        timer?.invalidate()
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Válasz elküldése
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onAnswerSelected(answer)
        }
    }
    
    private func resetForNewQuestion() {
        selectedAnswer = nil
        answerSubmitted = false
        showTimeWarning = false
        pulseAnimation = false
        timer?.invalidate()
        startTimer()
    }
    
    private func getRandomTip() -> String {
        let tips = [
            "Olvasd el figyelmesen a kérdést mielőtt válaszolsz!",
            "Az első ötlet nem mindig a legjobb, de ne gondolkozz túl sokat!",
            "Ha nem tudod a választ, próbáld kizárni a nyilvánvalóan rossz válaszokat!",
            "Figyelj az időre, de ne siess túl sokat!",
            "A nehéz kérdések ugyanannyit érnek, mint a könnyűek!"
        ]
        return tips.randomElement() ?? tips[0]
    }
}

// MARK: - Answer Option View
struct AnswerOptionView: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var bounce = false
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.15)
        } else {
            return .gray.opacity(0.08)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .blue
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Válasz betűjele
                Text(String(UnicodeScalar(65 + index)!)) // A, B, C, D
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    )
                
                // Válasz szövege
                Text(option)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                Spacer()
                
                // Kijelölés ikon
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .scaleEffect(bounce ? 1.2 : 1.0)
                }
            }
            .padding(20)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
            .shadow(
                color: isSelected ? .blue.opacity(0.2) : .black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onChange(of: isSelected) { selected in
            if selected {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounce = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        bounce = false
                    }
                }
            }
        }
    }
}

// MARK: - Player Status View
struct PlayerStatusView: View {
    let player: QuizPlayer
    let hasAnswered: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(hasAnswered ? .green : .gray)
            
            Text(player.username)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(hasAnswered ? .primary : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            if hasAnswered {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Time Up View
struct TimeUpView: View {
    @State private var scaleEffect = 0.5
    @State private var opacity = 0.0
    @State private var rotation = 0.0
    @State private var pulse = 0.0
    @State private var textGlow = 0.0
    @State private var particles: [Particle] = []
    @State private var showButtons = false
    @State private var backgroundPulse = 0.0
    @State private var showTimeText = false
    @State private var showParticles = false
    @State private var animationPhase = 0
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Sötét háttér overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Fő tartalom
            VStack(spacing: 40) {
                            // 👈 ITT VAN A CLOCK ANIMATION - CSERÉLVE
                            ClockAnimationView(shakeAmount: backgroundPulse)
                                .scaleEffect(1.2)
                            
                            // Szöveg animáció
                            VStack(spacing: 20) {
                                Text("IDŐ LETELT!")
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .glowEffect(color: .red, intensity: 1.0)
                                    .shadow(color: .black, radius: 10)
                                
                                if showTimeText {
                                    Text("Sajnos nem sikerült időben válaszolnod.\nA következő kérdésre készülj!")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .transition(.opacity.combined(with: .scale))
                                }
                            }
                            
                            // Akció gomb
                            if animationPhase >= 2 {
                                Button(action: onContinue) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Tovább a következő kérdésre")
                                    }
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                                }
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .padding(40)
                    }
                    .onAppear {
                        startAnimations()
                    }
                }
    
    // MARK: - Animációk indítása
    private func startAnimations() {
        // 1. Óra rázkódás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.2)) {
                backgroundPulse = 1.0
            }
        }
        
        // 2. Szöveg beúszás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            }
        }
        
        // 3. Háttér pulzálás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                backgroundPulse = 1.0
            }
        }
        
        // 4. Részecskék megjelenése
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.5)) {
                showParticles = true
            }
        }
        
        // 5. További szöveg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showTimeText = true
                animationPhase = 1
            }
        }
        
        // 6. Gomb megjelenése
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = 2
            }
        }
        
        // Hang effekt szimuláció
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔊 Time's up sound effect")
        }
    }
    
    // MARK: - Részecskék generálása
    private func generateParticles() {
        let particleCount = 30
        let colors: [Color] = [.red, .orange, .yellow, .white]
        
        for _ in 0..<particleCount {
            let particle = Particle(
                id: UUID(),
                x: Double.random(in: 0.3...0.7) * UIScreen.main.bounds.width,
                y: Double.random(in: 0.3...0.7) * UIScreen.main.bounds.height,
                color: colors.randomElement()!,
                size: Double.random(in: 4...12),
                speed: Double.random(in: 2...8),
                direction: Double.random(in: 0...360),
                life: Double.random(in: 1.0...3.0)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Particle Modell
struct Particle: Identifiable {
    let id: UUID
    var x: Double
    var y: Double
    let color: Color
    let size: Double
    let speed: Double
    let direction: Double
    let life: Double
}

// MARK: - Particle View
struct ParticleView: View {
    let particle: Particle
    @State private var opacity = 1.0
    @State private var scale = 1.0
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Részecske animáció
                withAnimation(.easeOut(duration: particle.life)) {
                    opacity = 0.0
                    scale = 0.1
                }
                
                // Részecske eltávolítása
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.life) {
                    // A valós implementációban el kell távolítani a tömbből
                }
            }
    }
}

// MARK: - Glow Effect Modifier
extension View {
    func glowEffect(color: Color, intensity: Double) -> some View {
        self
            .shadow(color: color.opacity(0.7 * intensity), radius: 5 * intensity)
            .shadow(color: color.opacity(0.5 * intensity), radius: 10 * intensity)
            .shadow(color: color.opacity(0.3 * intensity), radius: 15 * intensity)
    }
}

// MARK: - Enhanced Time Up View (Komplex verzió)
struct EnhancedTimeUpView: View {
    @State private var animationPhase = 0
    @State private var clockShake = 0.0
    @State private var textScale = 0.3
    @State private var backgroundPulse = 0.0
    @State private var showTimeText = false
    @State private var showParticles = false
    
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Animált háttér
            Color.black.opacity(0.8 + backgroundPulse * 0.2)
                .ignoresSafeArea()
            
            // Részecskék a háttérben
            if showParticles {
                TimeUpParticleField()
            }
            
            VStack(spacing: 40) {
                // Óra animáció
                ClockAnimationView(shakeAmount: clockShake)
                    .scaleEffect(1.2)
                
                // Szöveg animáció
                VStack(spacing: 20) {
                    Text("IDŐ LETELT!")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(textScale)
                        .glowEffect(color: .red, intensity: 1.0)
                        .shadow(color: .black, radius: 10)
                    
                    if showTimeText {
                        Text("A következő kérdésre fókuszálj\nés próbálj meg gyorsabb lenni!")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // Akció gomb
                if animationPhase >= 2 {
                    Button(action: onContinue) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Folytatás")
                        }
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .red.opacity(0.6), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(40)
        }
        .onAppear {
            startEnhancedAnimations()
        }
    }
    
    private func startEnhancedAnimations() {
        // 1. Óra rázkódás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.2)) {
                clockShake = 1.0
            }
        }
        
        // 2. Szöveg beúszás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                textScale = 1.0
            }
        }
        
        // 3. Háttér pulzálás
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                backgroundPulse = 1.0
            }
        }
        
        // 4. Részecskék megjelenése
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.5)) {
                showParticles = true
            }
        }
        
        // 5. További szöveg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showTimeText = true
                animationPhase = 1
            }
        }
        
        // 6. Gomb megjelenése
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Clock Animation View
struct ClockAnimationView: View {
    let shakeAmount: Double
    @State private var hourRotation = 0.0
    @State private var minuteRotation = 0.0
    @State private var explode = false
    
    var body: some View {
        ZStack {
            // Óra keret
            Circle()
                .fill(Color.red)
                .frame(width: 120, height: 120)
                .scaleEffect(explode ? 1.5 : 1.0)
                .opacity(explode ? 0.0 : 1.0)
            
            Circle()
                .fill(Color.orange)
                .frame(width: 100, height: 100)
                .scaleEffect(explode ? 1.3 : 1.0)
                .opacity(explode ? 0.0 : 1.0)
            
            // Óramutatók
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 30)
                .offset(y: -15)
                .rotationEffect(.degrees(hourRotation))
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 40)
                .offset(y: -20)
                .rotationEffect(.degrees(minuteRotation))
            
            // Középpont
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
        }
        .rotationEffect(.degrees(shakeAmount * 10))
        .offset(x: shakeAmount * 20, y: shakeAmount * 10)
        .onAppear {
            startClockAnimations()
        }
    }
    
    private func startClockAnimations() {
        // Óramutatók forgása
        withAnimation(.easeInOut(duration: 0.5)) {
            hourRotation = 45
            minuteRotation = 270
        }
        
        // Explosion effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                explode = true
            }
        }
    }
}

// MARK: - Particle Field
struct TimeUpParticleField: View {
    @State private var particles: [TimeParticle] = []
    
    struct TimeParticle: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var size: Double
        var speed: Double
        var color: Color
        var life: Double
    }
    
    var body: some View {
        ForEach(particles) { particle in
            Circle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
                .position(x: particle.x, y: particle.y)
                .opacity(particle.life)
        }
        .onAppear {
            generateParticleField()
        }
    }
    
    private func generateParticleField() {
        let colors: [Color] = [.red, .orange, .yellow, .white]
        for _ in 0..<50 {
            let particle = TimeParticle(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: Double.random(in: 0...UIScreen.main.bounds.height),
                size: Double.random(in: 2...8),
                speed: Double.random(in: 0.5...2),
                color: colors.randomElement()!,
                life: Double.random(in: 0.3...1.0)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Háttér a preview-hoz
        LinearGradient(
            gradient: Gradient(colors: [.blue, .purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Egyszerű verzió
        // TimeUpView(onContinue: { print("Continue tapped") })
        
        // Komplex verzió
        EnhancedTimeUpView(onContinue: { print("Continue tapped") })
    }
}

// MARK: - Usage in QuizQuestionView
/*
 Használat a QuizQuestionView-ben:
 
 struct QuizQuestionView: View {
     @State private var showTimeUp = false
     
     var body: some View {
         ZStack {
             // ... meglévő content
             
             if showTimeUp {
                 TimeUpView(onContinue: {
                     // Következő kérdés vagy eredmények
                     showTimeUp = false
                     proceedToNextQuestion()
                 })
             }
         }
         .onChange(of: timeRemaining) { time in
             if time == 0 {
                 showTimeUp = true
             }
         }
     }
 }
 */
// MARK: - Tip View
struct TipView: View {
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text(tip)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleQuiz = Quiz(
        id: 1,
        title: "Teszt",
        description: "Teszt",
        category: "Tudomány",
        difficulty: .medium,
        questions: [
            QuizQuestion(
                id: 1,
                question: "Mi a Föld legnagyobb óceánja?",
                options: ["Atlanti", "Indiai", "Csendes", "Északi-sarki"],
                correctAnswer: 2
            )
        ],
        timeLimit: 10,
        maxPlayers: 4,
        createdBy: 1
    )
    
    let session = QuizSession(id: 1, quiz: sampleQuiz, players: [])
    
    QuizQuestionView(
        session: session,
        onAnswerSelected: { _ in },
        onTimeUp: {},
        onProceedToNextQuestion: {}
    )
}
