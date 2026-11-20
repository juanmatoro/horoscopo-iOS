//
//  Horoscope.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 18/11/2026.
//

import UIKit

struct Horoscope {
    let id: String

    // Nombre y fechas se leen del catálogo Localizable.xcstrings con las claves
    // "<id>.name" y "<id>.dates", así que cambian solos con el idioma de la app
    var name: String {
        return Bundle.main.localizedString(forKey: "\(id).name", value: nil, table: nil)
    }

    var dates: String {
        return Bundle.main.localizedString(forKey: "\(id).dates", value: nil, table: nil)
    }

    // Propiedad autocalculada: el icono se busca en Assets como "<id>-icon"
    var icon: UIImage? {
        return UIImage(named: "\(id)-icon")
    }

    // Color propio del signo. El asset "<id>-color" define una variante para
    // modo claro y otra para oscuro, y el sistema elige la correcta solo.
    var color: UIColor {
        return UIColor(named: "\(id)-color") ?? .label
    }

    static let horoscopeList: [Horoscope] = [
        Horoscope(id: "aries"),
        Horoscope(id: "taurus"),
        Horoscope(id: "gemini"),
        Horoscope(id: "cancer"),
        Horoscope(id: "leo"),
        Horoscope(id: "virgo"),
        Horoscope(id: "libra"),
        Horoscope(id: "scorpio"),
        Horoscope(id: "sagittarius"),
        Horoscope(id: "capricorn"),
        Horoscope(id: "aquarius"),
        Horoscope(id: "pisces")
    ]
}
