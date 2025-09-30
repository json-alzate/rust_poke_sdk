#!/bin/bash

# Script para compilar el SDK para diferentes plataformas

set -e

echo "🚀 Compilando Pokémon SDK para múltiples plataformas..."

# Función para verificar y configurar Android NDK
check_android_ndk() {
    echo "🔍 Verificando Android NDK..."
    
    # Buscar Android NDK en ubicaciones comunes
    NDK_PATHS=(
        "$ANDROID_NDK_HOME"
        "$ANDROID_HOME/ndk-bundle"
        "$HOME/Android/Sdk/ndk-bundle"
        "$HOME/Android/Sdk/ndk/"*
        "/opt/android-ndk"
        "/usr/local/android-ndk"
    )
    
    for ndk_path in "${NDK_PATHS[@]}"; do
        # Expandir globs
        for expanded_path in $ndk_path; do
            if [ -d "$expanded_path" ] && [ -f "$expanded_path/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang" ]; then
                export ANDROID_NDK_HOME="$expanded_path"
                export NDK_HOME="$expanded_path"
                echo "✅ Android NDK encontrado en: $expanded_path"
                return 0
            fi
        done
    done
    
    echo "❌ Android NDK no encontrado."
    echo "📥 Por favor instala Android NDK:"
    echo "   1. Instalar via Android Studio SDK Manager"
    echo "   2. O descargar desde: https://developer.android.com/ndk/downloads"
    echo "   3. Configurar ANDROID_NDK_HOME variable de entorno"
    echo ""
    echo "💡 Ejemplo de configuración:"
    echo "   export ANDROID_NDK_HOME=/path/to/android-ndk-r25c"
    echo "   export PATH=\$PATH:\$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
    return 1
}

# Función para configurar variables de entorno de Android
setup_android_env() {
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "❌ ANDROID_NDK_HOME no está configurado"
        return 1
    fi
    
    export NDK_HOME="$ANDROID_NDK_HOME"
    export TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
    export PATH="$PATH:$TOOLCHAIN/bin"
    
    # Configurar linkers para cada arquitectura
    export CC_aarch64_linux_android="$TOOLCHAIN/bin/aarch64-linux-android21-clang"
    export CXX_aarch64_linux_android="$TOOLCHAIN/bin/aarch64-linux-android21-clang++"
    export AR_aarch64_linux_android="$TOOLCHAIN/bin/llvm-ar"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$TOOLCHAIN/bin/aarch64-linux-android21-clang"
    
    export CC_armv7_linux_androideabi="$TOOLCHAIN/bin/armv7a-linux-androideabi21-clang"
    export CXX_armv7_linux_androideabi="$TOOLCHAIN/bin/armv7a-linux-androideabi21-clang++"
    export AR_armv7_linux_androideabi="$TOOLCHAIN/bin/llvm-ar"
    export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$TOOLCHAIN/bin/armv7a-linux-androideabi21-clang"
    
    export CC_i686_linux_android="$TOOLCHAIN/bin/i686-linux-android21-clang"
    export CXX_i686_linux_android="$TOOLCHAIN/bin/i686-linux-android21-clang++"
    export AR_i686_linux_android="$TOOLCHAIN/bin/llvm-ar"
    export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="$TOOLCHAIN/bin/i686-linux-android21-clang"
    
    export CC_x86_64_linux_android="$TOOLCHAIN/bin/x86_64-linux-android21-clang"
    export CXX_x86_64_linux_android="$TOOLCHAIN/bin/x86_64-linux-android21-clang++"
    export AR_x86_64_linux_android="$TOOLCHAIN/bin/llvm-ar"
    export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$TOOLCHAIN/bin/x86_64-linux-android21-clang"
    
    echo "✅ Variables de entorno de Android configuradas"
    return 0
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [android|ios|wasm|all|clean]"
    echo ""
    echo "Opciones:"
    echo "  android  - Compila para Android (ARM64 y ARMv7)"
    echo "  ios      - Compila para iOS (ARM64 y x86_64 simulator)"
    echo "  wasm     - Compila para WebAssembly"
    echo "  all      - Compila para todas las plataformas"
    echo "  clean    - Limpia los archivos de compilación"
    echo "  help     - Muestra esta ayuda"
}

# Función para limpiar
clean() {
    echo "🧹 Limpiando archivos de compilación..."
    cargo clean
    rm -rf target/
    rm -rf pkg/
    rm -rf dist/
    echo "✅ Limpieza completada"
}

