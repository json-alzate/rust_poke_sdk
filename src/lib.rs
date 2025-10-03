use serde::{Deserialize, Serialize};
use std::ffi::CString;
use std::os::raw::c_char;

// Estructura para representar un Pokémon
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Pokemon {
    pub id: u32,
    pub name: String,
    pub height: u32,
    pub weight: u32,
    pub base_experience: Option<u32>,
    pub sprites: PokemonSprites,
    pub types: Vec<PokemonType>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PokemonSprites {
    pub front_default: Option<String>,
    pub back_default: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PokemonType {
    pub slot: u32,
    #[serde(rename = "type")]
    pub type_info: TypeInfo,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TypeInfo {
    pub name: String,
    pub url: String,
}

// Resultado de la operación
#[derive(Debug, Serialize, Deserialize)]
pub struct PokemonResult {
    pub success: bool,
    pub pokemon: Option<Pokemon>,
    pub error: Option<String>,
}

// Función principal para obtener un Pokémon por ID
pub fn get_pokemon(id: u32) -> PokemonResult {
    match fetch_pokemon_sync(id) {
        Ok(pokemon) => PokemonResult {
            success: true,
            pokemon: Some(pokemon),
            error: None,
        },
        Err(err) => PokemonResult {
            success: false,
            pokemon: None,
            error: Some(err.to_string()),
        },
    }
}

// Función interna para hacer la petición HTTP
fn fetch_pokemon_sync(id: u32) -> Result<Pokemon, Box<dyn std::error::Error>> {
    let url = format!("https://pokeapi.co/api/v2/pokemon/{}", id);
    
    #[cfg(not(target_arch = "wasm32"))]
    {
        let response = reqwest::blocking::get(&url)?;
        let pokemon: Pokemon = response.json()?;
        Ok(pokemon)
    }
    
    #[cfg(target_arch = "wasm32")]
    {
        // Para WebAssembly, necesitaríamos usar async/await
        // Por simplicidad, retornamos un error por ahora
        let _ = url; // Usar la variable para evitar warning
        Err("WebAssembly support requires async implementation".into())
    }
}

// Función para Android/iOS que retorna un JSON string
// Esta función será llamada desde el código nativo
#[no_mangle]
pub extern "C" fn getPokemonJson(id: u32) -> *mut c_char {
    // Validar entrada
    if id == 0 || id > 1025 {
        let error_result = PokemonResult {
            success: false,
            pokemon: None,
            error: Some(format!("Invalid Pokemon ID: {}. Must be between 1 and 1025.", id)),
        };
        let json_string = serde_json::to_string(&error_result).unwrap_or_else(|_| 
            r#"{"success":false,"pokemon":null,"error":"Invalid ID and serialization error"}"#.to_string()
        );
        return match CString::new(json_string) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        };
    }

    let result = get_pokemon(id);
    let json_string = match serde_json::to_string(&result) {
        Ok(json) => json,
        Err(_) => {
            let error_result = PokemonResult {
                success: false,
                pokemon: None,
                error: Some("Failed to serialize result".to_string()),
            };
            serde_json::to_string(&error_result).unwrap_or_else(|_| 
                r#"{"success":false,"pokemon":null,"error":"Critical serialization error"}"#.to_string()
            )
        }
    };
    
    match CString::new(json_string) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => {
            // Si no podemos crear el CString, retornar un error básico
            let fallback = CString::new(r#"{"success":false,"pokemon":null,"error":"CString creation failed"}"#).unwrap();
            fallback.into_raw()
        }
    }
}

// Función para liberar memoria (importante para evitar memory leaks)
#[no_mangle]
pub extern "C" fn freeString(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

// Configuración para WebAssembly
#[cfg(target_arch = "wasm32")]
mod wasm {
    use super::*;
    use wasm_bindgen::prelude::*;
    use wasm_bindgen_futures::JsFuture;
    use web_sys::{Request, RequestInit, RequestMode, Response, window};
    use std::error::Error;
    use std::fmt;

    // Error personalizado para WebAssembly
    #[derive(Debug)]
    struct WasmError(String);

    impl fmt::Display for WasmError {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            write!(f, "{}", self.0)
        }
    }

    impl Error for WasmError {}

    #[wasm_bindgen]
    pub async fn get_pokemon_wasm(id: u32) -> JsValue {
        let result = fetch_pokemon_async(id).await;
        match result {
            Ok(pokemon) => {
                let success_result = PokemonResult {
                    success: true,
                    pokemon: Some(pokemon),
                    error: None,
                };
                serde_wasm_bindgen::to_value(&success_result).unwrap_or(JsValue::NULL)
            }
            Err(err) => {
                let error_result = PokemonResult {
                    success: false,
                    pokemon: None,
                    error: Some(err.to_string()),
                };
                serde_wasm_bindgen::to_value(&error_result).unwrap_or(JsValue::NULL)
            }
        }
    }

    async fn fetch_pokemon_async(id: u32) -> Result<Pokemon, Box<dyn std::error::Error>> {
        let url = format!("https://pokeapi.co/api/v2/pokemon/{}", id);
        
        let opts = RequestInit::new();
        opts.set_method("GET");
        opts.set_mode(RequestMode::Cors);

        let request = Request::new_with_str_and_init(&url, &opts)
            .map_err(|e| WasmError(format!("Failed to create request: {:?}", e)))?;
        
        let window = window().ok_or(WasmError("No global window object".to_string()))?;
        let resp_value = JsFuture::from(window.fetch_with_request(&request)).await
            .map_err(|e| WasmError(format!("Fetch failed: {:?}", e)))?;
        let resp: Response = resp_value.dyn_into()
            .map_err(|_| WasmError("Failed to convert response".to_string()))?;
        
        let json = JsFuture::from(resp.json().map_err(|e| WasmError(format!("Failed to get JSON: {:?}", e)))?)
            .await
            .map_err(|e| WasmError(format!("JSON parsing failed: {:?}", e)))?;
        
        let pokemon: Pokemon = serde_wasm_bindgen::from_value(json)
            .map_err(|e| WasmError(format!("Failed to deserialize Pokemon: {:?}", e)))?;
        
        Ok(pokemon)
    }
}

#[cfg(target_arch = "wasm32")]
pub use wasm::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_pokemon_structure() {
        // Test que verifica que la estructura funciona
        let result = get_pokemon(1); // Bulbasaur
        
        if result.success {
            assert!(result.pokemon.is_some());
            let pokemon = result.pokemon.unwrap();
            assert_eq!(pokemon.id, 1);
            assert_eq!(pokemon.name, "bulbasaur");
        } else {
            // En caso de error de red, solo verificamos que el error está presente
            assert!(result.error.is_some());
        }
    }

    #[test]
    fn test_pokemon_serialization() {
        let pokemon = Pokemon {
            id: 1,
            name: "bulbasaur".to_string(),
            height: 7,
            weight: 69,
            base_experience: Some(64),
            sprites: PokemonSprites {
                front_default: Some("https://example.com/front.png".to_string()),
                back_default: Some("https://example.com/back.png".to_string()),
            },
            types: vec![PokemonType {
                slot: 1,
                type_info: TypeInfo {
                    name: "grass".to_string(),
                    url: "https://pokeapi.co/api/v2/type/12/".to_string(),
                },
            }],
        };

        let result = PokemonResult {
            success: true,
            pokemon: Some(pokemon),
            error: None,
        };

        let json = serde_json::to_string(&result);
        assert!(json.is_ok());
    }
}

// Funciones JNI específicas para Android - Top-level functions (más simples)
#[cfg(target_os = "android")]
#[no_mangle]
pub extern "C" fn Java_com_example_androidxerpatestsdk_pokemon_PokemonSDKKt_pokemonSdkGetJson(
    _env: *mut std::os::raw::c_void,
    _class: *mut std::os::raw::c_void,
    id: std::os::raw::c_int,
) -> *mut c_char {
    // Llamar a la función original que hace la petición HTTP real
    getPokemonJson(id as u32)
}

// Función JNI para liberar memoria - CRÍTICA para evitar memory leaks
#[cfg(target_os = "android")]
#[no_mangle]
pub extern "C" fn Java_com_example_androidxerpatestsdk_pokemon_PokemonSDKKt_pokemonSdkFreeString(
    _env: *mut std::os::raw::c_void,
    _class: *mut std::os::raw::c_void,
    ptr: std::os::raw::c_long,
) {
    if ptr != 0 {
        freeString(ptr as *mut c_char);
    }
}
