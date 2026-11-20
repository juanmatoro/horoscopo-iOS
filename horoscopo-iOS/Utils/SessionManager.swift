//
//  SessionManager.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import Foundation

// Guarda en UserDefaults el signo favorito del usuario (solo hay uno)
struct SessionManager {

    private static let favoriteKey = "FAVORITE_HOROSCOPE"

    private let userDefaults = UserDefaults.standard

    // id del signo favorito, o nil si no hay ninguno
    var favoriteHoroscopeId: String? {
        return userDefaults.string(forKey: SessionManager.favoriteKey)
    }

    // Pasar nil quita el favorito
    func setFavoriteHoroscope(id: String?) {
        if let id {
            userDefaults.set(id, forKey: SessionManager.favoriteKey)
        } else {
            userDefaults.removeObject(forKey: SessionManager.favoriteKey)
        }
    }

    func isFavoriteHoroscope(id: String) -> Bool {
        return favoriteHoroscopeId == id
    }
}
