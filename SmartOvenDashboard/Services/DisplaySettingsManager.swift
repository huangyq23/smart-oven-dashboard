//
//  DisplaySettingsManager.swift
//  SmartOvenDashboard
//
//

import Foundation

enum DisplayTemperatureUnit: String, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
    case kelvin = "K"
}

class DisplaySettingsManager: ObservableObject {
    @Published var temperatureUnit: DisplayTemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "displayTemperatureUnit")
        }
    }
    
    convenience init(forceUnit: DisplayTemperatureUnit) {
        self.init()
        self.temperatureUnit = forceUnit
    }

    init() {
        let savedUnit = UserDefaults.standard.string(forKey: "displayTemperatureUnit") ?? DisplayTemperatureUnit.celsius.rawValue
        temperatureUnit = DisplayTemperatureUnit(rawValue: savedUnit) ?? .celsius
    }

    func toggleUnit() {
        switch temperatureUnit {
        case .celsius:
            temperatureUnit = .fahrenheit
        case .fahrenheit:
            temperatureUnit = .kelvin
        case .kelvin:
            temperatureUnit = .celsius
        }
    }
    
    func displayTemperatureWithoutUnit(_ temperatureCelsius: Double) -> String {
        switch temperatureUnit {
        case .celsius:
            return String(format: "%.2f", temperatureCelsius)
        case .fahrenheit:
            return String(format: "%.2f", convertToFahrenheit(celsius: temperatureCelsius))
        case .kelvin:
            return String(format: "%.2f", convertToKelvin(celsius: temperatureCelsius))
        }
    }

    func displayTemperature(_ temperatureCelsius: Double) -> String {
        switch temperatureUnit {
        case .celsius:
            return String(format: "%.2f°C", temperatureCelsius)
        case .fahrenheit:
            return String(format: "%.2f°F", convertToFahrenheit(celsius: temperatureCelsius))
        case .kelvin:
            return String(format: "%.2fK", convertToKelvin(celsius: temperatureCelsius))
        }
    }
    
    func rawDisplayTemperature(_ temperatureCelsius: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return temperatureCelsius
        case .fahrenheit:
            return convertToFahrenheit(celsius: temperatureCelsius)
        case .kelvin:
            return convertToKelvin(celsius: temperatureCelsius)
        }
    }

    private func convertToFahrenheit(celsius: Double) -> Double {
        return celsius * 9 / 5 + 32
    }

    private func convertToKelvin(celsius: Double) -> Double {
        return celsius + 273.15
    }
}



