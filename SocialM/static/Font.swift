//
//  Font.swift
//  SocialM
//
//  Created by Czeglédi Ádi on 10/10/25.
//

import SwiftUI

extension Font {
    static func lexend(fontStyle: Font.TextStyle = .body, fontWeight: Weight = .regular) -> Font {
        return Font.custom(CustomFonts(weight: fontWeight).rawValue, size:18)
    }
    
    static func lexend2(fontStyle: Font.TextStyle = .body, fontWeight: Weight = .regular) -> Font {
        return Font.custom(CustomFonts(weight: fontWeight).rawValue, size:16)
    }
    
    static func lexend3(fontStyle: Font.TextStyle = .body, fontWeight: Weight = .regular) -> Font {
        return Font.custom(CustomFonts(weight: fontWeight).rawValue, size:13)
    }
    
    
    
}
enum CustomFonts: String {
    case regular = "Lexend"
    case semibold = "Lexend-Semibold"
    
        
    init(weight: Font.Weight){
        switch weight {
            case .regular:
            self = .regular
        case .semibold:
            self = .semibold
            
            default :
            self = .regular
        }

    }
}
