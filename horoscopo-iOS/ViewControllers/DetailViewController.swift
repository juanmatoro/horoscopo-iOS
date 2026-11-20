//
//  DetailViewController.swift
//  horoscopo-iOS
//
//  Created by Juanma on 20/11/2026.
//

import UIKit

class DetailViewController: UIViewController {

    // Periodo de la predicción; el orden coincide con los segmentos del selector
    enum Period: Int {
        case day, week, month

        // Texto que espera la API para cada periodo
        var apiValue: String {
            switch self {
            case .day: return "daily"
            case .week: return "weekly"
            case .month: return "monthly"
            }
        }
    }

    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var periodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteBarButton: UIBarButtonItem!

    // Se asigna desde ListViewController en prepare(for:sender:)
    var horoscope: Horoscope?

    private let service = HoroscopeService()
    private let session = SessionManager()

    private var isFavorite = false
    // Última predicción cargada; es nil mientras carga o si falla
    private var prediction: String?
    // Petición en curso, para cancelarla si el usuario cambia de periodo
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let horoscope else { return }
        title = horoscope.name
        signImageView.image = horoscope.icon
        signImageView.tintColor = horoscope.color
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        isFavorite = session.isFavoriteHoroscope(id: horoscope.id)
        updateFavoriteIcon()
        loadPrediction(for: .day)
    }

    @IBAction func periodChanged(_ sender: UISegmentedControl) {
        guard let period = Period(rawValue: sender.selectedSegmentIndex) else { return }
        loadPrediction(for: period)
    }

    @IBAction func favoriteButtonClicked(_ sender: UIBarButtonItem) {
        guard let horoscope else { return }
        isFavorite.toggle()
        session.setFavoriteHoroscope(id: isFavorite ? horoscope.id : nil)
        updateFavoriteIcon()
    }

    @IBAction func shareButtonClicked(_ sender: UIBarButtonItem) {
        // Solo se puede compartir si ya hay una predicción cargada
        guard let prediction else { return }
        let activityViewController = UIActivityViewController(activityItems: [prediction], applicationActivities: nil)
        // En iPad el panel necesita un punto de anclaje o la app crashea
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }

    private func updateFavoriteIcon() {
        favoriteBarButton.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
    }

    private func loadPrediction(for period: Period) {
        guard let horoscope else { return }

        // Si el usuario cambia de periodo antes de que llegue la respuesta,
        // descartamos la anterior para que no pise a la nueva
        loadTask?.cancel()
        prediction = nil
        predictionLabel.text = "Consultando con las estrellas..."
        loadingIndicator.startAnimating()

        loadTask = Task {
            do {
                let text = try await service.fetchPrediction(sign: horoscope.id, period: period.apiValue)
                prediction = text
                predictionLabel.text = text
            } catch {
                // Una petición cancelada la sustituye otra que ya se encarga del indicador
                if Task.isCancelled { return }
                predictionLabel.text = "No se pudo cargar la predicción."
            }
            loadingIndicator.stopAnimating()
        }
    }
}
