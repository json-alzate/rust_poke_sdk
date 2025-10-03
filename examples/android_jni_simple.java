// Ejemplo simple de integración JNI en Android

public class PokeSDK {
    
    static {
        System.loadLibrary("poke_sdk");
    }
    
    // Declaraciones de métodos nativos con nombres corregidos
    public static native String getPokemonJson(int id);
    public static native void freeString(long ptr);
    
    // Método de conveniencia
    public static String getPokemon(int id) {
        return getPokemonJson(id);
    }
}

// Ejemplo de uso en Activity
public class MainActivity extends AppCompatActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        Button button = findViewById(R.id.button);
        TextView textView = findViewById(R.id.textView);
        
        button.setOnClickListener(v -> {
            // ✅ Ahora funciona correctamente con JNI
            String result = PokeSDK.getPokemon(25); // Pikachu
            textView.setText(result);
        });
    }
}