import 'package:flutter/material.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people, 
              size: screenWidth * 0.25, // 25% del ancho
              color: Colors.blue,
            ),
            SizedBox(height: screenHeight * 0.02), // 2% de la altura
            Text(
              'Gestión de Clientes',
              style: TextStyle(
                fontSize: screenWidth * 0.06, // 6% del ancho
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // 10% del ancho
              child: Text(
                'Aquí podrás gestionar todos tus clientes',
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // 4% del ancho
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar agregar cliente
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
