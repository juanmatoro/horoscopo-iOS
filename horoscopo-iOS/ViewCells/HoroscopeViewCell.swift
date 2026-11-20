//
//  HoroscopeViewCell.swift
//  horoscopo-iOS
//
//  Created by Juanma on 18/11/2026.
//

import UIKit

class HoroscopeViewCell: UITableViewCell {

    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // El fondo lo pinta la tarjeta (ver updateConfiguration), no la celda entera
        backgroundColor = .clear
        nameLabel.font = Style.titleFont()
        nameLabel.adjustsFontForContentSizeCategory = true
        dateLabel.font = Style.captionFont()
        dateLabel.textColor = .secondaryLabel
        dateLabel.adjustsFontForContentSizeCategory = true
    }

    // Dibuja la celda como una tarjeta con esquinas redondeadas y separación entre filas.
    // Partir de listGroupedCell().updated(for:) conserva el color al pulsar la fila
    override func updateConfiguration(using state: UICellConfigurationState) {
        var background = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
        background.cornerRadius = Style.cornerRadius
        background.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        backgroundConfiguration = background
    }
    
    func render(horoscope: Horoscope) {
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        Style.styleSignIcon(signImageView, horoscope: horoscope, padding: 10, cornerRadius: 14)
        favoriteImageView.isHidden = !SessionManager().isFavoriteHoroscope(id: horoscope.id)
    }

}
