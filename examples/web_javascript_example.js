// Ejemplo de uso del SDK en WebAssembly (JavaScript/HTML)
// Este archivo puede ser usado en cualquier aplicación web

// Cargar el módulo WebAssembly
import init, { get_pokemon_wasm } from './pkg/poke_sdk.js';

class PokemonSDK {
    constructor() {
        this.initialized = false;
        this.initPromise = null;
    }
    
    // Inicializar el módulo WASM
    async init() {
        if (this.initialized) return;
        if (this.initPromise) return this.initPromise;
        
        this.initPromise = init();
        await this.initPromise;
        this.initialized = true;
    }
    
    // Obtener un Pokémon por ID
    async getPokemon(id) {
        await this.init();
        
        try {
            const result = await get_pokemon_wasm(id);
            return result;
        } catch (error) {
            return {
                success: false,
                pokemon: null,
                error: error.message || 'Unknown error occurred'
            };
        }
    }
}

// Crear instancia global
const pokemonSDK = new PokemonSDK();

// Ejemplo de uso con HTML
/*
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pokémon SDK Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .pokemon-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            background-color: #f9f9f9;
        }
        .pokemon-image {
            max-width: 200px;
            height: auto;
        }
        .error {
            color: red;
            background-color: #ffe6e6;
            padding: 10px;
            border-radius: 4px;
        }
        .loading {
            color: blue;
            background-color: #e6f3ff;
            padding: 10px;
            border-radius: 4px;
        }
        button {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        input {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            margin: 5px;
        }
    </style>
</head>
<body>
    <h1>🎮 Pokémon SDK Demo</h1>
    
    <div>
        <input type="number" id="pokemonId" placeholder="ID del Pokémon (1-1010)" min="1" max="1010" value="1">
        <button id="getPokemonBtn" onclick="fetchPokemon()">Obtener Pokémon</button>
        <button onclick="getRandomPokemon()">Pokémon Aleatorio</button>
    </div>
    
    <div id="status"></div>
    <div id="pokemonContainer"></div>

    <script type="module">
        import init, { get_pokemon_wasm } from './pkg/poke_sdk.js';
        
        class PokemonApp {
            constructor() {
                this.initialized = false;
                this.init();
            }
            
            async init() {
                try {
                    await init();
                    this.initialized = true;
                    this.showStatus('SDK inicializado correctamente', 'success');
                } catch (error) {
                    this.showStatus(`Error al inicializar SDK: ${error.message}`, 'error');
                }
            }
            
            async getPokemon(id) {
                if (!this.initialized) {
                    await this.init();
                }
                
                this.showStatus('Obteniendo Pokémon...', 'loading');
                
                try {
                    const result = await get_pokemon_wasm(id);
                    
                    if (result.success) {
                        this.displayPokemon(result.pokemon);
                        this.showStatus('Pokémon obtenido exitosamente', 'success');
                    } else {
                        this.showStatus(`Error: ${result.error}`, 'error');
                    }
                    
                    return result;
                } catch (error) {
                    this.showStatus(`Error inesperado: ${error.message}`, 'error');
                    return {
                        success: false,
                        pokemon: null,
                        error: error.message
                    };
                }
            }
            
            displayPokemon(pokemon) {
                const container = document.getElementById('pokemonContainer');
                
                const types = pokemon.types.map(t => t.type.name).join(', ');
                
                container.innerHTML = `
                    <div class="pokemon-card">
                        <h2>${pokemon.name.charAt(0).toUpperCase() + pokemon.name.slice(1)}</h2>
                        <div style="display: flex; gap: 20px; align-items: flex-start;">
                            <div>
                                ${pokemon.sprites.front_default ? 
                                    `<img src="${pokemon.sprites.front_default}" alt="${pokemon.name}" class="pokemon-image">` : 
                                    '<div>No hay imagen disponible</div>'
                                }
                            </div>
                            <div>
                                <p><strong>ID:</strong> #${pokemon.id}</p>
                                <p><strong>Altura:</strong> ${pokemon.height / 10} m</p>
                                <p><strong>Peso:</strong> ${pokemon.weight / 10} kg</p>
                                ${pokemon.base_experience ? `<p><strong>Experiencia Base:</strong> ${pokemon.base_experience}</p>` : ''}
                                <p><strong>Tipos:</strong> ${types}</p>
                            </div>
                        </div>
                    </div>
                `;
            }
            
            showStatus(message, type) {
                const statusDiv = document.getElementById('status');
                statusDiv.className = type;
                statusDiv.textContent = message;
                
                if (type === 'loading') {
                    document.getElementById('getPokemonBtn').disabled = true;
                } else {
                    document.getElementById('getPokemonBtn').disabled = false;
                }
            }
            
            getRandomId() {
                return Math.floor(Math.random() * 1010) + 1;
            }
        }
        
        // Crear instancia global
        const app = new PokemonApp();
        
        // Funciones globales para los botones
        window.fetchPokemon = async function() {
            const id = parseInt(document.getElementById('pokemonId').value);
            if (id < 1 || id > 1010) {
                app.showStatus('Por favor, ingresa un ID válido (1-1010)', 'error');
                return;
            }
            await app.getPokemon(id);
        };
        
        window.getRandomPokemon = async function() {
            const randomId = app.getRandomId();
            document.getElementById('pokemonId').value = randomId;
            await app.getPokemon(randomId);
        };
        
        // Cargar Pokémon inicial al cargar la página
        window.addEventListener('load', () => {
            setTimeout(() => fetchPokemon(), 1000);
        });
    </script>
</body>
</html>
*/

// Ejemplo para uso en frameworks modernos (React, Vue, etc.)
/*
// React Example
import React, { useState, useEffect } from 'react';
import init, { get_pokemon_wasm } from './pkg/poke_sdk.js';

const PokemonComponent = () => {
    const [pokemon, setPokemon] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [pokemonId, setPokemonId] = useState(1);
    const [sdkReady, setSdkReady] = useState(false);
    
    useEffect(() => {
        // Inicializar SDK
        init().then(() => {
            setSdkReady(true);
        }).catch(err => {
            setError(`Failed to initialize SDK: ${err.message}`);
        });
    }, []);
    
    const fetchPokemon = async (id) => {
        if (!sdkReady) {
            setError('SDK not ready yet');
            return;
        }
        
        setLoading(true);
        setError(null);
        
        try {
            const result = await get_pokemon_wasm(id);
            
            if (result.success) {
                setPokemon(result.pokemon);
            } else {
                setError(result.error);
            }
        } catch (err) {
            setError(`Unexpected error: ${err.message}`);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div>
            <h1>Pokémon SDK Demo</h1>
            
            <div>
                <input
                    type="number"
                    value={pokemonId}
                    onChange={(e) => setPokemonId(parseInt(e.target.value))}
                    min="1"
                    max="1010"
                />
                <button 
                    onClick={() => fetchPokemon(pokemonId)}
                    disabled={loading || !sdkReady}
                >
                    {loading ? 'Loading...' : 'Get Pokémon'}
                </button>
            </div>
            
            {error && <div style={{ color: 'red' }}>{error}</div>}
            
            {pokemon && (
                <div>
                    <h2>{pokemon.name}</h2>
                    <p>ID: #{pokemon.id}</p>
                    <p>Height: {pokemon.height / 10}m</p>
                    <p>Weight: {pokemon.weight / 10}kg</p>
                    {pokemon.sprites.front_default && (
                        <img src={pokemon.sprites.front_default} alt={pokemon.name} />
                    )}
                </div>
            )}
        </div>
    );
};

export default PokemonComponent;
*/

export { pokemonSDK as default };