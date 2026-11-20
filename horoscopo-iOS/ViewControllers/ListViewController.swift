//
//  ViewController.swift
//  horoscopo-iOS
//
//  Created by Turno Mananas on 18/11/2026.
//

import UIKit

class ListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    let horoscopeList = Horoscope.horoscopeList

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
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
