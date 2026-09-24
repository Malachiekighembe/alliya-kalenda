import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/animations.dart';
import 'core/colors.dart';
import 'core/formatting.dart';
import 'core/project_cover.dart';
import 'data/local_store.dart';
import 'domain/models.dart';
import 'features_pages.dart';
import 'messages_page.dart';

class AlliyaKalendaApp extends StatefulWidget {
  const AlliyaKalendaApp({super.key});
  @override
  State<AlliyaKalendaApp> createState() => _AlliyaKalendaAppState();
}

class _AlliyaKalendaAppState extends State<AlliyaKalendaApp> {
  late final Future<SharedPreferences> _preferences = _initialize();

  Future<SharedPreferences> _initialize() async {
    final results = await Future.wait<dynamic>([
      SharedPreferences.getInstance(),
      ensureDateFormatting(),
      Future<void>.delayed(const Duration(milliseconds: 850)),
    ]);
    return results.first as SharedPreferences;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.light(
      primary: kNavy,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xffd9e8f7),
      onPrimaryContainer: kNavy,
      secondary: kAccent,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xffd9e6fb),
      onSecondaryContainer: const Color(0xff0b2240),
      tertiary: kAmber,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xffffe3c2),
      onTertiaryContainer: const Color(0xff4a2405),
      surface: Colors.white,
      onSurface: const Color(0xff16202c),
      surfaceContainerHighest: kSurfaceHigh,
      surfaceContainerLow: const Color(0xffeef3f7),
      onSurfaceVariant: const Color(0xff5a6b7a),
      outline: const Color(0xffc3cfdc),
      outlineVariant: const Color(0xffe3eaf1),
      error: const Color(0xffc8453a),
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displaySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        titleSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      ),
      scaffoldBackgroundColor: kAppBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: kAppBackground,
        surfaceTintColor: Colors.transparent,
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: const Color(0x222e6fd6),
      dividerTheme: const DividerThemeData(
        color: kCardBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x140b2240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: kCardBorder, width: .6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 62,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        minWidth: 64,
        backgroundColor: kNavy,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: Color(0xa6ffffff)),
        labelType: NavigationRailLabelType.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kNavy,
          side: const BorderSide(color: kAccent, width: 1.4),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kNavy,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kNavy,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
            bottom: Radius.zero,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alliya Kalenda',
      theme: theme,
      home: FutureBuilder<SharedPreferences>(
        future: _preferences,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const _SplashScreen();
          return AppShell(store: LocalStore(snapshot.data!));
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kNavy,
    body: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .82, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/branding/Alliya-Kalenda-app-icon-bigA-calendar-1024-rounded.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Alliya Kalenda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre chantier, en mouvement.',
              style: TextStyle(color: Color(0xff9bd8cf), fontSize: 14),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: kAccent),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({required this.store, super.key});
  final LocalStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  bool railExpanded = false;
  static const labels = [
    'Dashboard',
    'Agenda',
    'Projets',
    'Messages',
    'Personnes',
    'Finances',
    'Rapports',
    'Paramètres',
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, child) => Scaffold(
        body: Row(
          children: [
            if (wide)
              _NavigationRail(
                index: index,
                expanded: railExpanded,
                onSelect: _select,
                onToggle: () => setState(() => railExpanded = !railExpanded),
              ),
            Expanded(
              child: Column(
                children: [
                  _Toolbar(
                    label: labels[index],
                    actionLabel: _actionLabel,
                    onAdd: _toolbarAction(context),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(.035, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(index),
                        child: _content(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: index == 0
                    ? 0
                    : index == 2
                    ? 1
                    : index == 3
                    ? 2
                    : 3,
                onDestinationSelected: (value) => value == 0
                    ? _select(0)
                    : value == 1
                    ? _select(2)
                    : value == 2
                    ? _select(3)
                    : _showMoreMenu(context),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view),
                    label: 'Accueil',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.apartment),
                    label: 'Projets',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz),
                    label: 'Plus',
                  ),
                ],
              ),
      ),
    );
  }

  void _select(int value) => setState(() => index = value);

  String? get _actionLabel => switch (index) {
    2 => 'Nouveau projet',
    1 => 'Ajouter activité',
    4 => 'Ajouter personne',
    5 => 'Ajouter dépense',
    6 => 'Nouveau rapport',
    _ => null,
  };

  VoidCallback? _toolbarAction(BuildContext context) {
    if (index == 2) return () => _showAddProject(context);
    if (_actionLabel == null) return null;
    return () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Le formulaire « $_actionLabel » sera bientôt disponible.',
        ),
      ),
    );
  }

  Widget _content() {
    switch (index) {
      case 0:
        return DashboardPage(
          store: widget.store,
          onProjects: () => _select(2),
          onMessages: () => _select(3),
          onAgenda: () => _select(1),
        );
      case 1:
        return const AgendaPage();
      case 2:
        return ProjectsPage(
          store: widget.store,
          onAdd: () => _showAddProject(context),
        );
      case 3:
        return MessagesPage(store: widget.store);
      case 4:
        return const PeoplePage();
      case 5:
        return FinancePage(store: widget.store);
      case 6:
        return const ReportsPage();
      default:
        return const SettingsPage();
    }
  }

  Future<void> _showAddProject(BuildContext context) async {
    final name = TextEditingController();
    final client = TextEditingController();
    final location = TextEditingController(text: 'Kinshasa');
    final amount = TextEditingController();
    var selectedCover = kProjectCovers.first;
    var status = ProjectStatus.planned;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau projet de chantier'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nom du chantier *',
                      hintText: 'ex. Résidence Bandalungwa',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: client,
                    decoration: const InputDecoration(
                      labelText: 'Client ou maître d’ouvrage',
                      hintText: 'ex. M. Mukendi',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Localisation',
                      hintText: 'ex. Gombe, Kinshasa',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant du contrat (\$)',
                      hintText: 'ex. 45000',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Photo de couverture',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kProjectCovers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cover = kProjectCovers[index];
                        final isSelected = cover == selectedCover;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedCover = cover),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? kAccent : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ProjectCover(source: cover),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () {
                final trimmed = name.text.trim();
                if (trimmed.isEmpty) return;
                final parsedAmount = double.tryParse(amount.text.replaceAll(' ', '')) ?? 0;
                widget.store.addProject(
                  name: trimmed,
                  client: client.text.trim().isEmpty ? 'Client non renseigné' : client.text.trim(),
                  location: location.text.trim().isEmpty ? 'Kinshasa' : location.text.trim(),
                  contractAmount: parsedAmount,
                  status: status,
                  imageUrl: selectedCover,
                );
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Créer le chantier'),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Chantier ajouté avec succès')),
      );
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Autres espaces',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                for (final item in [
                  (
                    1,
                    Icons.calendar_month_rounded,
                    'Agenda',
                    'Planning du chantier',
                  ),
                  (4, Icons.groups_outlined, 'Personnes', 'Équipe et contacts'),
                  (
                    5,
                    Icons.account_balance_wallet_outlined,
                    'Finances',
                    'Paiements et solde',
                  ),
                  (
                    6,
                    Icons.description_outlined,
                    'Rapports',
                    'Briefs journaliers',
                  ),
                  (7, Icons.settings_outlined, 'Paramètres', 'Préférences'),
                ])
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: item.$1 == index
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _select(item.$1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                item.$2,
                                size: 17,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    item.$4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.index,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });
  final int index;
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) => NavigationRail(
    backgroundColor: kNavy,
    extended: expanded,
    selectedIndex: index,
    onDestinationSelected: onSelect,
    labelType: expanded ? null : NavigationRailLabelType.selected,
    leading: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            child: Image.asset(
              'assets/branding/Alliya-Kalenda-app-icon-bigA-calendar-1024-rounded.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ALLIYA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: onToggle,
            tooltip: expanded ? 'Réduire le menu' : 'Agrandir le menu',
            style: IconButton.styleFrom(foregroundColor: Colors.white70),
            icon: Icon(
              expanded
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    ),
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.grid_view, color: Colors.white70),
        selectedIcon: Icon(Icons.grid_view, color: Colors.white),
        label: Text('Dashboard', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calendar_month, color: Colors.white70),
        selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
        label: Text('Agenda', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.apartment, color: Colors.white70),
        selectedIcon: Icon(Icons.apartment, color: Colors.white),
        label: Text('Projets', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.forum_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.forum, color: Colors.white),
        label: Text('Messages', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.groups, color: Colors.white70),
        selectedIcon: Icon(Icons.groups, color: Colors.white),
        label: Text('Personnes', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.account_balance_wallet, color: Colors.white70),
        selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.white),
        label: Text('Finances', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.description, color: Colors.white70),
        selectedIcon: Icon(Icons.description, color: Colors.white),
        label: Text('Rapports', style: TextStyle(color: Colors.white)),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings, color: Colors.white70),
        selectedIcon: Icon(Icons.settings, color: Colors.white),
        label: Text('Paramètres', style: TextStyle(color: Colors.white)),
      ),
    ],
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.label, this.actionLabel, this.onAdd});
  final String label;
  final String? actionLabel;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            12,
            compact ? 12 : 16,
            4,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 4,
                height: 26,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Alliya Kalenda · espace de travail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[_SyncPill(), const SizedBox(width: 12)],
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded, size: 19),
                tooltip: 'Rechercher',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 2),
                compact
                    ? IconButton.filled(
                        onPressed: onAdd,
                        tooltip: actionLabel,
                        icon: const Icon(Icons.add_rounded, size: 18),
                      )
                    : FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(actionLabel!),
                      ),
              ],
              const SizedBox(width: 8),
              const _Avatar(),
            ],
          ),
        );
      },
    );
  }
}

