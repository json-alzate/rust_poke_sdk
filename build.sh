#!/bin/bash

# Script para compilar el SDK para diferentes plataformas

set -e

echo "🚀 Compilando Pokémon SDK para múltiples plataformas..."

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
    echo "✅ Limpieza completada"
}

# Función para compilar para Android
build_android() {
    echo "🤖 Compilando para Android..."
    
    # Instalar targets si no están instalados
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