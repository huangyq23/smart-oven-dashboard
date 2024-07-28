//
//  TokenManager.swift
//  SmartOvenDashboard
//
//

import Foundation
import KeychainSwift
import OSLog

class TokenManager {
    static let shared = TokenManager()
    
    private let keychain = KeychainSwift()
    
    private init() {}
    
    func fetchAuthDetails() -> AuthDetails? {
        if let data = keychain.getData("tokens") {
            let decoder = JSONDecoder()
            do {
                let authDetails = try decoder.decode(AuthDetails.self, from: data)
                return authDetails
            } catch {
                print("Error decoding object")
                return nil
            }
        }
        return nil
    }
    
    func saveAuthDetails(_ authDetails: AuthDetails) -> Bool {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(authDetails)
            keychain.set(data, forKey: "tokens", withAccess: .accessibleAfterFirstUnlock)
            return true
        } catch {
            print("Error encoding object: \(error)")
            return false
        }
    }
    
    func clearAuthDetails() {
        keychain.delete("tokens")
    }
    
    func getAuthDetails() async -> AuthDetails? {
        if let authDetails = fetchAuthDetails() {
            if !authDetails.isTokenExpired() {
                return authDetails
            }
                        
            do {
                let refreshedAuthDetails = try await refreshToken(authDetails: authDetails)
                if !refreshedAuthDetails.isTokenExpired() {
                    saveAuthDetails(authDetails)
                    return refreshedAuthDetails
                }
            } catch {
                Logger.appLogging.error("\(error)")
            }
        }
        return nil
    }
    
}