/// Small indicator reflecting the local-first sync state.
class _SyncPill extends StatelessWidget {
  const _SyncPill();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xffe2eafb),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: 8,
              height: 8,
              child: ColoredBox(color: const Color(0xff2e6fd6)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Synchronisé',
            style: TextStyle(
              color: const Color(0xff1d4f9e),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Current user avatar with initials.
class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.primary,
      child: Text(initials('Malachie Kighembe')),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.store,
    required this.onProjects,
    required this.onMessages,
    required this.onAgenda,
    super.key,
  });
  final LocalStore store;
  final VoidCallback onProjects;
  final VoidCallback onMessages;
  final VoidCallback onAgenda;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (store.projects.isNotEmpty) ...[
        AnimatedReveal(
          child: _DashboardHero(
            project: store.projects.first,
            onOpenProjects: onProjects,
          ),
        ),
        const SizedBox(height: 12),
      ],
      AnimatedReveal(
        delay: const Duration(milliseconds: 80),
        child: _Panel(
          title: 'Progression des projets',
          icon: Icons.trending_up_rounded,
          action: TextButton(
            onPressed: onProjects,
            child: const Text('Voir tout'),
          ),
          children: [
            for (final project in store.projects) _Progress(project: project),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _QuickActions(
        onProjects: onProjects,
        onMessages: onMessages,
        onAgenda: onAgenda,
      ),
      const SizedBox(height: 14),
      AnimatedReveal(child: _Stats(store: store)),
      const SizedBox(height: 16),
      AnimatedReveal(
        delay: const Duration(milliseconds: 160),
        child: _CompactPanel(
          title: 'Activités du jour',
          icon: Icons.event_available_rounded,
          children: [
            for (final item in store.activities)
              _CompactRow(
                leadingIcon: Icons.schedule_rounded,
                title: item.title,
                subtitle: '${item.time} · ${item.project}',
                status: item.status,
              ),
          ],
        ),
      ),
      AnimatedReveal(
        delay: const Duration(milliseconds: 240),
        child: _CompactPanel(
          title: 'Paiements récents',
          icon: Icons.payments_outlined,
          children: [
            for (final item in store.payments)
              _CompactRow(
                leadingIcon: Icons.payments_outlined,
                title: item.project,
                subtitle: '${item.date} · ${item.method}',
                trailing: Text(
                  money(item.amount),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Lightweight panel: dense icon+text rows instead of full-height ListTiles.
class _CompactPanel extends StatelessWidget {
  const _CompactPanel({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.status,
  });
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.primary,
            child: Icon(leadingIcon, size: 14),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 7),
            trailing!,
          ] else if (status != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  status!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onProjects,
    required this.onMessages,
    required this.onAgenda,
  });

  final VoidCallback onProjects;
  final VoidCallback onMessages;
  final VoidCallback onAgenda;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _QuickAction(
          label: 'Projets',
          icon: Icons.apartment_rounded,
          onPressed: onProjects,
          filled: true,
        ),
        const SizedBox(width: 10),
        _QuickAction(
          label: 'Brief équipe',
          icon: Icons.forum_rounded,
          onPressed: onMessages,
        ),
        const SizedBox(width: 10),
        _QuickAction(
          label: 'Agenda',
          icon: Icons.calendar_month_rounded,
          onPressed: onAgenda,
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => filled
      ? FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        )
      : OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        );
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.project, required this.onOpenProjects});

  final Project project;
  final VoidCallback onOpenProjects;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 226),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Real project photo, full bleed.
          Positioned.fill(child: ProjectCover(source: project.imageUrl)),
          // Light scrim: transparent on top so the photo reads clearly, darker
          // at the bottom where the title and progress bar sit.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kNavy.withValues(alpha: .1),
                    kNavy.withValues(alpha: .32),
                    kNavy.withValues(alpha: .74),
                  ],
                  stops: const [0, .44, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroTag(status: project.status),
                const SizedBox(height: 12),
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${project.client} · ${project.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: project.progress / 100),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                minHeight: 6,
                                value: value,
                                backgroundColor: Colors.white24,
                                color: kAccent,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${project.progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Échéance : ${formatDate(project.plannedEnd)} · ${deadlineHint(project.plannedEnd)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenProjects,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Voir le projet'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Status chip sitting on top of the hero photo.
class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ProjectStatus.active => 'Actif',
      ProjectStatus.completed => 'Terminé',
      ProjectStatus.planned => 'Planifié',
      ProjectStatus.paused => 'En pause',
      ProjectStatus.cancelled => 'Annulé',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xff8fd0ff),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label · à la une',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.store});
  final LocalStore store;
  @override
  Widget build(BuildContext context) {
    final specs = [
      _StatSpec(
        label: 'Projets actifs',
        value: store.activeProjects.toDouble(),
        icon: Icons.pending_actions_outlined,
        color: kAccent,
      ),
      _StatSpec(
        label: 'Activités du jour',
        value: store.activities.length.toDouble(),
        icon: Icons.event_available_rounded,
        color: kAmber,
      ),
      _StatSpec(
        label: 'Total reçu',
        value: store.totalReceived,
        icon: Icons.south_west_rounded,
        color: const Color(0xff2f7dd9),
      ),
      _StatSpec(
        label: 'Dépenses',
        value: store.totalExpenses,
        icon: Icons.north_east_rounded,
        color: const Color(0xffd1524f),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 82,
          children: [
            for (var i = 0; i < specs.length; i++)
              AnimatedReveal(
                delay: Duration(milliseconds: i * 70),
                child: _StatTile(spec: specs[i]),
              ),
          ],
        );
      },
    );
  }
}

class _StatSpec {
  const _StatSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.spec});
  final _StatSpec spec;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCount = spec.value == spec.value.roundToDouble();
    final formatter = isCount ? (value) => value.round().toString() : money;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.2,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: spec.color.withValues(alpha: .14),
                  foregroundColor: spec.color,
                  child: Icon(spec.icon, size: 13),
                ),
              ],
            ),
            const SizedBox(height: 5),
            AnimatedCounter(value: spec.value, formatter: formatter),
          ],
        ),
      ),
    );
  }
}

/// Dashboard row for one project: real chantier photo + progress.
class _Progress extends StatelessWidget {
  const _Progress({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 64,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The chantier photo — the card must read as a picture and
                  // not as a flat colour block.
                  ProjectCover(source: project.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          kNavy.withValues(alpha: .78),
                        ],
                        stops: const [.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5,
                    bottom: 4,
                    child: Text(
                      '${project.progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${project.client} · ${deadlineHint(project.plannedEnd)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: project.progress / 100),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      minHeight: 6,
                      value: value,
                      color: kAccent,
                      backgroundColor: kSurfaceHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.children,
    this.action,
    this.icon,
  });
  final String title;
  final List<Widget> children;
  final Widget? action;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon!, size: 15, color: scheme.primary),
                if (icon != null) const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 3),
            SizedBox(width: 26, height: 2, child: ColoredBox(color: kAccent)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
