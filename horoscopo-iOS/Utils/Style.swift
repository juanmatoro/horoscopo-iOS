//
//  Style.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import UIKit

// Valores de diseño compartidos por la lista y el detalle, para que las dos
// pantallas tengan el mismo aspecto y se cambien desde un solo sitio
enum Style {

    static let cornerRadius: CGFloat = 16

    // Fondo de pantalla y de las tarjetas: colores del sistema, que ya cambian con el modo oscuro
    static let screenColor = UIColor.systemGroupedBackground
    static let cardColor = UIColor.secondarySystemGroupedBackground

    // Fondo suave del icono con el color del signo. Si el color es dinámico, el
    // resultado también lo es y se adapta al modo claro y oscuro
    static func iconBackground(for color: UIColor) -> UIColor {
        return color.withAlphaComponent(0.15)
    }

    // Fuentes con estilo de texto: escalan con el tamaño de letra del usuario
    static func titleFont() -> UIFont {
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
    }

    static func bodyFont() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }

    static func captionFont() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    // Aplica el estilo de icono del signo: forma redondeada, color y fondo suave
    static func styleSignIcon(_ imageView: UIImageView, horoscope: Horoscope, padding: CGFloat, cornerRadius: CGFloat) {
        imageView.image = horoscope.icon?.padded(by: padding)
        imageView.tintColor = horoscope.color
        imageView.backgroundColor = iconBackground(for: horoscope.color)
        imageView.layer.cornerRadius = cornerRadius
        imageView.clipsToBounds = true
    }
}

extension UIImage {

    // Devuelve el icono dentro de un cuadrado con margen, para que no toque los bordes
    // del fondo redondeado. Conserva el modo plantilla para poder seguir tintándolo
    func padded(by padding: CGFloat) -> UIImage {
        let side = max(size.width, size.height) + padding * 2
        let canvas = CGSize(width: side, height: side)
        let rendered = UIGraphicsImageRenderer(size: canvas).image { _ in
            let origin = CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2)
            draw(in: CGRect(origin: origin, size: size))
        }
        return rendered.withRenderingMode(.alwaysTemplate)
    }
}
