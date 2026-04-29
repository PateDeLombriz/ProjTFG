// NO hi ha dependencies noves de Flutter.
//
// ## QUÈ FA I PER A QUÈ SERVEIX
// Shell de navegació del treballador autenticat. Equivalent a MainScaffold per a empresa.
// Proporciona el BottomNavigationBar flotant amb estil idèntic al d'empresa:
// arrodonit, ombra subtil, colors del tema Material 3 (scheme.*).
// Quatre pestanyes: Inici · Tasques · Obres · Perfil.
// Cada pàgina gestiona el seu propi Scaffold + AppBar; aquest widget
// únicament orquestra la navegació inferior.
// Per a: treballador autenticat.
// Activa: TreballadorHomeScreen, TreballadorTasquesScreen,
//         TreballadorObresScreen, TreballadorProfileScreen (perfil propi).

import 'package:flutter/material.dart';
import 'package:front_end/screens/treballador/treballador_home_screen.dart';
import 'package:front_end/screens/treballador/treballador_tasques_screen.dart';
import 'package:front_end/screens/treballador/treballador_obres_screen.dart';
import 'package:front_end/screens/treballador/perfil_treb.dart';

class TreballadorMainScaffold extends StatefulWidget {
  const TreballadorMainScaffold({super.key});

  @override
  State<TreballadorMainScaffold> createState() =>
      _TreballadorMainScaffoldState();
}

class _TreballadorMainScaffoldState extends State<TreballadorMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TreballadorHomeScreen(),
    TreballadorTasquesScreen(),
    TreballadorObresScreen(),
    TreballadorProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Inici',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment_rounded),
      label: 'Tasques',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.location_city_outlined),
      activeIcon: Icon(Icons.location_city_rounded),
      label: 'Obres',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _pages[_currentIndex],

      // ───────────── BottomNavigationBar flotant (estil empresa) ─────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              items: _navItems,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: scheme.surface,
              elevation: 0,
              selectedItemColor: scheme.primary,
              unselectedItemColor: scheme.onSurfaceVariant,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              showUnselectedLabels: true,
            ),
          ),
        ),
      ),
    );
  }
}
