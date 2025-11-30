import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE46B3F);
    const primaryLight = Color(0xFFC47A69);
    const bgLight = Color(0xFFF8F6F6);
    const surfaceLight = Color(0xFFF3EBE8);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header (logo)
              const SizedBox(height: 32),
              Center(
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    size: 40,
                    color: primaryLight,
                  ),
                ),
              ),

              // Ilustração + título
              Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            // mesma imagem do HTML
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCnQtNZvYhEvjiy8qRfWdbQ-RuqJDWut81y89FkkbjSOOueoSNxuA-HkLzPRgQmhtw8erod5j5rlHGPRUJGu2y1xIy6uCuuWQTTReKSSrwDDdtlt5Ho4BB8RZuLk5sLxssIrLsDEJqNSVMtMylPpYpjxNbEpiFkIm2qk_227whsgn8VunvIll-cetimA5mc3_HrG-QEUVeokaj7jVzFoMyTm8hAtjoxLwMU4BK7k47UDVzzxEe8cI5TvIBJ3QFID2lDpQpl7D2z9UzZ',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Avalie imóveis e bairros de Jaraguá do Sul',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B120E),
                        ),
                  ),
                ],
              ),

              // Botões
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryLight,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: surfaceLight,
                        foregroundColor: const Color(0xFF211A18),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('Criar conta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
