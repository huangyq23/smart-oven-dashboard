//
//  AuthenticationService.swift
//  SmartOvenDashboard
//
//
import Foundation
import SwiftSoup
import SwiftyJSON

struct OuterLayer: Codable {
    let props: PagePropsLayer
}

struct PagePropsLayer: Codable {
    let pageProps: UserCustomTokenLayer
}

struct UserCustomTokenLayer: Codable {
    let userCustomToken: String
}

struct AuthRequest: Codable {
    let token: String
    let returnSecureToken: Bool
}

struct AuthDetails: Codable {
    let idToken: String
    let refreshToken: String
    var expiresAt: Date
    
    init(from authResponse: any AuthTokenResponseProtocol) {
        self.idToken = authResponse.idToken
        self.refreshToken = authResponse.refreshToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(Int(authResponse.expiresIn)!))
    }
    
    func isTokenExpired() -> Bool {
        return Date() >= expiresAt
    }
}

protocol AuthTokenResponseProtocol {
    var idToken: String { get }
    var refreshToken: String { get }
    var expiresIn: String { get }
}

struct AuthResponse: Codable, AuthTokenResponseProtocol {
    let idToken: String
    let refreshToken: String
    var expiresIn: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    let grantType: String
    
    init(from authDetails: AuthDetails) {
        self.refreshToken = authDetails.refreshToken
        self.grantType = "refresh_token"
    }
}

struct TokenResponse: Codable, AuthTokenResponseProtocol {
    let accessToken, expiresIn, tokenType, refreshToken: String
    let idToken, userId, projectId: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case userId = "user_id"
        case projectId = "project_id"
    }
}

struct AuthError: Decodable {
    let error: ErrorDetail
}

struct ErrorDetail: Decodable {
    let message: String
}

func getQueryParameterValue(from url: URL, paramKey: String) -> String? {
    guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        print("Cannot create URLComponents")
        return nil
    }
    
    return urlComponents.queryItems?.first(where: { $0.name == paramKey })?.value
}

func fetchHTMLContent(from url: URL, elementId: String) async throws -> String {
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8) ?? ""
    let doc: Document = try SwiftSoup.parse(html)
    guard let element = try doc.getElementById(elementId) else {
        throw NSError(domain: "ElementNotFound", code: 0, userInfo: [NSLocalizedDescriptionKey: "Element with ID \(elementId) not found"])
    }
    return try element.html()
}

// Async function to parse the JSON string
func parseUserCustomToken(from jsonString: String) throws -> String {
    // Convert the JSON string to Data
    guard let jsonData = jsonString.data(using: .utf8) else {
        throw NSError(domain: "Invalid JSON", code: 0, userInfo: nil)
    }

    // Decode the JSON data
    let decoder = JSONDecoder()
    let decodedData = try decoder.decode(OuterLayer.self, from: jsonData)

    // Extract the userCustomToken
    return decodedData.props.pageProps.userCustomToken
}


func fetchAuthResponse(token: String) async throws -> AuthResponse {
    let requestPayload = AuthRequest(token: token, returnSecureToken: true)

    guard let url = URL(string: "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyCustomToken?key=AIzaSyB0VNqmJVAeR1fn_NbqqhwSytyMOZ_JO9c") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONEncoder().encode(requestPayload)
    } catch {
        throw error
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(AuthResponse.self, from: data)
}

func refreshToken(authDetails: AuthDetails) async throws -> AuthDetails {
    
    let requestPayload = RefreshTokenRequest(from: authDetails)
    
    guard let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDQiOP2fTR9zvFcag2kSbcmG9zPh6gZhHw") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONEncoder().encode(requestPayload)
    } catch {
        throw error
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
    
    return AuthDetails(from: tokenResponse)
}
