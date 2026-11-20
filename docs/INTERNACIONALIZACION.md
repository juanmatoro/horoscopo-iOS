# Internacionalización (inglés base y español) y traducción de la predicción

Este documento explica, paso a paso, cómo la app muestra su interfaz en inglés o
español según el idioma del dispositivo, y cómo se traduce la predicción que
llega de la API, que solo existe en inglés.

**Inglés es el idioma base** del código y del catálogo de cadenas, porque la API
entrega las predicciones en inglés y así la interfaz y los datos coinciden por
defecto. El español se mantiene como traducción. Continúa el
[tutorial principal](TUTORIAL.md).

> **Estado.** La interfaz en inglés y español está implementada. El español se
> comprobó en el simulador después de pasar el inglés a idioma base; el inglés
> se comprobó antes del cambio, y después solo se compiló. La **traducción de la predicción** está
> implementada, pero **no se ha podido probar que traduzca de verdad**: el
> simulador no admite el framework Translation. Solo se comprobó que el botón
> aparece y que el fallo se trata bien. Ver el apartado 8.

---

## 1. Conceptos

- **Internacionalización (i18n):** preparar la app para que pueda mostrarse en
  varios idiomas, sin textos fijos repartidos por el código.
- **Localización (l10n):** aportar las traducciones concretas de cada idioma.
- **Cadena localizable:** un texto que se busca por una **clave** en una tabla
  del idioma activo. Si el idioma no existe, se usa el idioma base.
- **String Catalog (`Localizable.xcstrings`):** el archivo de Xcode donde viven
  todas las claves y sus traducciones, en una tabla con una columna por idioma.

Hay **dos problemas distintos** en esta app, y se resuelven de forma distinta:

| Texto | Quién lo escribe | Cómo se resuelve |
|---|---|---|
| Interfaz, nombres y fechas de los signos | Nosotros | Catálogo de cadenas |
| Predicción diaria/semanal/mensual | La API (solo en inglés) | Traducción en el dispositivo |

La API no ofrece otros idiomas, así que no se puede pedir la predicción ya
traducida.

---

## 2. Paso 1: declarar los idiomas del proyecto

El proyecto necesita saber qué idiomas soporta. En el archivo del proyecto
(`horoscopo-iOS.xcodeproj/project.xcproj`) la lista de localizaciones quedó así:

```
"localizations": {
  "development": "en",
  "supported": [ "Base", "en", "es" ],
},
```

En Xcode se hace en *Project → Info → Localizations*, con el botón `+`.

- `en` es la **región de desarrollo** y el idioma base: el idioma al que se
  vuelve si el dispositivo está en un idioma que la app no soporta.
- `Base` es la localización base de los storyboards.

---

## 3. Paso 2: crear el catálogo de cadenas

`horoscopo-iOS/Localizable.xcstrings` tiene como idioma de origen el
**inglés** (`"sourceLanguage": "en"`), el mismo en el que se escriben los textos
del código, y una traducción al español para cada clave.

Hay dos tipos de claves:

**a) El propio texto como clave** (el estilo por defecto de Xcode). Para los
literales del código:

| Clave (inglés) | Español |
|---|---|
| `Search sign` | Buscar signo |
| `Consulting the stars...` | Consultando con las estrellas... |
| `The prediction could not be loaded.` | No se pudo cargar la predicción. |
| `Day` / `Week` / `Month` | Día / Semana / Mes |
| `Translate` / `Show original` | Traducir / Ver original |
| `The prediction could not be translated.` | No se pudo traducir la predicción. |
| `OK` | Aceptar |

**b) Claves explícitas por signo.** Para los datos del modelo, donde el texto no
está escrito en el código:

| Clave | Inglés | Español |
|---|---|---|
| `aries.name` | Aries | Aries |
| `aries.dates` | March 21 - April 19 | 21 de marzo - 19 de abril |
| `taurus.name` | Taurus | Tauro |
| ... | ... | ... |

Son 24 claves (12 nombres y 12 fechas). Llevan `"extractionState": "manual"`
para que Xcode no las marque como obsoletas: como se construyen en el código con
`"\(id).name"`, Xcode no las detecta solo al analizar los literales.

Como en el resto de la app, la clave se construye con el `id` del signo, el mismo
que ya usan los iconos (`aries-icon`) y los colores (`aries-color`).

---

## 4. Paso 3: textos del código con `String(localized:)`

Los literales se envuelven así:

```swift
// Antes
predictionLabel.text = "The prediction could not be loaded."

// Después
predictionLabel.text = String(localized: "The prediction could not be loaded.")
```

