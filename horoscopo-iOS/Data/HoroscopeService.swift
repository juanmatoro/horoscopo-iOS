//
//  HoroscopeService.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import Foundation

// Pide a la API la predicción de un signo para un periodo
struct HoroscopeService {

    enum ServiceError: Error {
        case invalidURL
        case badResponse
    }

    // Refleja el JSON de la API: { "data": { "horoscope": "..." } }
    private struct Response: Decodable {
        let data: Payload

        struct Payload: Decodable {
            let horoscope: String
        }
    }

    // sign: id del signo ("aries"). period: "daily", "weekly" o "monthly"
    func fetchPrediction(sign: String, period: String) async throws -> String {
        guard let url = URL(string: "https://freehoroscopeapi.com/api/v1/get-horoscope/\(period)?sign=\(sign)") else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        // Una respuesta 404 o 500 también "llega", pero no es válida
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.badResponse
        }

        return try JSONDecoder().decode(Response.self, from: data).data.horoscope
    }
}
