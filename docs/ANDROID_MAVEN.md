# Configuración para Android con Maven

## Estructura del AAR para Maven

Para distribuir el SDK como un AAR a través de Maven, necesitas crear la siguiente estructura:

```
poke-sdk-android/
├── build.gradle
├── src/
│   └── main/
│       ├── AndroidManifest.xml
│       ├── jniLibs/
│       │   ├── arm64-v8a/
│       │   │   └── libpoke_sdk.so
│       │   ├── armeabi-v7a/
│       │   │   └── libpoke_sdk.so
│       │   ├── x86/
│       │   │   └── libpoke_sdk.so
│       │   └── x86_64/
│       │       └── libpoke_sdk.so
│       └── java/
│           └── com/
│               └── yourcompany/
│                   └── pokesdk/
│                       └── PokemonSDK.java
└── proguard-rules.pro
```

## build.gradle del AAR

```gradle
plugins {
    id 'com.android.library'
    id 'maven-publish'
}

android {
    namespace 'com.yourcompany.pokesdk'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34
        
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation 'androidx.core:core:1.12.0'
}

publishing {
    publications {
        release(MavenPublication) {
            from components.release
            
            groupId = 'com.yourcompany'
            artifactId = 'poke-sdk'
            version = '1.0.0'
            
            pom {
                name = 'Pokemon SDK'
                description = 'A cross-platform SDK for Pokemon API integration'
                url = 'https://github.com/yourcompany/poke-sdk'
                
                licenses {
                    license {
                        name = 'MIT License'
                        url = 'https://opensource.org/licenses/MIT'
                    }
                }
            }
        }
    }
}
```

## AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
```

## Uso en aplicaciones Android

### 1. Agregar al build.gradle de la app:

```gradle
dependencies {
    implementation 'com.yourcompany:poke-sdk:1.0.0'
}
```

### 2. Usar en código:

```java
import com.yourcompany.pokesdk.PokemonSDK;

// En tu Activity o Fragment
private void fetchPokemon() {
    new Thread(() -> {
        PokemonSDK.PokemonResult result = PokemonSDK.getPokemon(25);
        
        runOnUiThread(() -> {
            if (result.success) {
                // Actualizar UI con result.pokemon
                Log.d("Pokemon", "Name: " + result.pokemon.name);
            } else {
                // Mostrar error
                Log.e("Pokemon", "Error: " + result.error);
            }
        });
    }).start();
}
```

## Script de build para AAR

```bash
#!/bin/bash

# build_aar.sh - Script para crear el AAR

echo "🔨 Compilando librerías nativas..."

# Compilar para Android
./build.sh android

echo "📦 Creando estructura del AAR..."

# Crear estructura
mkdir -p android-aar/src/main/jniLibs/
mkdir -p android-aar/src/main/java/com/yourcompany/pokesdk/

# Copiar librerías nativas
cp -r dist/android/lib/* android-aar/src/main/jniLibs/

# Copiar código Java
cp examples/android_java_example.java android-aar/src/main/java/com/yourcompany/pokesdk/PokemonSDK.java

# Copiar archivos de configuración
cp android-config/build.gradle android-aar/
cp android-config/AndroidManifest.xml android-aar/src/main/

echo "🏗️ Compilando AAR..."
cd android-aar
./gradlew assembleRelease

echo "✅ AAR creado en: android-aar/build/outputs/aar/"
```

## Publicar a Maven Central

### 1. Configurar credenciales en ~/.gradle/gradle.properties:

```properties
signing.keyId=12345678
signing.password=yourpassword
signing.secretKeyRingFile=/Users/yourname/.gnupg/secring.gpg

ossrhUsername=yourusername
ossrhPassword=yourpassword
```

### 2. Configurar firma en build.gradle:

```gradle
plugins {
    id 'signing'
}

signing {
    sign publishing.publications.release
}
```

### 3. Publicar:

```bash
./gradlew publishReleasePublicationToSonatypeRepository
```

## Maven Local (para testing)

```bash
# Publicar a repositorio local
./gradlew publishToMavenLocal

# Usar en otras apps localmente
dependencies {
    implementation 'com.yourcompany:poke-sdk:1.0.0'
}
```