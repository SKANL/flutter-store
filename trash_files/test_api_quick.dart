import 'dart:io';

void main() async {
  print('🔍 Verificando API C# - Test Inmediato');
  print('=====================================');
  
  try {
    print('Verificando puerto 5041...');
    
    // Intentar conectar al puerto
    final socket = await Socket.connect('localhost', 5041, timeout: Duration(seconds: 3));
    socket.destroy();
    
    print('✅ Puerto 5041 está ABIERTO y escuchando');
    print('🎉 Tu API C# está ejecutándose correctamente');
    
  } catch (e) {
    print('❌ Puerto 5041 NO está disponible');
    print('🚨 PROBLEMA: Tu API C# NO está ejecutándose');
    print('');
    print('💡 SOLUCIÓN INMEDIATA:');
    print('1. Ve a tu proyecto de API C#');
    print('2. Ejecuta: dotnet run');
    print('3. Verifica que aparezca: "Now listening on: http://localhost:5041"');
    print('4. Luego vuelve a probar tu app Flutter');
  }
}
