// Ejemplo de uso del SDK en Android (Java)
// Este archivo debe ir en tu proyecto Android

package com.example.pokesdk;

import org.json.JSONObject;
import org.json.JSONException;

public class PokemonSDK {
    
    static {
        // Cargar la librería nativa
        System.loadLibrary("poke_sdk");
    }
    
    // Declaración de métodos nativos
    public static native String getPokemonJson(int id);
    public static native void freeString(long ptr);
    
    // Clase para representar un Pokémon
    public static class Pokemon {
        public int id;
        public String name;
        public int height;
        public int weight;
        public Integer baseExperience;
        public String frontSprite;
        public String backSprite;
        
        public Pokemon(JSONObject json) throws JSONException {
            this.id = json.getInt("id");
            this.name = json.getString("name");
            this.height = json.getInt("height");
            this.weight = json.getInt("weight");
            
            if (!json.isNull("base_experience")) {
                this.baseExperience = json.getInt("base_experience");
            }
            
            JSONObject sprites = json.getJSONObject("sprites");
            if (!sprites.isNull("front_default")) {
                this.frontSprite = sprites.getString("front_default");
            }
            if (!sprites.isNull("back_default")) {
                this.backSprite = sprites.getString("back_default");
            }
        }
        
        @Override
        public String toString() {
            return String.format("Pokemon{id=%d, name='%s', height=%d, weight=%d}", 
                               id, name, height, weight);
        }
    }
    
    // Resultado de la consulta
    public static class PokemonResult {
        public boolean success;
        public Pokemon pokemon;
        public String error;
        
        public PokemonResult(JSONObject json) throws JSONException {
            this.success = json.getBoolean("success");
            
            if (success && !json.isNull("pokemon")) {
                this.pokemon = new Pokemon(json.getJSONObject("pokemon"));
            }
            
            if (!success && !json.isNull("error")) {
                this.error = json.getString("error");
            }
        }
    }
    
    // Método principal para obtener un Pokémon
    public static PokemonResult getPokemon(int id) {
        try {
            String jsonString = getPokemonJson(id);
            if (jsonString == null) {
                return createErrorResult("Failed to get result from native code");
            }
            
            JSONObject json = new JSONObject(jsonString);
            return new PokemonResult(json);
            
        } catch (JSONException e) {
            return createErrorResult("Failed to parse JSON: " + e.getMessage());
        } catch (Exception e) {
            return createErrorResult("Unexpected error: " + e.getMessage());
        }
    }
    
    private static PokemonResult createErrorResult(String error) {
        PokemonResult result = new PokemonResult();
        result.success = false;
        result.error = error;
        return result;
    }
    
    // Constructor privado para crear resultado de error
    private static class PokemonResult {
        private PokemonResult() {}
    }
}

// Ejemplo de uso en una Activity
/*
public class MainActivity extends AppCompatActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        Button button = findViewById(R.id.buttonGetPokemon);
        button.setOnClickListener(v -> {
            // Ejecutar en background thread
            new Thread(() -> {
                PokemonSDK.PokemonResult result = PokemonSDK.getPokemon(1);
                
                // Volver al main thread para actualizar UI
                runOnUiThread(() -> {
                    if (result.success) {
                        Log.d("Pokemon", "Obtenido: " + result.pokemon.toString());
                        // Actualizar UI con los datos del Pokémon
                    } else {
                        Log.e("Pokemon", "Error: " + result.error);
                        // Mostrar error al usuario
                    }
                });
            }).start();
        });
    }
}
*/