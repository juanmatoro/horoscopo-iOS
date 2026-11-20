//
//  DetailViewController.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import UIKit

class DetailViewController: UIViewController {

    // Periodo de la predicción; el orden coincide con los segmentos del selector
    enum Period: Int {
        case day, week, month
    }

    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var periodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var predictionLabel: UILabel!

    // Se asigna desde ListViewController en prepare(for:sender:)
    var horoscope: Horoscope?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let horoscope else { return }
        title = horoscope.name
        signImageView.image = horoscope.icon
        signImageView.tintColor = horoscope.color
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        loadPrediction(for: .day)
    }

    @IBAction func periodChanged(_ sender: UISegmentedControl) {
        guard let period = Period(rawValue: sender.selectedSegmentIndex) else { return }
        loadPrediction(for: period)
    }

    // TODO: conectar con la API para pedir la predicción del signo y el periodo
    private func loadPrediction(for period: Period) {
        predictionLabel.text = "Aquí aparecerá la predicción."
    }
}
