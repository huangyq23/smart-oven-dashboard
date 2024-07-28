//
//  QuickControlsView.swift
//  SmartOvenDashboard
//
//

import SwiftUI

struct QuickControlsView: View {
    var cooking: Bool = false
    var lightOn: Bool = true
    
    var setLight: (_ on: Bool) -> Void = {on in }
    var stop: () -> Void = {}
    var steam: () -> Void = {}
    var airFry: () -> Void = {}
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(action: stop) {
                    QuickButtonImage(systemName: "stop.circle.fill", color: .red, active: cooking)
                }
                
                Button {
                    setLight(!lightOn)
                } label: {
                    QuickButtonImage(systemName: "lightbulb.circle.fill", color: .yellow, active: lightOn)
                }
                
                CookingModeButton(title: "Steam", action: steam)
                CookingModeButton(title: "Air Fry", action: airFry)
                CookingModeButton(title: "Convection\n Bake")
                CookingModeButton(title: "Proof")
                CookingModeButton(title: "Bake")
                CookingModeButton(title: "Dehydrate")
                CookingModeButton(title: "Broil")
            }
        }
    }
}

struct CookingModeButton: View {
    var title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
            .fontWeight(.semibold)
            .frame(minWidth: 80, minHeight: 40)
            .padding()
            .foregroundColor(.primary) // Text color
            .background(Color(UIColor.tertiarySystemGroupedBackground)) // Button background color
            .cornerRadius(10)
            .shadow(radius: 1.5, x: 0.5, y: 0.5)
        }.padding(2)
    }
}

#Preview {
    QuickControlsView()
}

#Preview("Light Off") {
    QuickControlsView(lightOn: false)
}

#Preview("Cooking") {
    QuickControlsView(cooking: true)
}

struct QuickButtonImage: View {
    var systemName: String
    var color: Color
    var active: Bool
    
    var body: some View {
        
        if active {
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .font(.system(size: 60))
        } else {
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.gray)
                .font(.system(size: 60))
        }
    }
}
