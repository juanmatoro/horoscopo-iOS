//
//  PaddedLabel.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import UIKit

// UILabel con margen interior, para poder darle fondo y bordes redondeados como una tarjeta
class PaddedLabel: UILabel {

    var textInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        // Calculamos el texto en el área sin márgenes y devolvemos el rectángulo ampliado
        let textRect = super.textRect(forBounds: bounds.inset(by: textInsets), limitedToNumberOfLines: numberOfLines)
        let inverted = UIEdgeInsets(top: -textInsets.top, left: -textInsets.left,
                                    bottom: -textInsets.bottom, right: -textInsets.right)
        return textRect.inset(by: inverted)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