# Función para compilar para Android
build_android() {
    echo "🤖 Compilando para Android..."
    
    # Verificar y configurar Android NDK
    if ! check_android_ndk; then
        echo "❌ No se puede compilar para Android sin NDK"
        echo "💡 Consulta ANDROID_SETUP.md para instrucciones detalladas"
        return 1
    fi
    
    if ! setup_android_env; then
        echo "❌ Error configurando entorno de Android"
        return 1
    fi
    
    # Instalar targets si no están instalados
    echo "📦 Instalando targets de Android..."
    rustup target add aarch64-linux-android
    rustup target add armv7-linux-androideabi
    rustup target add i686-linux-android
    rustup target add x86_64-linux-android
    
    # Compilar para diferentes arquitecturas de Android
    echo "📱 Compilando para ARM64..."
    cargo build --release --target aarch64-linux-android
    
    echo "📱 Compilando para ARMv7..."
    cargo build --release --target armv7-linux-androideabi
    
    echo "📱 Compilando para x86_64 (emulador)..."
    cargo build --release --target x86_64-linux-android
    
    echo "📱 Compilando para i686 (emulador)..."
    cargo build --release --target i686-linux-android
    
    # Crear directorio de distribución
    mkdir -p dist/android/lib/{arm64-v8a,armeabi-v7a,x86_64,x86}
    mkdir -p dist/android/include
    
    # Copiar librerías
    cp target/aarch64-linux-android/release/libpoke_sdk.so dist/android/lib/arm64-v8a/
    cp target/armv7-linux-androideabi/release/libpoke_sdk.so dist/android/lib/armeabi-v7a/
    cp target/x86_64-linux-android/release/libpoke_sdk.so dist/android/lib/x86_64/
    cp target/i686-linux-android/release/libpoke_sdk.so dist/android/lib/x86/
    
    # Copiar header
    cp poke_sdk.h dist/android/include/
    
    echo "✅ Compilación para Android completada en dist/android/"
}

# Función para compilar para iOS
build_ios() {
    echo "🍎 Compilando para iOS..."
    
    # Instalar targets si no están instalados
    rustup target add aarch64-apple-ios
    rustup target add x86_64-apple-ios
    rustup target add aarch64-apple-ios-sim
    
    # Compilar para diferentes arquitecturas de iOS
    echo "📱 Compilando para iOS ARM64 (dispositivos)..."
    cargo build --release --target aarch64-apple-ios
    
    echo "📱 Compilando para iOS Simulator x86_64..."
    cargo build --release --target x86_64-apple-ios
    
    echo "📱 Compilando para iOS Simulator ARM64..."
    cargo build --release --target aarch64-apple-ios-sim
    
    # Crear directorio de distribución
    mkdir -p dist/ios/lib
    mkdir -p dist/ios/include
    
    # Copiar librerías
    cp target/aarch64-apple-ios/release/libpoke_sdk.a dist/ios/lib/libpoke_sdk_ios.a
    cp target/x86_64-apple-ios/release/libpoke_sdk.a dist/ios/lib/libpoke_sdk_simulator_x64.a
    cp target/aarch64-apple-ios-sim/release/libpoke_sdk.a dist/ios/lib/libpoke_sdk_simulator_arm64.a
    
    # Copiar header
    cp poke_sdk.h dist/ios/include/
    
    echo "✅ Compilación para iOS completada en dist/ios/"
}

# Función para compilar para WebAssembly
build_wasm() {
    echo "🌐 Compilando para WebAssembly..."
    
    # Instalar wasm-pack si no está instalado
    if ! command -v wasm-pack &> /dev/null; then
        echo "📦 Instalando wasm-pack..."
        curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
    fi
    
    # Compilar con wasm-pack
    wasm-pack build --target web --out-dir pkg
    
    # Crear directorio de distribución
    mkdir -p dist/wasm
    cp -r pkg/* dist/wasm/
    
    echo "✅ Compilación para WebAssembly completada en dist/wasm/"
}

# Función para compilar todo
build_all() {
    build_android
    build_ios
    build_wasm
    echo "🎉 ¡Compilación completada para todas las plataformas!"
}

# Main
case "$1" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    wasm)
        build_wasm
        ;;
    all)
        build_all
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Opción no válida: $1"
        show_help
        exit 1
        ;;
esac