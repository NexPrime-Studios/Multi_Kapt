import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mudámos o nome do teste para algo que faça sentido no nosso projeto
  testWidgets('Teste de carregamento da Home do Cliente', (
    WidgetTester tester,
  ) async {
    // 1. Constrói o app (O DecisorDePlataforma vai rodar aqui)
    // Nota: Como o teste roda num ambiente simulado, ele costuma assumir um ecrã pequeno (Mobile)
    //await tester.pumpWidget(const MaterialApp(home: DecisorDePlataforma()));

    // 2. Verifica se o título da AppBar aparece no ecrã
    // Mudámos de procurar '0' para procurar o texto que escrevemos na AppBar
    expect(find.text('Escolha um Mercado'), findsOneWidget);

    // 3. Verifica se existe um campo de pesquisa (TextField)
    expect(find.byType(TextField), findsOneWidget);

    // 4. Verifica se existe o ícone de busca
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
