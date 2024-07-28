//
//  LoginStatusView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import OSLog

struct LoginStatusView: View {
    @Environment(DevicesManager.self) var devicesManager
    
    var body: some View {
        if devicesManager.needsAuthentication {
            SignInView()
        }
    }
}

struct SignInView: View {
    @State private var showWebAuthenticationSession = false
    
    var body: some View {
        Button("Log In") {
            self.showWebAuthenticationSession = true
        }
        .foregroundStyle(.blue)
        .sheet(isPresented: $showWebAuthenticationSession) {
            WebAuthenticationSession { success in
                self.showWebAuthenticationSession = false
            }
        }
    }
}

struct SignOutView: View {
    var signOut: () -> Void = {}
    
    var body: some View {
        Button (action: signOut) {
            Text("Log Out")
        }
//        Button {
//            exit(0)
//        } label: {
//            Text("Quit")
//        }
//        Button {
//            do {
//                let logs = try Logger.retrieveLogs(since: -3600)
//                logs.forEach { print($0) }
//            } catch {
//                print("Error retrieving logs: \(error)")
//            }
//        } label: {
//            Text("Log!")
//        }
    }
}

#Preview {
    LoginStatusView().environment(DevicesManager.shared)
}

#Preview("Sign In") {
    SignInView()
}

#Preview("Sign Out") {
    SignOutView()
}
