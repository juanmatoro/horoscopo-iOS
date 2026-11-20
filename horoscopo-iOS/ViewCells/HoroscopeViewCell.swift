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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func render(horoscope: Horoscope) {
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        signImageView.image = horoscope.icon
        signImageView.tintColor = horoscope.color
        favoriteImageView.isHidden = !SessionManager().isFavoriteHoroscope(id: horoscope.id)
    }

}
