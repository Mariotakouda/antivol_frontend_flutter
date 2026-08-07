// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:antivole/screens/auth/splash_screen.dart';
import 'package:antivole/providers/auth_provider.dart';

/// Le test original était le "counter" par défaut. L'app réelle affiche
/// un `SplashScreen` qui redirige vers l'écran de connexion ou d'accueil.
///
/// Ici on remplace `AuthProvider` par une version de test qui ne fait
/// rien dans `verifierSessionExistante()` afin d'éviter les appels réseau
/// et on vérifie que la navigation aboutit bien à l'écran de connexion.
class TestAuthProvider extends AuthProvider {
  @override
  Future<void> verifierSessionExistante() async {
    // Ne rien faire pour les tests; laisse l'état par défaut (non connecté).
    return;
  }
}

void main() {
  testWidgets('SplashScreen navigates to LoginScreen when not connected', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => TestAuthProvider(),
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Lancer la navigation post-frame et attendre que tout se stabilise.
    await tester.pumpAndSettle();

    // Le LoginScreen contient le texte 'Bon retour' -> vérifier sa présence.
    expect(find.text('Bon retour'), findsOneWidget);
  });
}
