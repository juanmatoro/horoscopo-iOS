//
//  ViewController.swift
//  horoscopo-iOS
//
//  Created by Juanma on 18/11/2026.
//

import UIKit

class ListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // Lista completa, sin filtrar
    private let allHoroscopes = Horoscope.horoscopeList

    // Lista que pinta la tabla: es allHoroscopes filtrada por `search`
    private(set) var horoscopeList = Horoscope.horoscopeList

    // Texto de búsqueda: al cambiar, se vuelve a filtrar y se repinta la tabla
    var search = "" {
        didSet {
            guard search != oldValue else { return }
            filterHoroscopes()
        }
    }

    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setupSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // El favorito puede haber cambiado en el detalle: repintamos las celdas
        tableView.reloadData()
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        // La lista es la propia pantalla, no hace falta atenuarla al buscar
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Buscar signo"
        navigationItem.searchController = searchController
        // Evita que la barra de búsqueda siga visible al navegar al detalle
        definesPresentationContext = true
    }

    private func filterHoroscopes() {
        let text = search.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            horoscopeList = allHoroscopes
        } else {
            // Ignora mayúsculas y tildes: "geminis" encuentra "Géminis"
            horoscopeList = allHoroscopes.filter { $0.name.localizedStandardContains(text) }
        }
        tableView.reloadData()
    }
}

extension ListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        search = searchController.searchBar.text ?? ""
    }
}

extension ListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return horoscopeList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Casteamos la celda a HoroscopeViewCell para acceder a sus outlets
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HoroscopeCell", for: indexPath) as? HoroscopeViewCell else {
            return UITableViewCell()
        }
        cell.render(horoscope: horoscopeList[indexPath.row])
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    
    //Desmarca la celda seleccionada al volver de detalle
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ListViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // El segue sale de la celda: recuperamos su fila para saber qué signo se ha pulsado
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let detailViewController = segue.destination as? DetailViewController else { return }
        detailViewController.horoscope = horoscopeList[indexPath.row]
    }
}
