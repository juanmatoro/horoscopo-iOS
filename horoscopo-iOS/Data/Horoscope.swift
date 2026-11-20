//
//  Horoscope.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 18/11/2026.
//

import UIKit

struct Horoscope {
    let id: String
    let name: String
    let dates: String

    // Propiedad autocalculada: el icono se busca en Assets como "<id>-icon"
    var icon: UIImage? {
        return UIImage(named: "\(id)-icon")
    }

    static let horoscopeList: [Horoscope] = [
        Horoscope(id: "aries", name: "Aries", dates: "21 de marzo - 19 de abril"),
        Horoscope(id: "taurus", name: "Tauro", dates: "20 de abril - 20 de mayo"),
        Horoscope(id: "gemini", name: "Géminis", dates: "21 de mayo - 20 de junio"),
        Horoscope(id: "cancer", name: "Cáncer", dates: "21 de junio - 22 de julio"),
        Horoscope(id: "leo", name: "Leo", dates: "23 de julio - 22 de agosto"),
        Horoscope(id: "virgo", name: "Virgo", dates: "23 de agosto - 22 de septiembre"),
        Horoscope(id: "libra", name: "Libra", dates: "23 de septiembre - 22 de octubre"),
        Horoscope(id: "scorpio", name: "Escorpio", dates: "23 de octubre - 21 de noviembre"),
        Horoscope(id: "sagittarius", name: "Sagitario", dates: "22 de noviembre - 21 de diciembre"),
        Horoscope(id: "capricorn", name: "Capricornio", dates: "22 de diciembre - 19 de enero"),
        Horoscope(id: "aquarius", name: "Acuario", dates: "20 de enero - 18 de febrero"),
        Horoscope(id: "pisces", name: "Piscis", dates: "19 de febrero - 20 de marzo")
    ]
}
