import SwiftUI

public extension Color {
    /// Namespace to prevent naming collisions with static accessors on
    /// SwiftUI's Color.
    ///
    /// Xcode's autocomplete allows for easy discovery of design system colors.
    /// At any call site that requires a color, type `Color.DesignSystem.<esc>`
    struct DesignSystem {
        public static let fokekszin = Color(red: 0.22745098173618317, green: 0.3843137323856354, blue: 0.5215686559677124, opacity: 1)
        public static let bordosszin = Color(red: 0.4862745098, green: 0.2666666667, blue: 0.3098039216, opacity: 1)
        public static let fopirosasszin = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.5686274766921997, green: 0.3333333432674408, blue: 0.3607843220233917, opacity: 1), location: 0.6791983246803284), Gradient.Stop(color: Color(red: 0.16862747073173523, green: 0.09885058552026749, blue: 0.1069912239909172, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5000000485154097, y: -6.930773212288077e-10), endPoint: UnitPoint(x: 0.5116279564395947, y: 0.8139535095653486))
        public static let pirosasszin = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.40784314274787903, green: 0.35686275362968445, blue: 0.43921568989753723, opacity: 1), location: 0), Gradient.Stop(color: Color(red: 0.5686274766921997, green: 0.33725491166114807, blue: 0.364705890417099, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let elsomunkahatter = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.14901961386203766, green: 0.3921568691730499, blue: 0.5568627715110779, opacity: 1), location: 0), Gradient.Stop(color: Color(red: 0.6235294342041016, green: 0.32156863808631897, blue: 0.3333333432674408, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let masodikmunkahatter = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.6235294342041016, green: 0.32156863808631897, blue: 0.3333333432674408, opacity: 1), location: 0), Gradient.Stop(color: Color(red: 0.8823529481887817, green: 0.4156862795352936, blue: 0.3294117748737335, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let harmadikmunkahatter = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.8823529481887817, green: 0.4156862795352936, blue: 0.3294117748737335, opacity: 1), location: 0.40234726667404175), Gradient.Stop(color: Color(red: 0.9450980424880981, green: 0.5921568870544434, blue: 0.3686274588108063, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let negyedikmunkahatter = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.8823529481887817, green: 0.4156862795352936, blue: 0.3294117748737335, opacity: 1), location: 0), Gradient.Stop(color: Color(red: 0.9529411792755127, green: 0.6196078658103943, blue: 0.3764705955982208, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let descriptions = Color(red: 0.8901960849761963, green: 0.729411780834198, blue: 0.4156862795352936, opacity: 1)
        public static let keresosavja = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.14901961386203766, green: 0.3921568691730499, blue: 0.5568627715110779, opacity: 1), location: 0.625), Gradient.Stop(color: Color(red: 0.04197736084461212, green: 0.11046673357486725, blue: 0.1568627655506134, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: 1), endPoint: UnitPoint(x: 0.5, y: 0))
        public static let oliva = Color(red: 85/255.0, green: 107/255.0, blue: 47/255.0, opacity: 1)
        public static let fomunkahatter = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.14901961386203766, green: 0.3921568691730499, blue: 0.5568627715110779, opacity: 1), location: 0), Gradient.Stop(color: Color(red: 0.9882352948188782, green: 0.7333333492279053, blue: 0.003921568859368563, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let fomunkahatter2 = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.14901961386203766, green: 0.3921568691730499, blue: 0.5568627715110779, opacity: 1), location: 0.10000000149011612), Gradient.Stop(color: Color(red: 0.5686274766921997, green: 0.5627450942993164, blue: 0.2803921699523926, opacity: 1), location: 0.550000011920929), Gradient.Stop(color: Color(red: 0.9882352948188782, green: 0.7333333492279053, blue: 0.003921568859368563, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let sargaska = LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(red: 0.8313725590705872, green: 0.686274528503418, blue: 0.21568627655506134, opacity: 1), location: 0.10000000149011612), Gradient.Stop(color: Color(red: 0.545098066329956, green: 0.3960784375667572, blue: 0.0313725508749485, opacity: 1), location: 1)]), startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17), endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
        public static let barack = Color(red: 220/255, green: 200/255, blue: 230/255, opacity: 1)
        
        
        
        
        
        public static let olivabogyo = Color(#colorLiteral(red: 0.537254902, green: 0.5764705882, blue: 0.4862745098, alpha: 1))
        public static let sargu = Color(#colorLiteral(red: 0.9921568627, green: 0.7921568627, blue: 0.2509803922, alpha: 1))
        public static let menta = Color(#colorLiteral(red: 0.7607843137, green: 0.937254902, blue: 0.9215686275, alpha: 1))
        public static let szurke = Color(#colorLiteral(red: 0.2901960784, green: 0.3058823529, blue: 0.4117647059, alpha: 1))





    }
}