`String(localized:)` busca el texto en el catálogo y devuelve el del idioma
activo. Si falta la clave, devuelve el propio texto, así que nunca se queda en
blanco. Se aplica en `ListViewController` (placeholder del buscador) y en
`DetailViewController` (estado de carga, error, aviso de traducción y selector).

---

## 5. Paso 4: nombres y fechas de los signos

El modelo `Horoscope` guardaba `name` y `dates` como texto fijo. Ahora guarda
solo el `id` y **calcula** esos dos campos leyendo el catálogo:

```swift
struct Horoscope {
    let id: String

    var name: String {
        return Bundle.main.localizedString(forKey: "\(id).name", value: nil, table: nil)
    }

    var dates: String {
        return Bundle.main.localizedString(forKey: "\(id).dates", value: nil, table: nil)
    }
    // ...
    static let horoscopeList: [Horoscope] = [
        Horoscope(id: "aries"),
        Horoscope(id: "taurus"),
        // ...
    ]
}
```

Se usa `Bundle.main.localizedString(forKey:...)` y no `String(localized:)` porque
la clave se construye en tiempo de ejecución (`"\(id).name"`) y `String(localized:)`
está pensado para literales.

Consecuencias:
- La lista, la celda y el detalle **no cambian**: siguen leyendo `horoscope.name`
  y `horoscope.dates`.
- El buscador filtra sobre `name`, así que **busca en el idioma activo**. Como
  usa `localizedStandardContains`, ignora tildes: "geminis" encuentra "Géminis".

**Alternativa descartada:** guardar mes y día de inicio y fin y generar el texto
con `DateFormatter`, que formatea según el idioma. Evitaría escribir 12 rangos por
idioma, pero cambia más el modelo. Con dos idiomas, las claves son más simples.

---

## 6. Paso 5: el selector de periodo

Los títulos "Day / Week / Month" están en el storyboard como texto base en
inglés. Para localizarlos se sobrescriben desde el código al cargar la pantalla:

```swift
private func setupPeriodTitles() {
    periodSegmentedControl.setTitle(String(localized: "Day"), forSegmentAt: Period.day.rawValue)
    periodSegmentedControl.setTitle(String(localized: "Week"), forSegmentAt: Period.week.rawValue)
    periodSegmentedControl.setTitle(String(localized: "Month"), forSegmentAt: Period.month.rawValue)
}
```

Es una decisión práctica: localizar textos de un storyboard exige un archivo
`.strings` por idioma cuyas claves son los identificadores internos de cada vista,
y es más frágil. Con tres textos, hacerlo en el código es más sencillo.

---

## 7. Paso 6: traducir la predicción (framework Translation)

### 7.1 Qué se hace y cuándo

- La predicción llega en inglés y se muestra tal cual.
- Si el idioma de la app **no** es el inglés, aparece un botón **Translate** (en español,
  **Traducir**) entre el selector y el texto.
- Al pulsarlo se traduce al idioma de la app. El botón pasa a **Show original**
  (en español, **Ver original**),
  y pulsarlo otra vez devuelve el inglés.
- Se decidió que sea el usuario quien lo pida, y no hacerlo automáticamente: la
  primera vez el sistema puede pedir descargar los idiomas, y así solo ocurre si
  el usuario lo quiere. Siempre se puede ver el original.

### 7.2 El problema: Translation es de SwiftUI

El framework solo entrega su sesión de traducción (`TranslationSession`) a través
del modificador de SwiftUI `translationTask`. Nuestra app es UIKit, así que se
usa un **puente**:

```
DetailViewController ──► PredictionTranslator ◄── TranslationHostView (SwiftUI)
   (pide traducir)         (estado compartido)      (ejecuta la sesión)
```

Todo está en `Utils/PredictionTranslator.swift`:

- **`PredictionTranslator`**: un objeto `@Observable` con la `configuration`
  (idioma de origen y destino), el texto a traducir y un `completion`.
  - `translate(_:completion:)` guarda el texto y activa la configuración. Si ya
    había una igual, llama a `invalidate()` para forzar otra ejecución, porque
    cambiar a una configuración idéntica no relanza nada.
  - `canTranslate` es `false` si el idioma de la app es inglés (no se puede
    traducir de inglés a inglés).
  - El idioma de destino sale de `Bundle.main.preferredLocalizations`, es decir,
    el idioma **de la app**, que es el mismo en el que se ven el resto de textos.
