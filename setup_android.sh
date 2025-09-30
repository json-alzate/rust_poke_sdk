#!/bin/bash

# Script de configuración rápida para Android NDK

set -e

echo "🔧 Configurando Android NDK..."

# Función para detectar NDK
detect_ndk() {
    local ndk_paths=(
        "$ANDROID_NDK_HOME"
        "$ANDROID_HOME/ndk-bundle"
        "$HOME/Android/Sdk/ndk-bundle"
        "$HOME/Android/Sdk/ndk/"*
        "/opt/android-ndk"
        "/usr/local/android-ndk"
    )
    
    for ndk_path in "${ndk_paths[@]}"; do
        # Expandir globs
        for expanded_path in $ndk_path; do
            if [ -d "$expanded_path" ] && [ -f "$expanded_path/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang" ]; then
                echo "$expanded_path"
                return 0
            fi
        done
    done
    
    return 1
}

# Detectar NDK
if NDK_PATH=$(detect_ndk); then
    echo "✅ NDK encontrado en: $NDK_PATH"
    export ANDROID_NDK_HOME="$NDK_PATH"
    export NDK_HOME="$NDK_PATH"
else
    echo "❌ NDK no encontrado."
    echo ""
    echo "📦 Por favor instala Android NDK:"
    echo "   1. Via Android Studio (SDK Manager → SDK Tools → NDK)"
    echo "   2. O descargar desde: https://developer.android.com/ndk/downloads"
    echo ""
    echo "💡 Después de instalar, ejecuta este script nuevamente:"
    echo "   chmod +x setup_android.sh"
    echo "   ./setup_android.sh"
    exit 1
fi

# Configurar variables de entorno
export PATH="$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"

# Configurar variables para cargo
export CC_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CXX_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"
export AR_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"

export CC_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
export CXX_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang++"
export AR_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"

export CC_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang"
export CXX_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang++"
export AR_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"

export CC_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
export CXX_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang++"
export AR_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"

echo "✅ Variables de entorno configuradas"

# Verificar herramientas
echo "🔍 Verificando herramientas..."
TOOLS=(
    "aarch64-linux-android21-clang"
    "armv7a-linux-androideabi21-clang"
    "i686-linux-android21-clang"
    "x86_64-linux-android21-clang"
)

TOOLCHAIN_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
ALL_GOOD=true

for tool in "${TOOLS[@]}"; do
    if [ -f "$TOOLCHAIN_BIN/$tool" ]; then
        echo "  ✅ $tool"
    else
        echo "  ❌ $tool - NO ENCONTRADO"
        ALL_GOOD=false
    fi
done

if [ "$ALL_GOOD" = true ]; then
    echo ""
    echo "🎉 Configuración exitosa!"
    echo "🚀 Ahora puedes ejecutar: ./build.sh android"
    echo ""
    echo "💡 Para hacer permanente esta configuración, agrega a ~/.bashrc:"
    echo "export ANDROID_NDK_HOME=\"$ANDROID_NDK_HOME\""
    echo "export NDK_HOME=\"\$ANDROID_NDK_HOME\""
    echo "export PATH=\"\$PATH:\$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin\""
else
    echo ""
    echo "❌ Configuración incompleta. Verifica la instalación del NDK."
    exit 1
fi