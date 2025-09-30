# 🎮 Pokémon SDK

Un SDK multiplataforma escrito en Rust que permite consultar la API de Pokémon desde aplicaciones nativas (Android/iOS) y web (WebAssembly).

## 📋 Características

- ✅ **Multiplataforma**: Android, iOS y WebAssembly
- ✅ **Alto rendimiento**: Implementado en Rust
- ✅ **Fácil integración**: APIs simples para cada plataforma
- ✅ **Gestión de memoria**: Sin memory leaks
- ✅ **Manejo de errores**: Respuestas estructuradas con manejo de errores
- ✅ **Tipado fuerte**: Estructuras de datos bien definidas

## 🏗️ Compilación

### Prerrequisitos

1. **Rust**: Instalar desde [rustup.rs](https://rustup.rs/)
2. **Targets adicionales**: Se instalan automáticamente con el script de build

### Script de Build Automático

```bash
# Hacer el script ejecutable
chmod +x build.sh

# Compilar para todas las plataformas
./build.sh all

# O compilar para plataformas específicas
./build.sh android    # Solo Android
./build.sh ios        # Solo iOS  
./build.sh wasm       # Solo WebAssembly

# Limpiar archivos de compilación
./build.sh clean
```

### Build Manual

#### Android

```bash
# Instalar targets
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

# Compilar
cargo build --release --target aarch64-linux-android
cargo build --release --target armv7-linux-androideabi
cargo build --release --target x86_64-linux-android
cargo build --release --target i686-linux-android
```

#### iOS

```bash
# Instalar targets
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

# Compilar
cargo build --release --target aarch64-apple-ios
cargo build --release --target x86_64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
```

#### WebAssembly

```bash
# Instalar wasm-pack
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# Compilar
wasm-pack build --target web --out-dir pkg
```

## 🚀 Instalación y Uso

### Android

#### 1. Agregar la librería al proyecto

Copiar los archivos desde `dist/android/`:

```
app/src/main/jniLibs/
├── arm64-v8a/
│   └── libpoke_sdk.so
├── armeabi-v7a/
│   └── libpoke_sdk.so
├── x86/
│   └── libpoke_sdk.so
└── x86_64/
    └── libpoke_sdk.so

app/src/main/cpp/
└── poke_sdk.h
```

#### 2. Agregar permisos de internet

En `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

#### 3. Usar el SDK

**Java:**
```java
// Cargar librería
static {
    System.loadLibrary("poke_sdk");
}

// Declarar método nativo
public static native String getPokemonJson(int id);

// Usar
String result = getPokemonJson(25); // Pikachu
```

**Kotlin:**
```kotlin
object PokemonSDK {
    init {
        System.loadLibrary("poke_sdk")
    }
    
    private external fun getPokemonJson(id: Int): String?
    
    suspend fun getPokemon(id: Int): PokemonResult = withContext(Dispatchers.IO) {
        // Implementación...
    }
}

// Usar con coroutines
val result = PokemonSDK.getPokemon(25)
```

### iOS

#### 1. Agregar la librería al proyecto

1. Crear un grupo "Libraries" en Xcode
2. Arrastrar `libpoke_sdk_ios.a` al proyecto
3. Agregar `poke_sdk.h` al bridging header

#### 2. Configurar Bridging Header

En tu bridging header (`YourProject-Bridging-Header.h`):

```c
#import "poke_sdk.h"
```

#### 3. Usar el SDK

**Swift:**
```swift
class PokemonSDK {
    static func getPokemon(id: Int, completion: @escaping (Result) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let jsonCString = get_pokemon_json(UInt32(id))
            let jsonString = String(cString: jsonCString!)
            free_string(jsonCString)
            
            // Procesar JSON...
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// Usar
PokemonSDK.getPokemon(id: 25) { result in
    switch result {
    case .success(let pokemon):
        print("Pokemon: \\(pokemon.name)")
    case .failure(let error):
        print("Error: \\(error)")
    }
}
```

### WebAssembly

#### 1. Instalar el paquete

Copiar los archivos desde `dist/wasm/` a tu proyecto web.

#### 2. Usar el SDK

**JavaScript/HTML:**
```html
<script type="module">
import init, { get_pokemon_wasm } from './pkg/poke_sdk.js';

async function main() {
    // Inicializar WASM
    await init();
    
    // Obtener Pokémon
    const result = await get_pokemon_wasm(25);
    
    if (result.success) {
        console.log('Pokemon:', result.pokemon);
    } else {
        console.error('Error:', result.error);
    }
}

main();
</script>
```

**React:**
```jsx
import { useEffect, useState } from 'react';
import init, { get_pokemon_wasm } from './pkg/poke_sdk.js';

function PokemonComponent() {
    const [pokemon, setPokemon] = useState(null);
    
    useEffect(() => {
        init().then(async () => {
            const result = await get_pokemon_wasm(25);
            if (result.success) {
                setPokemon(result.pokemon);
            }
        });
    }, []);
    
    return (
        <div>
            {pokemon && <h1>{pokemon.name}</h1>}
        </div>
    );
}
```

## 📚 API Reference

### Estructuras de Datos

#### Pokemon

```rust
struct Pokemon {
    id: u32,
    name: String,
    height: u32,
    weight: u32,
    base_experience: Option<u32>,
    sprites: PokemonSprites,
    types: Vec<PokemonType>,
}
```

#### PokemonResult

```rust
struct PokemonResult {
    success: bool,
    pokemon: Option<Pokemon>,
    error: Option<String>,
}
```

### Funciones

#### Para Android/iOS (C ABI)

```c
// Obtener Pokémon como JSON string
char* get_pokemon_json(unsigned int id);

// Liberar memoria del string retornado
void free_string(char* ptr);
```

#### Para WebAssembly

```rust
// Función async que retorna Promise<PokemonResult>
async fn get_pokemon_wasm(id: u32) -> JsValue;
```

#### Para Rust nativo

```rust
// Función síncrona
fn get_pokemon(id: u32) -> PokemonResult;
```

## 🧪 Testing

```bash
# Ejecutar tests
cargo test

# Test específico
cargo test test_get_pokemon_structure
```

## 📝 Ejemplos Completos

Los ejemplos completos están disponibles en la carpeta `examples/`:

- [`android_java_example.java`](examples/android_java_example.java) - Implementación completa para Android en Java
- [`android_kotlin_example.kt`](examples/android_kotlin_example.kt) - Implementación completa para Android en Kotlin  
- [`ios_swift_example.swift`](examples/ios_swift_example.swift) - Implementación completa para iOS en Swift
- [`web_javascript_example.js`](examples/web_javascript_example.js) - Implementación completa para Web

## 🔧 Configuración de Desarrollo

### Android NDK

Para desarrollar para Android, necesitas el Android NDK. Puedes instalarlo a través de Android Studio o:

```bash
# Configurar variables de entorno
export ANDROID_NDK_HOME=/path/to/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin
```

### iOS Development

Para desarrollar para iOS necesitas:
- Xcode (solo en macOS)
- iOS SDK

### WebAssembly

Para desarrollo web necesitas:
- Node.js (para herramientas de desarrollo)
- Un servidor web para servir los archivos WASM

## 🚨 Notas Importantes

### Gestión de Memoria

**Importante para Android/iOS**: Siempre llamar `free_string()` después de usar `get_pokemon_json()` para evitar memory leaks:

```c
char* result = get_pokemon_json(25);
// Usar el resultado...
free_string(result); // ¡IMPORTANTE!
```

### Manejo de Errores

El SDK maneja los errores de manera elegante y retorna estructuras con información detallada del error. Siempre verificar el campo `success` antes de acceder a los datos.

### Limitaciones

- WebAssembly requiere CORS habilitado para consultas a APIs externas
- Las consultas son síncronas en Android/iOS y asíncronas en WebAssembly
- Se requiere conexión a internet para consultar la API de Pokémon

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear un Pull Request

## 📞 Soporte

Si tienes problemas o preguntas:

1. Revisar los ejemplos en la carpeta `examples/`
2. Verificar que todas las dependencias estén instaladas
3. Asegurarse de que las librerías estén correctamente enlazadas
4. Crear un issue en el repositorio con detalles del problema

---

¡Feliz desarrollo con Pokémon! 🎮✨