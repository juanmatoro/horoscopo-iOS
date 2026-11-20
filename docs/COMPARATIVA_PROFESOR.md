# Comparativa con el proyecto de clase (Zodiac-iOS)

Este documento compara la lógica de negocio de nuestra app con la del
proyecto de referencia del profesor,
[IgniteCoders/Zodiac-iOS](https://github.com/IgniteCoders/Zodiac-iOS)
(commit `d65822a`, 27/05/2026), e indica por qué cada parte está resuelta como
está.

**Alcance:** solo funcionalidad (datos, búsqueda, navegación, favoritos, red).
No se compara diseño, colores ni estética.

**Cómo leerlo.** Hay dos tipos de diferencias:

- **Decisión:** las dos apps tienen la funcionalidad y la resolvemos distinto.
  Se explica el motivo.
- **Pendiente:** el profesor la tiene y nuestra app **todavía no**. No es una
  decisión de diseño, es trabajo por hacer. Está marcado como tal.

---

## 1. Resumen

| Funcionalidad | Profesor | Nuestra app | Tipo |
|---|---|---|---|
| Modelo y lista de signos | `Horoscope` + `getAll()` | `Horoscope` + `horoscopeList` | Decisión |
| Carga del icono | `getImage()` con `!` | `icon` opcional | Decisión |
| Lista en tabla | `dataSource` | `dataSource` + `delegate` | Decisión |
| Búsqueda | `UISearchBarDelegate`, nombre y fechas | `UISearchResultsUpdating` + variable `search`, solo nombre | Decisión y pendiente |
| Pasar el signo al detalle | `prepare` con `indexPathForSelectedRow` | `prepare` con la celda (`sender`) | Decisión |
| Quitar la selección de la celda | En `prepare` | En `didSelectRowAt` | Decisión |
| Signo opcional en el detalle | `horoscope!` | `horoscope?` + `guard let` | Decisión |
| Título de la pantalla de detalle | `navigationItem.title` | `title` | Decisión |
| Selector día/semana/mes | Sí, con `switch` | Sí, con `enum Period` | Decisión |
| Predicción desde la API | Sí (`HoroscopeApi`) | Sí (`HoroscopeService`, con `Codable`) | Decisión |
| Indicador de carga | Sí | Sí | Decisión |
| Favorito (persistente) | Sí (`SessionManager`) | Sí (`SessionManager`) | Decisión |
| Compartir la predicción | Sí (`UIActivityViewController`) | Sí | Decisión |
| Refrescar la lista al volver | `reloadData` en `viewWillAppear` | Sí | Igual |

---

## 2. Modelo y lista de signos

**Profesor** (`Data/Horoscope.swift`): struct con `id`, `name`, `dates`. La
lista es `static private let list` y se lee con `static func getAll()`.

**Nuestra app** (`Data/Horoscope.swift`): el mismo struct, con la lista como
`static let horoscopeList`, pública.

**Por qué lo hacemos así**
- La lista es un dato fijo, así que una constante estática es lo más directo.
- La diferencia con el profesor es de encapsulación: él esconde la lista y
  obliga a pasar por `getAll()`. Nosotros la exponemos directamente.
  Cualquiera de las dos vale; la del profesor protege mejor la lista de que
  alguien la use mal, y si algún día los datos vinieran de otro sitio, solo
  habría que cambiar `getAll()`.
- El `id` en inglés (`aries`, `taurus`...) cumple la misma función en ambos:
  nombra el icono y servirá de parámetro `sign` para la API.
- Nombres y fechas están en español en nuestra app y en inglés en la del
  profesor. Esto afecta a la búsqueda: se busca sobre el texto de cada app.

## 3. Carga del icono

**Profesor:** `func getImage() -> UIImage` con
`UIImage(named: "horoscope-icons/\(id)-icon")!`. Usa la ruta con carpeta
(la carpeta de Assets tiene *Provides Namespace* activado) y fuerza el
desempaquetado con `!`.

**Nuestra app:** `var icon: UIImage?` con `UIImage(named: "\(id)-icon")`. La
carpeta **no** tiene namespace, así que el nombre va sin prefijo.

**Por qué lo hacemos así**
- `UIImage(named:)` devuelve `nil` si el nombre no existe. Con `!`, un icono
  mal nombrado hace **crashear la app**; con el opcional, el icono simplemente
  no se pinta.
- Es una propiedad calculada (`var`) y no una función: no recibe parámetros,
  se deduce del `id`.
- Las dos formas de nombrar (con o sin namespace) funcionan; lo importante es
  que el código y los Assets coincidan.

## 4. Lista en tabla

**Profesor** (`MainViewController`): implementa `UITableViewDataSource` y
asigna `tableView.dataSource = self`. Dentro de `cellForRowAt` usa
`as! HoroscopeViewCell`.

**Nuestra app** (`ListViewController`): implementa `UITableViewDataSource` y
`UITableViewDelegate`. En `cellForRowAt` convierte con `as?` dentro de un
`guard` y, si falla, devuelve `UITableViewCell()`.

**Por qué lo hacemos así**
- `as?` evita el crash si el identificador de celda o la clase del storyboard
  estuvieran mal. El coste es que el fallo pasa a ser una fila vacía, más
  difícil de detectar que un crash; el `as!` del profesor avisa antes en
  desarrollo.
- Asignamos también el `delegate` porque usamos `didSelectRowAt`
  (ver apartado 7). El profesor no lo necesita.
- La celda tiene el mismo método `render(horoscope:)` en ambas apps: la celda
  recibe el modelo y se pinta ella misma.

## 5. Búsqueda

**Profesor:**
- Crea un `UISearchController` y se pone él mismo como delegado de la
  `searchBar` (`UISearchBarDelegate`).
- En `textDidChange` filtra `Horoscope.getAll()` por **nombre o fechas**,
  pasando a minúsculas con `lowercased()`.
- Si el texto está vacío, restaura la lista completa.
- Gestiona también el botón *Cancelar* (`searchBarCancelButtonClicked`).

**Nuestra app:**
- Tiene `allHoroscopes` (lista completa) y `horoscopeList` (la filtrada que
  pinta la tabla).
- Una variable `search` con `didSet`: al cambiar su valor se filtra y se llama
  a `reloadData()`.
- El `UISearchController` se crea dentro de `ListViewController` y se conecta
  con `UISearchResultsUpdating`; `updateSearchResults(for:)` solo copia el
  texto a `search`.
- Filtra solo por **nombre**, con `localizedStandardContains`, que ignora
  mayúsculas y tildes.

**Por qué lo hacemos así**
- Mover la lógica a la variable `search` separa dos cosas: *quién cambia el
  texto* (el controlador de búsqueda) y *qué pasa al cambiarlo* (filtrar y
  repintar). Se podría cambiar `search` desde otro sitio y la tabla se
  actualizaría igual.
- `UISearchResultsUpdating` es el mecanismo pensado para `UISearchController`.
  No hace falta un método aparte para *Cancelar*: al cancelar, el sistema
  llama a `updateSearchResults` con el texto vacío y la lista se restaura sola.
- `localizedStandardContains` evita la comparación manual con `lowercased()` y,
  además, ignora tildes (`geminis` encuentra `Géminis`), cosa que
  `lowercased().contains` no hace. Importa porque nuestros nombres están en
  español.
- **Pendiente:** el profesor también busca por fechas y nosotros no. Si se
  quiere igualar, basta añadir la condición sobre `dates` en
  `filterHoroscopes()`.

## 6. Pasar el signo pulsado al detalle

**Profesor:** en `prepare(for:sender:)` comprueba
`segue.identifier == "Show Detail"`, obtiene la fila con
`tableView.indexPathForSelectedRow!` y le asigna el signo al detalle.

**Nuestra app:** en `prepare(for:sender:)` recibe la celda por `sender` (el
segue sale de la celda), obtiene su fila con `tableView.indexPath(for:)` y le
asigna el signo al detalle.

**Por qué lo hacemos así**
- `sender` es la celda que originó el segue, así que no dependemos del estado
  de selección de la tabla.
- Con `indexPathForSelectedRow!`, el profesor depende de que la celda siga
  seleccionada en ese momento. En nuestro caso esa dependencia no existe,
  porque quitamos la selección antes (apartado 7).
- Nosotros no comprobamos `segue.identifier`: hoy solo hay un segue en la
  pantalla. Si se añadiera otro, habría que comprobarlo para no confundirlos.
- Los dos usan `horoscopeList[indexPath.row]` (la lista filtrada), de modo que
  el signo que llega al detalle es el que se ve en pantalla aunque haya una
  búsqueda activa.

## 7. Quitar la selección de la celda

**Profesor:** llama a `tableView.deselectRow(at:animated:)` al final de
`prepare`.

**Nuestra app:** lo hace en `didSelectRowAt`.

**Por qué lo hacemos así**
- Quitar la selección es una reacción a "se ha pulsado una fila", y para eso
  existe `didSelectRowAt`. Dejarlo en `prepare` mezcla esa responsabilidad con
  la de pasar datos.
- En los dos casos la celda no se queda marcada al volver del detalle.
  No lo hemos comparado en ejecución, solo leyendo el código.

## 8. Pantalla de detalle: opcional, título y selector

**Signo recibido**
- Profesor: `var horoscope: Horoscope!`. Si llega `nil`, `viewDidLoad`
  crashea.
- Nosotros: `var horoscope: Horoscope?` con `guard let horoscope else { return }`.
  Si llega `nil`, la pantalla queda sin pintar pero no se cae.
- Motivo: se decidió en clase (ver conversación) que el opcional obliga a
  tratar el caso de que el valor falte. `!` queda para los `@IBOutlet`, que
  rellena el storyboard.

**Título**
- Profesor: `navigationItem.title = horoscope.name`.
- Nosotros: `title = horoscope.name`.
- Las dos ponen el nombre del signo en la barra. `navigationItem.title` afecta
  solo a la barra; `title` también alimenta el texto del botón *atrás* de
  pantallas posteriores. En esta app el resultado visible es el mismo.

**Selector día / semana / mes**
- Profesor: `periodChanged` con un `switch` sobre el índice que devuelve los
  textos `"daily"`, `"weekly"` y `"monthly"`, que son los que espera la API.
- Nosotros: `enum Period: Int` con `day`, `week`, `month`, cuyo valor
  coincide con el índice del segmento, y `Period(rawValue:)` para convertirlo.
- Motivo: el `enum` convierte los números 0/1/2 en un tipo con nombre, y el
  compilador avisa si falta un caso. Con el `switch` del profesor, cualquier
  índice que no sea 0 ni 1 se trata como mensual (`default`).
- Diferencia a tener en cuenta cuando conectemos la API: la API espera
  `daily/weekly/monthly`, y nuestro `enum` usa `day/week/month`. Habrá que
  traducir entre los dos (en el tutorial hay una función `apiValue(for:)` para
  ello).

---

## 9. API, carga, favorito, compartir y refresco

Estas funcionalidades empezaron como pendientes y ya están en nuestra app.
Se comprobaron en el simulador, salvo lo que se indica.

### 9.1 Predicción desde la API (`Data/HoroscopeService.swift`)

- **Profesor:** `HoroscopeApi.getPrediction`, una función estática que hace
  `GET https://freehoroscopeapi.com/api/v1/get-horoscope/<periodo>?sign=<id>`.
  Lee el JSON con `JSONSerialization` y `as!`/`!`; si algo falla, devuelve un
  texto de error.
- **Nuestra app:** `HoroscopeService.fetchPrediction(sign:period:)` llama al
  mismo endpoint, pero decodifica con `Codable` (`Response.data.horoscope`),
  comprueba que el código HTTP sea 2xx y **lanza** el error en vez de
  devolverlo como texto. Quien lo llama decide qué mostrar.
- **Por qué:** con `Codable` y `throws`, una respuesta con otro formato no
  crashea la app, y la pantalla puede distinguir un error de una predicción
  real. Es el diseño que ya proponía el tutorial.
- **Periodo:** `DetailViewController.Period` tiene `apiValue`, que traduce
  `day/week/month` a `daily/weekly/monthly`, que es lo que espera la API.
- Se comprobó que el endpoint responde `200` con `{"data": {"horoscope": ...}}`
  y que la app muestra el texto devuelto para día, semana y mes.

### 9.2 Indicador de carga

- Mientras llega la respuesta se muestra "Consultando con las estrellas..." y
  un `UIActivityIndicatorView` (`startAnimating`/`stopAnimating`, con
  *Hides When Stopped*). El profesor lo hace con `isHidden`.
- Si el usuario cambia de periodo antes de que llegue la respuesta, la
  petición anterior se **cancela** (`loadTask?.cancel()`), para que no pise a
  la nueva. El profesor no lo hace.
- Si falla, se muestra "No se pudo cargar la predicción.".
- **Sin comprobar:** en la prueba la respuesta llegó antes de poder capturar
  la pantalla, así que no se llegó a ver el indicador en pantalla.

### 9.3 Favorito persistente (`Utils/SessionManager.swift`)

- Igual que el profesor: un solo favorito, guardado en `UserDefaults`.
  Marcar otro signo sustituye al anterior (se comprobó en el simulador).
- Diferencia: nosotros usamos un `struct` con `favoriteHoroscopeId: String?` y
  quitamos el favorito con `removeObject` (`setFavoriteHoroscope(id: nil)`). El
  profesor usa una `class` y guarda una cadena vacía para "ninguno".
- Botón de corazón en la barra del detalle (`heart` / `heart.fill`) y un
  corazón en la celda cuando es el favorito.

### 9.4 Compartir la predicción

- Botón de compartir en la barra del detalle que abre un
  `UIActivityViewController`. Solo comparte si hay una predicción cargada
  (`prediction` es `nil` mientras carga o si falla).
- Diferencia: en iPad anclamos el panel al botón con
  `popoverPresentationController?.barButtonItem`; el profesor lo ancla a la
  vista. Se comprobó en el simulador de iPhone que el panel se abre.

### 9.5 Refrescar la lista al volver

- Igual que el profesor: `tableView.reloadData()` en `viewWillAppear`, para que
  el corazón de la celda refleje el favorito cambiado en el detalle.

---

## 10. Lo que sigue sin igualar

- **Búsqueda por fechas:** el profesor busca por nombre y fechas; nosotros solo
  por nombre. Basta añadir la condición sobre `dates` en `filterHoroscopes()`.
