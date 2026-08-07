

# Generador de Datos de Salud

<!-- 
[![Release](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/release.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/release.yml)
[![CodeQL](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/codeql.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/codeql.yml)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/) -->
[![CI](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/ci.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faminbenarieb%2Fhealthkit-data-generator%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/aminbenarieb/healthkit-data-generator)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faminbenarieb%2Fhealthkit-data-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/aminbenarieb/healthkit-data-generator)
[![Tuist Preview](https://tuist.dev/amin-benarieb-work/healthkit-data-generator/previews/latest/badge.svg)](https://tuist.dev/<your-account>/<your-project>/previews/latest)

## Descripción general

HealthDataGenerator es un paquete integral de Swift que proporciona herramientas para:

- **Generación de datos**: Crea datos de muestra realistas de salud para pruebas
- **Exportación de datos**: Exporta datos de HealthKit a formato JSON con configuración flexible
- **Importación de datos**: Importa datos de salud desde perfiles JSON a Apple Health

### ¿Por qué usarlo?

- Llena Apple Health con datos realistas en minutos
- Perfecto para capturas de pantalla, demostraciones, pruebas de IU y QA
- Configuraciones impulsadas por IA: “Crea 2 semanas de entrenamiento para maratón” → muestras listas para usar

## Videos de demostración

| Generación manual  | Generación con LLM  | 
|---------|---------|
| <video width="320" height="240" src="https://github.com/user-attachments/assets/2e953227-0b84-4c1f-90af-cfdbc43583e6"></video>  |   <video width="320" height="240" src="https://github.com/user-attachments/assets/5b808db3-4ae7-4188-a687-505a9b71b5da"></video> | 


## Agradecimientos

Este proyecto está inspirado y se basa en el excelente trabajo realizado en [healthkit-sample-generator](https://github.com/mseemann/healthkit-sample-generator) de Michael Seemann. Si bien este paquete SPM es una reescritura completa con funciones modernas de Swift, integración de LLM y funcionalidad mejorada, reconocemos los conceptos y enfoques fundamentales del proyecto original.

## Instalación

### Gestor de Paquetes de Swift

Agrega el paquete HealthDataGenerator a tu proyecto:

```swift
dependencies: [
    .package(url: "https://github.com/aminbenarieb/healthkit-data-generator", from: "0.1.0")
]
```

### Compilación de la aplicación
Este proyecto utiliza [Tuist](https://tuist.io). Consulta su sitio web para instalarlo y luego ejecuta `tuist generate`.

## Uso

### Perfiles preestablecidos

```swift
import HealthDataGenerator
import HealthKit

let healthStore = HKHealthStore()
let generator = HealthDataGenerator(healthStore: healthStore)

// Generar 7 días de datos con perfil deportivo
let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(7)
)

let allTypes = HealthConstants.authorizationWriteTypes()
try generator.generateAndPopulate(samplesTypes: allTypes, config: config)
```

### Presets rápidos

```swift
// Última semana - perfil deportivo
let config1 = SampleGenerationConfig.lastWeekSporty()

// Último mes - perfil equilibrado
let config2 = SampleGenerationConfig.lastMonthBalanced()

// Última semana - perfil de estrés
let config3 = SampleGenerationConfig.lastWeekStressed()

try generator.generateAndPopulate(samplesTypes: allTypes, config: config1)
```

### Ejemplos completos

Este repositorio incluye una aplicación de demostración en SwiftUI (`HealthDataGeneratorApp/`) que muestra todas las funciones del paquete con una interfaz intuitiva para la generación de datos de salud tanto manual como impulsada por IA.

Para ejemplos detallados de uso que cubren todas las funciones, consulta [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md), que incluye perfiles personalizados, rangos de fechas, selección de métricas, patrones de generación, integración con LLM y ejemplos de integración en aplicaciones.

### 🤖 Generación de datos de salud impulsada por IA

El `LLMManager` permite la generación de datos de salud impulsada por IA a partir de descripciones en lenguaje natural. Admite múltiples proveedores de LLM a través de una interfaz unificada y enruta automáticamente las solicitudes al mejor proveedor disponible.

```swift
import HealthDataGenerator
import HealthKit

let healthStore = HKHealthStore()
let llmManager = LLMManager()

// Generar datos de salud desde lenguaje natural
let response = try await llmManager.generateHealthConfig(from: 
    "Create 2 weeks of marathon training data for an athlete with high activity, excellent sleep, and high-protein diet"
)

// Importar la configuración generada
let generator = HealthDataGenerator(healthStore: healthStore)
try generator.importFromLLMJSON(response.json)
```

#### Proveedor LLM actual
Apple Foundation Model (iOS 26.0+): Integración nativa con el modelo de IA en dispositivo de Apple

#### Extensión con proveedores personalizados
Puedes agregar proveedores de LLM personalizados implementando el protocolo LLMProvider:
```swift
class CustomLLMProvider: LLMProvider {
    let identifier = "custom_provider"
    let name = "Custom LLM"
    var isAvailable: Bool { true }
    
    func generateHealthConfig(from prompt: String) async throws -> String {
        // Tu integración de LLM personalizada
        return generatedJSON
    }
    
    func canHandle(_ prompt: String) -> Bool {
        // Determina si este proveedor puede manejar la solicitud
        return true
    }
}

// Registra tu proveedor
llmManager.register(CustomLLMProvider())
```

El JSON generado sigue el esquema definido en [LLM_JSON_SCHEMA.md](LLM_JSON_SCHEMA.md), admitiendo tanto la generación basada en configuración como la especificación directa de muestras.

<!-- ### Data Export

```swift
import HealthDataGenerator


```

### Data Import

```swift
import HealthDataGenerator

``` -->


## Licencia

Este proyecto está licenciado bajo la Licencia MIT - consulta el archivo [LICENSE](LICENSE) para obtener más detalles.
