//
//  WebAuthenticationSession.swift
//  SmartOvenDashboard
//

import SwiftUI
import AuthenticationServices

struct WebAuthenticationSession: UIViewControllerRepresentable {
    let url = URL(string: "https://anovaculinary.io/ali/?redirect_uri=smartoven://load")!
    let callbackURLScheme = "smartoven"
    var completionHandler: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { callbackURL, error in
            
            if let url = callbackURL {
                let accessToken = getQueryParameterValue(from: url, paramKey: "access_token")
                print("Access Token: \(accessToken!)")
                
                var components = URLComponents(string: "https://oven.anovaculinary.com/signin?token_type=bearer")
                
                components?.queryItems?.append(URLQueryItem(name: "access_token", value: accessToken))
                
                Task {
                    do {
                        let nextDataString = try await fetchHTMLContent(from: (components?.url)!, elementId: "__NEXT_DATA__")
                        let userCustomToken = try parseUserCustomToken(from: nextDataString)
                        let authResponse = try await fetchAuthResponse(token: userCustomToken)
                        let authDetails = AuthDetails(from: authResponse)
                        let success = TokenManager.shared.saveAuthDetails(authDetails)
                        if success {
                            print("\(String(describing: authDetails))")
                            DevicesManager.shared.needsAuthentication = false
                            self.completionHandler(true)
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.completionHandler(false)
            }
            
        }
        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = context.coordinator
        session.start()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return ASPresentationAnchor()
        }
    }
}
