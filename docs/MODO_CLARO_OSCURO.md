# Modo claro y oscuro con iconos tintados

Este documento explica cómo la app se adapta al modo claro y oscuro del
sistema y cómo cada signo tiene su propio color, con un contraste accesible en
ambos modos. Continúa el [tutorial principal](TUTORIAL.md).

---

## 1. Qué se consigue

- La app **sigue el modo del sistema** (Ajustes → Pantalla y brillo). No hay
  interruptor propio.
- Los iconos de los signos **se tintan** con un color distinto para cada signo.
- Cada color tiene **dos variantes**: una más oscura para fondo claro y una más
  clara para fondo oscuro, de modo que el icono se ve bien en los dos.

---

## 2. Cómo funciona el modo oscuro en iOS

iOS decide el aspecto con la **trait collection** de cada vista
(`userInterfaceStyle`: `.light` o `.dark`). Si usas colores del sistema o
colores de Assets con variante oscura, UIKit **repinta solo** cuando el usuario
cambia de modo, sin código extra.

Por eso no hace falta tocar `Info.plist`: mientras no exista la clave
`UIUserInterfaceStyle`, la app sigue al sistema.

Lo que ya era dinámico en el proyecto:

- El fondo de las pantallas y de la tabla usa `systemBackgroundColor`.
- Los textos de los labels usan el color por defecto (`label`).

Lo único que no se adaptaba eran los **iconos**: los SVG están dibujados en
negro (`#000000`), así que sobre fondo oscuro eran casi invisibles.

---

## 3. Paso 1: iconos como plantilla (template)

Un icono se puede dibujar de dos maneras:

- **Original**: se muestra tal cual, con sus colores.
- **Template**: solo cuenta su forma (la transparencia) y se pinta con el
  `tintColor` de la vista.

Para poder tintar los SVG hay que marcarlos como *template*. En cada
`*.imageset/Contents.json` se añade:

```json
"properties" : {
  "template-rendering-intent" : "template"
}
```

En Xcode se hace seleccionando el image set y, en el *Attributes Inspector*,
poniendo *Render As → Template Image*.

---

## 4. Paso 2: colores en Assets con variante clara y oscura

Se crea una carpeta `Horoscope-colors` en `Assets.xcassets` con un *color set*
por signo, con la misma convención que los iconos: `<id>-color`
(`aries-color`, `taurus-color`...).

Cada color set tiene dos entradas: la normal (modo claro) y otra con
*Appearances → Any, Dark* (modo oscuro). En Xcode: seleccionar el color set y
activar *Appearances → Any, Dark* en el inspector.

Como con los iconos, la carpeta `Horoscope-colors` **no** debe tener
*Provides Namespace*, para que `UIColor(named: "aries-color")` funcione.

### Paleta y contraste

El contraste es la proporción de luminosidad entre el color y el fondo. Las
pautas WCAG 2.1 piden:

- **4.5:1** para texto normal.
- **3:1** para elementos gráficos como iconos (criterio 1.4.11).

Los colores se han elegido para superar **4.5:1** en ambos modos, que cubre de
sobra el mínimo para iconos. Se ha calculado contra el blanco (`#FFFFFF`, fondo
del modo claro) y contra el negro (`#000000`, fondo base del modo oscuro).

| Signo | Claro | Contraste | Oscuro | Contraste |
|---|---|---|---|---|
| Aries | `#C62828` | 5.62 | `#FF8A80` | 9.20 |
| Tauro | `#2E7D32` | 5.13 | `#81C784` | 10.44 |
| Géminis | `#9A6700` | 4.87 | `#FFD54F` | 14.88 |
| Cáncer | `#1565C0` | 5.75 | `#90CAF9` | 12.00 |
| Leo | `#B34700` | 5.50 | `#FFB74D` | 12.13 |
| Virgo | `#6B6B00` | 5.63 | `#DCE775` | 15.73 |
| Libra | `#C2185B` | 5.87 | `#F48FB1` | 9.41 |
| Escorpio | `#880E4F` | 9.45 | `#F06292` | 6.87 |
| Sagitario | `#3949AB` | 7.73 | `#9FA8DA` | 9.09 |
| Capricornio | `#455A64` | 7.24 | `#B0BEC5` | 11.02 |
| Acuario | `#00838F` | 4.52 | `#80DEEA` | 13.55 |
| Piscis | `#5E35B1` | 8.02 | `#B39DDB` | 8.76 |

Regla práctica: en modo claro se usa una versión **oscura y saturada** del tono,
y en modo oscuro una versión **clara y suave**. Para comprobar un color nuevo,
la fórmula del ratio es `(L1 + 0.05) / (L2 + 0.05)`, con `L1` la luminancia
relativa del más claro y `L2` la del más oscuro.

Algunos tonos son parecidos entre sí (por ejemplo Escorpio y Libra, o Cáncer y
Sagitario). Si se quiere más separación, se puede ajustar sin tocar código,
solo editando los color sets.

---

## 5. Paso 3: el color en el modelo

Se añade una propiedad calculada a `Horoscope`, igual que `icon`:

```swift
// Color propio del signo. El asset "<id>-color" define una variante para
// modo claro y otra para oscuro, y el sistema elige la correcta solo.
var color: UIColor {
    return UIColor(named: "\(id)-color") ?? .label
}
```

`UIColor(named:)` devuelve un color **dinámico**: no se fija un valor al
crearlo, se resuelve cada vez que la vista se dibuja según el modo actual. Si
falta el asset, se usa `.label` (negro en claro, blanco en oscuro) para que el
icono nunca desaparezca.

---

## 6. Paso 4: aplicar el tinte

En la celda (`HoroscopeViewCell.render`) y en el detalle
(`DetailViewController.viewDidLoad`) se añade una línea tras asignar el icono:

```swift
signImageView.image = horoscope.icon
signImageView.tintColor = horoscope.color
```

Como el color es dinámico y la imagen es *template*, al cambiar de modo el
sistema vuelve a calcular el tinte **sin que el código haga nada más**.

---

## 7. Cómo probarlo

1. Ejecuta la app en el simulador.
2. Cambia el modo sin salir de la app con la opción *Environment Overrides*
   (icono de interruptores) de la barra de depuración de Xcode, o desde los
   Ajustes del simulador (Pantalla y brillo).
3. Comprueba en la lista y en el detalle que cada signo mantiene su color y que
   se distingue bien en claro y en oscuro.

Para revisar la accesibilidad, usa el *Accessibility Inspector* de Xcode
(*Xcode → Open Developer Tool → Accessibility Inspector*), que mide el
contraste de los elementos en pantalla.

---

## 8. Errores típicos

| Síntoma | Causa probable |
|---|---|
| El icono sigue negro en modo oscuro | El image set no está como *Template Image* |
| El icono sale siempre en `label` (negro/blanco) | El nombre del color set no es `<id>-color`, o la carpeta tiene *Provides Namespace* |
| El color no cambia al alternar el modo | El color set no tiene la variante *Dark* |
| Un color se ve apagado en un modo | Su contraste es inferior a 4.5:1; recalcúlalo con la fórmula del apartado 4 |

---

## 9. Resumen

1. Los iconos pasan a ser *template* para poder tintarse.
2. Cada signo tiene un color en Assets con variante clara y oscura.
3. `Horoscope.color` lo expone al código como `UIColor` dinámico.
4. La celda y el detalle lo aplican con `tintColor`.
5. El sistema hace el resto al cambiar de modo.
