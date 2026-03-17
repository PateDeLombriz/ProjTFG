import 'package:flutter/material.dart';
import 'package:front_end/screens/empresa/home_empresa.dart';
import 'package:front_end/screens/obra_screens/obra_form.dart';
import 'package:front_end/screens/empresa/tasquesList_screen.dart';
import 'package:front_end/screens/empresa/recursosList_screen.dart';
import 'package:front_end/screens/empresa/tasca_form.dart';
import 'package:front_end/screens/empresa/inc_sol_form.dart';
import 'package:front_end/screens/empresa/solicRec_form.dart';
import 'package:front_end/screens/empresa/doc_form.dart';
import 'package:front_end/screens/empresa/treballador_form.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeEmpresa(),
    TasquesScreen(),
    RecursosScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Obres'),
    BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), label: 'Tasques'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Recursos'),

  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Fons suau coherent amb pantalles (surface / surfaceVariant lleuger)
    final scaffoldBg = scheme.surface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _pages[_currentIndex],

      // ───────────── BottomNavigationBar estilitzat ─────────────
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

      // ───────────── FAB global amb menú coherent ─────────────
      floatingActionButton: _FabMenu(onSelected: _handleFabAction),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _handleFabAction(_FabItem item) {
    switch (item) {
      case _FabItem.obra:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ObraForm()));
        break;
      case _FabItem.tasca:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TascaFormScreen()));
        break;
      case _FabItem.incidencia:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidenciaFormScreen()));
        break;
      case _FabItem.solRec:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SolRecursFormScreen()));
        break;
      case _FabItem.document:
        // TODO: passa l'obraId real
        Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentObraScreen(obraId: 1)));
        break;
      case _FabItem.treballador:
        // TODO: passa l'obraId real
        Navigator.push(context, MaterialPageRoute(builder: (_) => TreballadorForm()));
    }
  }
}

/* ───────────────────────── FAB amb PopupMenu ───────────────────────── */

class _FabMenu extends StatelessWidget {
  const _FabMenu({required this.onSelected});
  final void Function(_FabItem) onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox?;
        final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final position = RelativeRect.fromRect(
          (box?.semanticBounds ?? Rect.zero)
              .shift(box?.localToGlobal(Offset.zero) ?? Offset.zero)
              .inflate(0),
          Offset.zero & overlay.size,
        );

        final selected = await showMenu<_FabItem>(
          context: context,
          position: position,
          surfaceTintColor: scheme.surfaceTint,
          items: [
            _menuItem(context, _FabItem.obra,       Icons.add_home_work_outlined,           'Crea Obra'),
            _menuItem(context, _FabItem.tasca,      Icons.task_alt_outlined,  'Crea Tasca'),
            _menuItem(context, _FabItem.incidencia, Icons.report_gmailerrorred_outlined, 'Crea Incidència'),
            _menuItem(context, _FabItem.solRec,     Icons.inventory_outlined, 'Sol·licita Recurs'),
            _menuItem(context, _FabItem.document,   Icons.drive_folder_upload_outlined, 'Afegeix Document'),
            _menuItem(context, _FabItem.treballador,Icons.add_reaction_outlined, 'Crea Treballador'),

          ],
        );

        if (selected != null) onSelected(selected);
      },
      tooltip: 'Crear',
      child: const Icon(Icons.add),
    );
  }

  PopupMenuItem<_FabItem> _menuItem(
    BuildContext context,
    _FabItem value,
    IconData icon,
    String text,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem<_FabItem>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Enum accions ───────────────────────── */
enum _FabItem { obra, tasca, incidencia, solRec, document, treballador }
