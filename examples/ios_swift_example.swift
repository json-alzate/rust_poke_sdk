// Ejemplo de uso del SDK en iOS (Swift)
// Este archivo debe ir en tu proyecto iOS

import Foundation

// Importar las funciones C
// Asegúrate de que poke_sdk.h esté incluido en el bridging header

class PokemonSDK {
    
    // Estructura para representar un Pokémon
    struct Pokemon: Codable {
        let id: Int
        let name: String
        let height: Int
        let weight: Int
        let baseExperience: Int?
        let sprites: Sprites
        let types: [PokemonType]
        
        struct Sprites: Codable {
            let frontDefault: String?
            let backDefault: String?
            
            enum CodingKeys: String, CodingKey {
                case frontDefault = "front_default"
                case backDefault = "back_default"
            }
        }
        
        struct PokemonType: Codable {
            let slot: Int
            let type: TypeInfo
            
            enum CodingKeys: String, CodingKey {
                case slot
                case type
            }
        }
        
        struct TypeInfo: Codable {
            let name: String
            let url: String
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, height, weight, sprites, types
            case baseExperience = "base_experience"
        }
    }
    
    // Estructura para el resultado
    struct PokemonResult: Codable {
        let success: Bool
        let pokemon: Pokemon?
        let error: String?
    }
    
    // Enum para manejar el resultado de manera más Swift-like
    enum Result {
        case success(Pokemon)
        case failure(String)
    }
    
    // Método principal para obtener un Pokémon
    static func getPokemon(id: Int, completion: @escaping (Result) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let result = getPokemonSync(id: id)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // Método síncrono
    static func getPokemonSync(id: Int) -> Result {
        // Llamar a la función C
        guard let jsonCString = get_pokemon_json(UInt32(id)) else {
            return .failure("Failed to get result from native code")
        }
        
        // Convertir C string a Swift String
        let jsonString = String(cString: jsonCString)
        
        // Liberar la memoria del C string
        free_string(jsonCString)
        
        // Parsear JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure("Failed to convert result to data")
        }
        
        do {
            let pokemonResult = try JSONDecoder().decode(PokemonResult.self, from: jsonData)
            
            if pokemonResult.success, let pokemon = pokemonResult.pokemon {
                return .success(pokemon)
            } else {
                let errorMessage = pokemonResult.error ?? "Unknown error"
                return .failure(errorMessage)
            }
        } catch {
            return .failure("Failed to parse JSON: \(error.localizedDescription)")
        }
    }
    
    // Versión async/await (iOS 13+)
    @available(iOS 13.0, *)
    static func getPokemon(id: Int) async -> Result {
        return await withCheckedContinuation { continuation in
            getPokemon(id: id) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

// Ejemplo de uso en un ViewController
/*
class ViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var getPokemonButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func getPokemonButtonTapped(_ sender: UIButton) {
        // Deshabilitar botón mientras se carga
        getPokemonButton.isEnabled = false
        getPokemonButton.setTitle("Cargando...", for: .normal)
        
        // Obtener Pokémon (ejemplo: Pikachu - ID 25)
        PokemonSDK.getPokemon(id: 25) { [weak self] result in
            guard let self = self else { return }
            
            // Re-habilitar botón
            self.getPokemonButton.isEnabled = true
            self.getPokemonButton.setTitle("Obtener Pokémon", for: .normal)
            
            switch result {
            case .success(let pokemon):
                self.updateUI(with: pokemon)
            case .failure(let error):
                self.showError(error)
            }
        }
    }
    
    private func updateUI(with pokemon: PokemonSDK.Pokemon) {
        nameLabel.text = pokemon.name.capitalized
        idLabel.text = "ID: \(pokemon.id)"
        heightLabel.text = "Altura: \(pokemon.height)"
        weightLabel.text = "Peso: \(pokemon.weight)"
        
        // Cargar imagen si existe
        if let frontSpriteURL = pokemon.sprites.frontDefault,
           let url = URL(string: frontSpriteURL) {
            loadImage(from: url)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self.pokemonImageView.image = image
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", 
                                    message: message, 
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Ejemplo usando async/await (iOS 13+)
@available(iOS 13.0, *)
extension ViewController {
    
    @IBAction func getPokemonWithAsyncAwait(_ sender: UIButton) {
        Task {
            getPokemonButton.isEnabled = false
            getPokemonButton.setTitle("Cargando...", for: .normal)
            
            let result = await PokemonSDK.getPokemon(id: 25)
            
            getPokemonButton.isEnabled = true
            getPokemonButton.setTitle("Obtener Pokémon", for: .normal)
            
            switch result {
            case .success(let pokemon):
                updateUI(with: pokemon)
            case .failure(let error):
                showError(error)
            }
        }
    }
}
*/