- **`TranslationHostView`**: una vista SwiftUI transparente con
  `.translationTask(translator.configuration)`. Cuando la configuración cambia,
  el sistema le da una sesión, traduce con `session.translate(texto)` y devuelve
  el resultado al `completion`.

### 7.3 Incrustar la vista SwiftUI en el detalle

`DetailViewController.setupTranslation()` crea un `UIHostingController` con la
vista invisible (1×1 puntos, sin interacción) y la añade como hijo:

```swift
let host = UIHostingController(rootView: TranslationHostView(translator: translator))
addChild(host)
view.addSubview(host.view)
// ... constraints de 1x1 ...
host.didMove(toParent: self)
```

Debe formar parte de la jerarquía de vistas para que el sistema pueda mostrar,
si hace falta, el panel de descarga de idiomas.

### 7.4 El botón

En el storyboard hay un `UIButton` ("Translate") oculto por defecto, conectado al
outlet `translateButton` y a la acción `translateButtonClicked(_:)`. La lógica:

1. Si ya se está mostrando la traducción, vuelve al original.
2. Si ya se tradujo antes ese mismo texto, la reutiliza sin pedirla otra vez.
3. Si no, la pide al traductor. Mientras tanto, el botón queda desactivado.
4. Cuando llega el resultado, comprueba que la predicción **sigue siendo la misma**
   (el usuario pudo cambiar de periodo mientras tanto): si no, lo descarta.
5. Si falla, muestra una alerta con "No se pudo traducir la predicción." y deja el
   texto original.

Al cambiar de periodo se reinicia todo: se borra la traducción guardada, se
oculta el botón y se vuelve a mostrar al llegar la nueva predicción.

**Compartir** envía el texto que se está viendo en ese momento, original o
traducido.

---

## 8. Cómo se comprobó y qué falta por comprobar

Se probó en el simulador arrancando la app en cada idioma, con los argumentos
`-AppleLanguages (en)` / `(es)` (en Xcode: *Edit Scheme → Run → Options → App
Language*).

**Comprobado**
- En inglés (antes de pasarlo a idioma base): nombres y fechas en inglés,
  placeholder "Search sign", selector Day / Week / Month, el buscador filtra
  ("tau" deja solo Taurus) y **no** aparece el botón de traducir. Tras el cambio
  de idioma base solo se compiló; no se volvió a ejecutar en inglés.
- En español, ya con el inglés como base: nombres y fechas en español,
  placeholder "Buscar signo", selector Día / Semana / Mes, y el botón
  **Traducir** (no "Translate") aparece entre el selector y el texto. Esto
  confirma que las claves en inglés encuentran su traducción al español.
- Al pulsar Traducir en el simulador, el sistema indica que la traducción **no
  está disponible en dispositivos simulados**, y la app muestra la alerta de
  error y conserva el texto original. Es decir, el camino de error funciona.

**Sin comprobar** (requiere un dispositivo real)
- Que la predicción se traduzca realmente al español.
- El panel de descarga de idiomas.
- El cambio de botón a "Ver original" y la vuelta al original.
- Que la traducción se reutilice al pulsar Traducir otra vez.
- Que el botón se reinicie al cambiar de periodo estando traducido.

---

## 9. Limitaciones conocidas

- **El título "The Zoltan horoscope"** de la pantalla de lista sigue en inglés en
  español: está escrito en el storyboard y no se ha localizado (puede ser un
  nombre de marca; si no, habría que localizarlo).
- **Accesibilidad de los botones:** el botón del corazón se anuncia como
  "love" en inglés y "me gusta" en español, que son las etiquetas por defecto del
  icono del sistema. No se les ha puesto una etiqueta propia.
- **Idiomas soportados:** la traducción solo cubre inglés → idioma de la app. Si
  se añade otro idioma a la interfaz, hay que añadir sus columnas al catálogo, y
  comprobar que el par inglés → ese idioma lo soporta Translation.
- **Tamaño de textos:** los textos en inglés y español tienen longitudes
  parecidas; en idiomas más largos habría que revisar el layout.

---

## 10. Resumen

1. Declarar `en` y `es` como idiomas del proyecto.
2. Crear `Localizable.xcstrings` con inglés como origen y las traducciones al
   español (claves literales y claves `<id>.name` / `<id>.dates`).
3. Envolver los literales del código con `String(localized:)`.
4. Hacer que `Horoscope` calcule `name` y `dates` desde el catálogo.
5. Localizar el selector de periodo desde el código.
6. Traducir la predicción con `Translation` mediante un puente
   (`PredictionTranslator` + `TranslationHostView`) y un botón *Translate* / *Traducir*.
