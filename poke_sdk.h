#ifndef POKE_SDK_H
#define POKE_SDK_H

#ifdef __cplusplus
extern "C" {
#endif

// Función principal que obtiene un Pokémon por ID y retorna JSON
// El caller debe llamar a free_string() para liberar la memoria
char* get_pokemon_json(unsigned int id);

// Función para liberar la memoria del string retornado
void free_string(char* ptr);

#ifdef __cplusplus
}
#endif

#endif // POKE_SDK_H