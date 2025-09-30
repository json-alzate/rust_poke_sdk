// Ejemplo de uso del SDK en Android (Kotlin)
// Este archivo debe ir en tu proyecto Android

package com.example.pokesdk

import org.json.JSONObject
import org.json.JSONException
import kotlinx.coroutines.*

object PokemonSDK {
    
    init {
        // Cargar la librería nativa
        System.loadLibrary("poke_sdk")
    }
    
    // Declaración de métodos nativos
    private external fun getPokemonJson(id: Int): String?
    private external fun freeString(ptr: Long)
    
    // Data class para representar un Pokémon
    data class Pokemon(
        val id: Int,
        val name: String,
        val height: Int,
        val weight: Int,
        val baseExperience: Int?,
        val frontSprite: String?,
        val backSprite: String?
    ) {
        companion object {
            fun fromJson(json: JSONObject): Pokemon {
                return Pokemon(
                    id = json.getInt("id"),
                    name = json.getString("name"),
                    height = json.getInt("height"),
                    weight = json.getInt("weight"),
                    baseExperience = if (json.isNull("base_experience")) null else json.getInt("base_experience"),
                    frontSprite = json.getJSONObject("sprites").optString("front_default", null),
                    backSprite = json.getJSONObject("sprites").optString("back_default", null)
                )
            }
        }
    }
    
    // Sealed class para el resultado
    sealed class PokemonResult {
        data class Success(val pokemon: Pokemon) : PokemonResult()
        data class Error(val message: String) : PokemonResult()
    }
    
    // Método suspendido para usar con coroutines
    suspend fun getPokemon(id: Int): PokemonResult = withContext(Dispatchers.IO) {
        try {
            val jsonString = getPokemonJson(id)
                ?: return@withContext PokemonResult.Error("Failed to get result from native code")
            
            val json = JSONObject(jsonString)
            val success = json.getBoolean("success")
            
            if (success) {
                val pokemonJson = json.getJSONObject("pokemon")
                val pokemon = Pokemon.fromJson(pokemonJson)
                PokemonResult.Success(pokemon)
            } else {
                val error = json.optString("error", "Unknown error")
                PokemonResult.Error(error)
            }
            
        } catch (e: JSONException) {
            PokemonResult.Error("Failed to parse JSON: ${e.message}")
        } catch (e: Exception) {
            PokemonResult.Error("Unexpected error: ${e.message}")
        }
    }
    
    // Método síncrono (para compatibilidad)
    fun getPokemonSync(id: Int): PokemonResult {
        return runBlocking {
            getPokemon(id)
        }
    }
}

// Ejemplo de uso en una Activity con coroutines
/*
class MainActivity : AppCompatActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        val button = findViewById<Button>(R.id.buttonGetPokemon)
        button.setOnClickListener {
            // Usar coroutines para la llamada asíncrona
            lifecycleScope.launch {
                val result = PokemonSDK.getPokemon(1) // Bulbasaur
                
                when (result) {
                    is PokemonSDK.PokemonResult.Success -> {
                        Log.d("Pokemon", "Obtenido: ${result.pokemon}")
                        // Actualizar UI con los datos del Pokémon
                        updateUI(result.pokemon)
                    }
                    is PokemonSDK.PokemonResult.Error -> {
                        Log.e("Pokemon", "Error: ${result.message}")
                        // Mostrar error al usuario
                        showError(result.message)
                    }
                }
            }
        }
    }
    
    private fun updateUI(pokemon: PokemonSDK.Pokemon) {
        // Actualizar la interfaz con los datos del Pokémon
        findViewById<TextView>(R.id.textPokemonName).text = pokemon.name.capitalize()
        findViewById<TextView>(R.id.textPokemonId).text = "ID: ${pokemon.id}"
        findViewById<TextView>(R.id.textPokemonHeight).text = "Altura: ${pokemon.height}"
        findViewById<TextView>(R.id.textPokemonWeight).text = "Peso: ${pokemon.weight}"
        
        // Cargar imagen si existe
        pokemon.frontSprite?.let { url ->
            // Usar tu librería de imágenes favorita (Glide, Picasso, etc.)
            // Glide.with(this).load(url).into(findViewById(R.id.imagePokemon))
        }
    }
    
    private fun showError(message: String) {
        Toast.makeText(this, "Error: $message", Toast.LENGTH_LONG).show()
    }
}
*/