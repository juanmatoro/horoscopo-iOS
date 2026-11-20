//
//  DetailViewController.swift
//  horoscopo-iOS
//
//  Created by Juanma on 20/11/2026.
//

import SwiftUI
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
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var favoriteBarButton: UIBarButtonItem!

    // Se asigna desde ListViewController en prepare(for:sender:)
    var horoscope: Horoscope?

    private let service = HoroscopeService()
    private let session = SessionManager()

    private var isFavorite = false
    // Última predicción cargada; es nil mientras carga o si falla
    private var prediction: String?
    // Traducción de la predicción actual; es nil hasta que el usuario la pide
    private var translatedPrediction: String?
    private var isShowingTranslation = false
    private let translator = PredictionTranslator()
    // Petición en curso, para cancelarla si el usuario cambia de periodo
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let horoscope else { return }
        applyStyle(for: horoscope)
        title = horoscope.name
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        setupTranslation()
        setupPeriodTitles()
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
        // Se comparte el texto que se está viendo (original o traducido)
        guard let shownText = isShowingTranslation ? translatedPrediction : prediction else { return }
        let activityViewController = UIActivityViewController(activityItems: [shownText], applicationActivities: nil)
        // En iPad el panel necesita un punto de anclaje o la app crashea
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }

    @IBAction func translateButtonClicked(_ sender: UIButton) {
        guard let prediction else { return }

        // Segundo toque: volvemos al texto original
        if isShowingTranslation {
            isShowingTranslation = false
            showPrediction(prediction)
            return
        }

        // Ya traducida antes: no hace falta pedirlo otra vez
        if let translatedPrediction {
            isShowingTranslation = true
            showPrediction(translatedPrediction)
            return
        }

        translateButton.isEnabled = false
        translator.translate(prediction) { [weak self] result in
            // Si el usuario cambió de periodo mientras tanto, esta respuesta ya no vale
            guard let self, self.prediction == prediction else { return }
            self.translateButton.isEnabled = true
            switch result {
            case .success(let text):
                self.translatedPrediction = text
                self.isShowingTranslation = true
                self.showPrediction(text)
            case .failure:
                self.showTranslationError()
            }
        }
    }

    // Los títulos del selector se localizan aquí; en el storyboard solo están como base
    private func setupPeriodTitles() {
        periodSegmentedControl.setTitle(String(localized: "Day"), forSegmentAt: Period.day.rawValue)
        periodSegmentedControl.setTitle(String(localized: "Week"), forSegmentAt: Period.week.rawValue)
        periodSegmentedControl.setTitle(String(localized: "Month"), forSegmentAt: Period.month.rawValue)
    }

    // Incrusta la vista SwiftUI invisible que ejecuta las traducciones
    private func setupTranslation() {
        let host = UIHostingController(rootView: TranslationHostView(translator: translator))
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.widthAnchor.constraint(equalToConstant: 1),
            host.view.heightAnchor.constraint(equalToConstant: 1),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        host.didMove(toParent: self)
    }

    // Pinta el texto en pantalla y ajusta el botón al estado actual
    private func showPrediction(_ text: String) {
        predictionLabel.text = text
        let title = isShowingTranslation ? String(localized: "Show original") : String(localized: "Translate")
        translateButton.setTitle(title, for: .normal)
    }

    private func showTranslationError() {
        let alert = UIAlertController(title: nil, message: String(localized: "The prediction could not be translated."), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
        present(alert, animated: true)
    }

    // Mismo lenguaje visual que la lista: colores del signo, esquinas redondeadas y tipografía escalable
    private func applyStyle(for horoscope: Horoscope) {
        view.backgroundColor = Style.screenColor

        Style.styleSignIcon(signImageView, horoscope: horoscope, padding: 18, cornerRadius: 28)

        nameLabel.font = Style.titleFont()
        nameLabel.adjustsFontForContentSizeCategory = true
        dateLabel.font = Style.captionFont()
        dateLabel.textColor = .secondaryLabel
        dateLabel.adjustsFontForContentSizeCategory = true

        // Selección con un tono suave del color del signo: el texto sigue siendo legible en claro y oscuro
        periodSegmentedControl.selectedSegmentTintColor = Style.iconBackground(for: horoscope.color)

        // La predicción se muestra en una tarjeta
        predictionLabel.font = Style.bodyFont()
        predictionLabel.adjustsFontForContentSizeCategory = true
        predictionLabel.backgroundColor = Style.cardColor
        predictionLabel.layer.cornerRadius = Style.cornerRadius
        predictionLabel.clipsToBounds = true

        translateButton.tintColor = horoscope.color
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
        translatedPrediction = nil
        isShowingTranslation = false
        translateButton.isHidden = true
        predictionLabel.text = String(localized: "Consulting the stars...")
        loadingIndicator.startAnimating()

        loadTask = Task {
            do {
                let text = try await service.fetchPrediction(sign: horoscope.id, period: period.apiValue)
                prediction = text
                showPrediction(text)
                // El botón solo aparece cuando hay texto y el idioma de la app no es el inglés
                translateButton.isHidden = !translator.canTranslate
            } catch {
                // Una petición cancelada la sustituye otra que ya se encarga del indicador
                if Task.isCancelled { return }
                predictionLabel.text = String(localized: "The prediction could not be loaded.")
            }
            loadingIndicator.stopAnimating()
        }
    }
}
