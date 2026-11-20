# Tutorial: una app iOS con lista y detalle (UIKit + Storyboard)

Este documento explica, paso a paso, cómo se ha construido la app **Horóscopo**
y sirve de guía para crear cualquier app que:

1. pinte una **lista** de elementos,
2. abra una **pantalla de detalle** al pulsar uno,
3. y (en la parte final) obtenga los datos de una **API externa**.

> **Estado del proyecto.** Todos los pasos están implementados en este repositorio.
> El paso 9 es una guía genérica con una API ficticia; la implementación real
> (`Data/HoroscopeService.swift`, favoritos y compartir) está descrita en
> [la comparativa con el proyecto del profesor](COMPARATIVA_PROFESOR.md).

Tecnologías: Swift, UIKit, Storyboard, Xcode.

Continuación: [Modo claro y oscuro con iconos tintados](MODO_CLARO_OSCURO.md).

También: [Internacionalización y traducción de la predicción](INTERNACIONALIZACION.md).

---

## Índice

1. [Qué vamos a construir](#1-qué-vamos-a-construir)
2. [Crear el proyecto](#2-crear-el-proyecto)
3. [El modelo de datos](#3-el-modelo-de-datos)
4. [Los iconos en Assets](#4-los-iconos-en-assets)
5. [La pantalla de lista](#5-la-pantalla-de-lista)
6. [La celda personalizada](#6-la-celda-personalizada)
7. [Auto Layout en la celda](#7-auto-layout-en-la-celda)
8. [La pantalla de detalle y la navegación](#8-la-pantalla-de-detalle-y-la-navegación)
9. [Conectar con una API externa](#9-conectar-con-una-api-externa)
10. [Errores típicos](#10-errores-típicos)
11. [Resumen del flujo completo](#11-resumen-del-flujo-completo)

---

## 1. Qué vamos a construir

Dos pantallas dentro de un `UINavigationController`:

```
┌──────────────────────┐        ┌──────────────────────┐
│ The Zoltan horoscope │        │ < Aries              │
├──────────────────────┤        ├──────────────────────┤
│ [♈] Aries            │  tap   │        [♈]           │
│     21 mar - 19 abr  │ ─────► │       Aries          │
│ [♉] Tauro            │        │  21 mar - 19 abr     │
│     20 abr - 20 may  │        │ [Día|Semana|Mes]    │
│ ...                  │        │  Predicción...       │
└──────────────────────┘        └──────────────────────┘
        Lista                            Detalle
```

Piezas y qué hace cada una:

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| Modelo | `Data/Horoscope.swift` | Qué datos tiene un signo y la lista de los 12 |
| Pantalla lista | `ViewControllers/ListViewController.swift` | Pinta la tabla y gestiona la pulsación |
| Celda | `ViewCells/HoroscopeViewCell.swift` | Pinta una fila (icono, nombre, fechas) |
| Pantalla detalle | `ViewControllers/DetailViewController.swift` | Pinta un signo y su predicción |
| Interfaz | `Base.lproj/Main.storyboard` | Diseño visual y navegación |

La idea de fondo es una regla que se repite en todas las apps de este tipo:
**el modelo guarda los datos, el storyboard los dibuja y el controlador los une.**

---

## 2. Crear el proyecto

1. Xcode → *File → New → Project → iOS → App*.
2. *Interface*: **Storyboard**. *Language*: **Swift**.
3. Organiza el código en carpetas (grupos) para no mezclar responsabilidades:
   `Data`, `ViewControllers`, `ViewCells`.

El proyecto trae un `ViewController` y un `Main.storyboard` con una pantalla
vacía. Renombraremos y ampliaremos esas piezas.

---

## 3. El modelo de datos

Un **modelo** es una estructura que describe un dato de tu app, sin nada de
interfaz. Aquí, un signo del horóscopo:

```swift
import UIKit

struct Horoscope {
    let id: String
    let name: String
    let dates: String

    // Propiedad autocalculada: el icono se busca en Assets como "<id>-icon"
    var icon: UIImage? {
        return UIImage(named: "\(id)-icon")
    }

    static let horoscopeList: [Horoscope] = [
        Horoscope(id: "aries", name: "Aries", dates: "21 de marzo - 19 de abril"),
        Horoscope(id: "taurus", name: "Tauro", dates: "20 de abril - 20 de mayo"),
        // ... hasta los 12 signos
    ]
}
```

> **Nota:** este es el modelo tal y como se creó al principio. Después se
> internacionalizó: hoy `Horoscope` guarda solo el `id` y calcula `name` y `dates`
> desde el catálogo de cadenas. Ver [Internacionalización](INTERNACIONALIZACION.md).

Conceptos:

- **`struct`**: tipo por valor, ideal para datos.
- **`id`**: identificador estable. Lo usamos para el nombre del icono y, más
  adelante, para pedir datos a la API (`aries`, `taurus`...).
- **Propiedad calculada (`icon`)**: no se guarda, se calcula cada vez que se
  lee. Así no duplicamos información: el icono se deduce del `id`.
- **`static let horoscopeList`**: la lista de datos fijos, accesible sin crear
  ninguna instancia (`Horoscope.horoscopeList`).
- **`UIImage?` es opcional** porque `UIImage(named:)` devuelve `nil` si el
  nombre no existe en Assets.

---

## 4. Los iconos en Assets

1. Abre `Assets.xcassets` y crea una carpeta `Horoscope-icons`.
2. Arrastra un SVG por signo. Cada uno crea un *image set*:
   `aries-icon`, `taurus-icon`, etc.
3. **La convención de nombres es la clave**: el modelo busca
   `"\(id)-icon"`, así que `id = "aries"` ⇒ imagen `aries-icon`.

Cómo comprobar que cargan bien:

- Cada `*.imageset` debe contener su `.svg` y un `Contents.json` que lo
  referencie por nombre de archivo.
- La carpeta `Horoscope-icons` **no** debe tener marcada la opción
  *Provides Namespace*. Si la tuviera, el nombre real sería
  `Horoscope-icons/aries-icon` y `UIImage(named: "aries-icon")` devolvería `nil`.

---

## 5. La pantalla de lista

### 5.1 En el storyboard

1. Arrastra un **Table View** a la pantalla y ajústalo a los cuatro bordes con
   constraints.
2. Selecciona el controlador y, en el *Identity Inspector*, ponle la clase
   `ListViewController`.
3. Selecciona el controlador y envuélvelo en un navegador:
   *Editor → Embed In → Navigation Controller*. Eso crea la barra superior y
   permite el título y la navegación hacia el detalle.
4. En el *Attributes Inspector* de la barra, activa *Prefers Large Titles* y
   pon el título de la pantalla.

### 5.2 En el código

```swift
class ListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    let horoscopeList = Horoscope.horoscopeList

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
}
```

- **`@IBOutlet`**: una "tubería" entre un elemento del storyboard y una
  variable de Swift. Se crea arrastrando con *Control* desde la tabla al
  código. Sin esa conexión, `tableView` sería `nil`.
- **`weak`**: la vista ya pertenece a la jerarquía de vistas; el controlador no
  necesita ser su dueño.
- **`!`**: UIKit rellena el outlet antes de `viewDidLoad`. Si no está
  conectado, es un error de programación y queremos enterarnos enseguida.

### 5.3 DataSource y Delegate

La tabla **no sabe qué mostrar**: se lo preguntas a su `dataSource`.

```swift
extension ListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return horoscopeList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HoroscopeCell",
                                                       for: indexPath) as? HoroscopeViewCell else {
            return UITableViewCell()
        }
        cell.render(horoscope: horoscopeList[indexPath.row])
        return cell
    }
}
```

- `numberOfRowsInSection`: cuántas filas hay.
- `cellForRowAt`: "dame la celda de la fila N". La tabla **reutiliza**
  celdas (`dequeueReusableCell`): solo existen las que caben en pantalla y,
  al hacer scroll, se rellenan de nuevo con otros datos. Por eso la celda
  expone un método `render` que lo sobrescribe todo.
- **`as? HoroscopeViewCell` (casteo)**: `dequeueReusableCell` devuelve un
  `UITableViewCell` genérico. Para acceder a los labels y la imagen propios
  hay que convertirlo a nuestra subclase. Si falla, devolvemos una celda vacía
  en vez de crashear.
- **`"HoroscopeCell"`** es el *reuse identifier*: debe ser **exactamente** el
  mismo que pongas en el storyboard (paso 6).

`UITableViewDelegate` se usa para reaccionar a eventos de la tabla (pulsar una
fila, alturas, etc.). Lo tenemos asignado para poder ampliarlo.

---

## 6. La celda personalizada

### 6.1 En el storyboard

1. Dentro de la tabla, selecciona la *Prototype Cell*.
2. *Identity Inspector* → clase `HoroscopeViewCell`.
3. *Attributes Inspector* → *Identifier* = `HoroscopeCell`.
4. Añade dentro de la celda un `UIImageView` y dos `UILabel` (nombre y fechas).

### 6.2 En el código

```swift
class HoroscopeViewCell: UITableViewCell {

    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    func render(horoscope: Horoscope) {
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        signImageView.image = horoscope.icon
    }
}
```

Los tres outlets se conectan con *Control + arrastrar* desde cada elemento de
la celda del storyboard hasta la clase. `render` recibe el modelo y pinta cada
componente: **la celda no sabe de dónde vienen los datos, solo cómo
dibujarlos**. Eso hace fácil cambiar la fuente (lista fija → API) sin tocarla.

---

## 7. Auto Layout en la celda

Si dejas las vistas con posiciones fijas (*fixed frame*), en otros tamaños de
pantalla o con texto largo se cortarán. Con constraints:

- **Icono**: 16 pt al borde izquierdo, centrado en vertical, tamaño 59×58.
- **Nombre**: 8 pt a la derecha del icono, 16 pt al borde derecho y 16 pt arriba.
- **Fechas**: alineadas con el nombre, 8 pt debajo de él y 16 pt hasta abajo.
- En el label de fechas, **Lines = 0** para que pueda ocupar varias líneas.

Como la tabla usa altura de fila automática, cada fila crece lo que necesite su
contenido.

---

## 8. La pantalla de detalle y la navegación

### 8.1 Diseño en el storyboard

1. Arrastra un *View Controller* nuevo y asígnale la clase `DetailViewController`.
2. Añade: un `UIImageView` (100×100, centrado), un `UILabel` para el nombre, otro
   para las fechas, un `UISegmentedControl` con *Día / Semana / Mes* y un
   `UILabel` multilínea para la predicción.
3. Apílalos con constraints (cada elemento pegado al anterior).

### 8.2 El segue (la flecha de navegación)

*Control + arrastrar* **desde la celda prototipo** hasta el controlador de
detalle → *Show*. Eso crea un *segue*: una instrucción del storyboard que dice
"al pulsar esta celda, abre esta pantalla dentro del navegador".

### 8.3 Pasar el dato de una pantalla a otra

El segue abre la pantalla pero no sabe qué signo se ha pulsado. Justo antes de
navegar, UIKit llama a `prepare(for:sender:)` en la pantalla de origen:

```swift
extension ListViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let detailViewController = segue.destination as? DetailViewController else { return }
        detailViewController.horoscope = horoscopeList[indexPath.row]
    }
}
```

- `sender` es la celda pulsada (porque el segue sale de la celda).
- `tableView.indexPath(for:)` nos dice **qué fila** es.
- `segue.destination` es el detalle ya creado, pero aún no mostrado: le
  asignamos el signo.

### 8.4 El controlador de detalle

```swift
class DetailViewController: UIViewController {

    enum Period: Int { case day, week, month }

    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var periodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var predictionLabel: UILabel!

    var horoscope: Horoscope?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let horoscope else { return }
        title = horoscope.name
        signImageView.image = horoscope.icon
        nameLabel.text = horoscope.name
        dateLabel.text = horoscope.dates
        loadPrediction(for: .day)
    }

    @IBAction func periodChanged(_ sender: UISegmentedControl) {
        guard let period = Period(rawValue: sender.selectedSegmentIndex) else { return }
        loadPrediction(for: period)
    }

    private func loadPrediction(for period: Period) {
        predictionLabel.text = "Aquí aparecerá la predicción."
    }
}
```

**Por qué `horoscope` es opcional (`?`) y no `!`:** entre que se crea la
pantalla y se ejecuta `prepare`, la propiedad está vacía, y si algún día se abre
el detalle sin pasarle un signo, `?` + `guard let` lo trata sin romper. Con `!`
la app se caería. Los outlets sí usan `!` porque los rellena el storyboard, no
el flujo de navegación.

**`@IBAction`** es lo contrario de un outlet: en vez de "leer" un elemento,
**reacciona a un evento**. Se conecta arrastrando desde el segmented control
(evento *Value Changed*) hasta la función.

**`enum Period: Int`**: el valor numérico de cada caso (0, 1, 2) coincide con el
índice del segmento, así convertimos el selector en un tipo seguro.

### 8.5 Cómo llega el título a la barra de navegación

No hay ninguna conexión explícita. `title` es una propiedad que ya trae todo
`UIViewController`, y cuando la pantalla está dentro de un
`UINavigationController`, la barra muestra el `title` del controlador visible.
En el storyboard ponía "Detail" por defecto; al asignar
`title = horoscope.name` en `viewDidLoad` se sustituye por el nombre del signo.

---

## 9. Conectar con una API externa

> Esta sección es una **guía genérica**: usa `https://api.ejemplo.com`, un dominio
> ficticio. El proyecto usa el mismo diseño con la API real; ver
> `Data/HoroscopeService.swift`.

La clave es no mezclar la red con las pantallas. Se hace en tres capas:

```
DetailViewController ──► HoroscopeService ──► URLSession ──► API
        (pinta)         (pide y decodifica)     (red)
```

### 9.1 Modelo de la respuesta (`Codable`)

Define un tipo que refleje el JSON de la API. Si el servidor devuelve:

```json
{ "sign": "aries", "period": "day", "text": "Hoy es un buen día para..." }
```

```swift
struct Prediction: Decodable {
    let sign: String
    let period: String
    let text: String
}
```

`Decodable` permite convertir JSON en este tipo automáticamente. Los nombres de
las propiedades deben coincidir con las claves del JSON (si no, se mapean con
`CodingKeys`).

### 9.2 El servicio de red con `async/await`

```swift
struct HoroscopeService {

    enum ServiceError: Error {
        case invalidURL
        case badResponse
    }

    func fetchPrediction(sign: String, period: String) async throws -> Prediction {
        guard let url = URL(string: "https://api.ejemplo.com/horoscope/\(sign)/\(period)") else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.badResponse
        }

        return try JSONDecoder().decode(Prediction.self, from: data)
    }
}
```

- **`async throws`**: la función espera a la red sin bloquear la app y puede
  fallar. Quien la llame usará `try await`.
- Comprobamos el **código HTTP**: una respuesta 404 o 500 también "llega", pero
  no es válida.

### 9.3 Usarlo desde el detalle

Sustituye el cuerpo de `loadPrediction(for:)`:

```swift
private let service = HoroscopeService()

private func loadPrediction(for period: Period) {
    guard let horoscope else { return }
    predictionLabel.text = "Cargando..."

    Task {
        do {
            let prediction = try await service.fetchPrediction(sign: horoscope.id,
                                                              period: apiValue(for: period))
            predictionLabel.text = prediction.text
        } catch {
            predictionLabel.text = "No se pudo cargar la predicción."
        }
    }
}

private func apiValue(for period: Period) -> String {
    switch period {
    case .day: return "day"
    case .week: return "week"
    case .month: return "month"
    }
}
```

- `Task { }` crea el contexto asíncrono desde una función normal.
- Como `UIViewController` está en el hilo principal, tocar `predictionLabel`
  después del `await` es seguro.
- **Siempre** hay que contemplar el estado de carga y el de error: la red falla.

### 9.4 Cuando la lista también viene de la API

Si la lista de signos viniera del servidor en vez de `Horoscope.horoscopeList`:

1. Haz `Horoscope` `Decodable`.
2. Cambia `let horoscopeList` por `var horoscopeList: [Horoscope] = []`.
3. Cárgala en `viewDidLoad` con `Task { ... }`.
4. Llama a `tableView.reloadData()` al recibirla para que la tabla se repinte.

### 9.5 Permisos de red

Las URLs `https` funcionan sin configurar nada. Para `http` (sin cifrar) iOS lo
bloquea por defecto (*App Transport Security*) y habría que añadir una
excepción en `Info.plist`. Mejor usar siempre `https`.

---

## 10. Errores típicos

| Síntoma | Causa probable |
|---|---|
| Crash `unexpectedly found nil` al abrir la pantalla | Un `@IBOutlet` sin conectar en el storyboard |
| La tabla sale vacía | Falta `tableView.dataSource = self` o el outlet de la tabla |
| Crash `unable to dequeue a cell with identifier` | El *Identifier* del storyboard no coincide con el del código |
| La celda sale en blanco | La clase de la celda no está asignada en el *Identity Inspector* |
| Los iconos no aparecen | El nombre del asset no sigue `"\(id)-icon"` o la carpeta tiene *Provides Namespace* |
| El título del detalle sigue siendo "Detail" | `horoscope` llega `nil`: revisa `prepare(for:sender:)` |
| El texto se corta en la celda | Vistas con *fixed frame* o *Lines* distinto de 0 |
| La API no devuelve nada y no hay error | Falta `try await`/`catch`, o el JSON no coincide con el `Decodable` |
| Aviso `Failed to send CA Event ... ExtendedLaunchMetrics` en consola | Es un log interno del sistema, no es un error de la app; se puede ignorar |

---

## 11. Resumen del flujo completo

1. La app arranca en el `UINavigationController` del storyboard, que muestra
   `ListViewController`.
2. En `viewDidLoad` se asigna `dataSource`/`delegate` a la tabla.
3. La tabla pide filas; `cellForRowAt` recicla una celda, la convierte a
   `HoroscopeViewCell` y llama a `render` con el signo de esa fila.
4. El usuario pulsa una celda y el *segue* abre `DetailViewController`.
5. Antes de mostrarse, `prepare(for:sender:)` le entrega el signo pulsado.
6. `viewDidLoad` del detalle pinta icono, nombre y fechas, y pone el nombre
   como título de la barra.
7. Al cambiar el selector Día/Semana/Mes se llama a `loadPrediction(for:)`, que
   (con la API conectada) pide la predicción y la pinta.

**Receta reutilizable para otra app:** cambia `Horoscope` por tu modelo, adapta
las celdas y los campos del detalle, y apunta el servicio a tu API. La
estructura (modelo → lista → celda → segue → detalle → servicio) es la misma.
