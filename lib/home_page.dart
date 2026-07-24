import 'package:flutter/material.dart';
import 'admin/login_page.dart';
import 'widgets/calculator_container.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 14, 14, 14),
          flexibleSpace: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Flexible(
                  child: Image.asset(
                    'assets/logo.png',
                    scale: 2,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white.withOpacity(0.95),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: const Center(
          child: CalculatorContainer(),
        ),
      ),
    );
  }
}
