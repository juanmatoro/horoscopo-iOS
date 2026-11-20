//
//  PredictionTranslator.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 20/11/2026.
//

import SwiftUI
import Translation

// El framework Translation solo ofrece su sesión a través de un modificador de
// SwiftUI (translationTask). Como la app es UIKit, este objeto hace de puente:
// DetailViewController le pide una traducción y una vista SwiftUI mínima,
// incrustada en el detalle, es la que ejecuta la sesión.
@Observable
@MainActor
final class PredictionTranslator {

    // Al cambiar (o invalidarse), la vista lanza una nueva traducción
    var configuration: TranslationSession.Configuration?
    private(set) var sourceText = ""
    private var completion: ((Result<String, Error>) -> Void)?

    // La API solo devuelve las predicciones en inglés
    private let sourceLanguage = Locale.Language(identifier: "en")

    // Idioma de la interfaz de la app, al que se traduce
    var targetLanguage: Locale.Language {
        return Locale.Language(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    }

    // No tiene sentido traducir de inglés a inglés
    var canTranslate: Bool {
        return targetLanguage.languageCode != sourceLanguage.languageCode
    }

    func translate(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        sourceText = text
        self.completion = completion

        if configuration == nil {
            configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
        } else {
            // Con la misma configuración, invalidarla fuerza una nueva ejecución
            configuration?.invalidate()
        }
    }

    fileprivate func finish(_ result: Result<String, Error>) {
        completion?(result)
        completion = nil
    }
}

// Vista invisible que aloja la sesión de traducción
struct TranslationHostView: View {

    let translator: PredictionTranslator

    var body: some View {
        Color.clear
            .translationTask(translator.configuration) { session in
                do {
                    let text = await translator.sourceText
                    let response = try await session.translate(text)
                    await translator.finish(.success(response.targetText))
                } catch {
                    await translator.finish(.failure(error))
                }
            }
    }
}
