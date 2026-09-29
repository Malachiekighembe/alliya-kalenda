import 'package:flutter/material.dart';

import 'core/animations.dart';
import 'core/api_client.dart';
import 'core/colors.dart';
import 'core/formatting.dart';
import 'core/project_cover.dart';
import 'data/local_store.dart';
import 'domain/models.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({required this.store, required this.onAdd, super.key});
  final LocalStore store;
  final VoidCallback onAdd;
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String _query = '';
  ProjectStatus? _statusFilter;
  final _search = TextEditingController();

  List<Project> get _projects {
    final needle = _query.trim().toLowerCase();
    return widget.store.projects
        .where(
          (project) =>
              (needle.isEmpty || project.name.toLowerCase().contains(needle)) &&
              (_statusFilter == null || project.status == _statusFilter),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vos projets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Suivez chaque chantier au même endroit.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              compact
                  ? IconButton.filled(
                      onPressed: widget.onAdd,
                      tooltip: 'Nouveau projet',
                      icon: const Icon(Icons.add_rounded),
                    )
                  : FilledButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nouveau projet'),
                    ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      _filterPanel(),
      const SizedBox(height: 16),
      if (_projects.isEmpty)
        _emptyResults()
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 3
                : constraints.maxWidth >= 650
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 250,
              ),
              itemCount: _projects.length,
              itemBuilder: (context, index) => AnimatedReveal(
                delay: Duration(milliseconds: index * 70),
                child: _ProjectCard(
                  project: _projects[index],
                  onDelete: () => _delete(context, _projects[index]),
                ),
              ),
            );
          },
        ),
    ],
  );

  Widget _filterPanel() {
    const statuses = <ProjectStatus?>[
      null,
      ProjectStatus.active,
      ProjectStatus.planned,
      ProjectStatus.completed,
      ProjectStatus.paused,
    ];
    const labels = <String>['Tous', 'Actifs', 'Planifiés', 'Terminés', 'Pause'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Rechercher un projet, un client...',
            prefixIcon: Icon(Icons.search_rounded),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < statuses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[i]),
                    selected: _statusFilter == statuses[i],
                    onSelected: (_) => setState(() {
                      if (_statusFilter == statuses[i]) {
                        _statusFilter = null;
                      } else {
                        _statusFilter = statuses[i];
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyResults() => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 46, color: Colors.black45),
          const SizedBox(height: 12),
          const Text(
            'Aucun projet trouvé',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Modifiez votre recherche ou vos filtres.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
  void _delete(BuildContext context, Project project) => showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer ce projet ?'),
      content: Text(project.name),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            widget.store.deleteProject(project);
            Navigator.pop(dialogContext);
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onDelete});

  final Project project;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photo fills whatever height is left once the caption block has
          // been laid out, so the card adapts to any tile size without
          // overflowing.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real photo of the chantier, bundled with the app so it also
                // renders when the site has no network at all.
                ProjectCover(source: project.imageUrl),
                // Light bottom-only scrim: keeps the photo visible while the
                // reference text stays readable.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .66),
                      ],
                      stops: const [.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 11,
                  top: 10,
                  child: _StatusPill(status: project.status, onPhoto: true),
                ),
                Positioned(
                  right: 5,
                  top: 4,
                  child: IconButton(
                    onPressed: onDelete,
                    tooltip: 'Supprimer le projet',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .9),
                      foregroundColor: scheme.primary,
                    ),
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 9,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          project.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${project.client} · ${project.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      label: '${project.progress.toInt()}% réalisé',
                      icon: Icons.trending_up_rounded,
                      color: kAccent,
                    ),
                    _Tag(
                      label: formatDate(project.plannedEnd),
                      icon: Icons.event_rounded,
                      color: kNavy,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: project.progress / 100),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                minHeight: 6,
                                value: value,
                                backgroundColor: kSurfaceHigh,
                                color: kAccent,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      deadlineHint(project.plannedEnd),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.onPhoto = false});
  final ProjectStatus status;

  /// When the pill sits on a photo it gets a solid background so it stays
  /// readable whatever the image looks like.
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProjectStatus.active => kAccent,
      ProjectStatus.completed => const Color(0xff2f7dd9),
      ProjectStatus.planned => kAmber,
      ProjectStatus.paused => const Color(0xff8a93a3),
      ProjectStatus.cancelled => const Color(0xffd1524f),
    };
    final label = switch (status) {
      ProjectStatus.active => 'Actif',
      ProjectStatus.completed => 'Terminé',
      ProjectStatus.planned => 'Planifié',
      ProjectStatus.paused => 'Pause',
      ProjectStatus.cancelled => 'Annulé',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPhoto
            ? Colors.white.withValues(alpha: .94)
            : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPhoto) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: onPhoto ? kNavy : color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaPage extends StatelessWidget {
  const AgendaPage({required this.store, super.key});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    // Les creneaux proviennent de l'API.
    final slots = store.activities;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PageIntro(
          title: 'Agenda chantier',
          eyebrow: 'Semaine du 14 septembre',
          icon: Icons.calendar_month_rounded,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aujourd’hui',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                _Tag(
                  label: '${slots.length} créneaux',
                  icon: Icons.schedule_rounded,
                  color: kAccent,
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _promptActivity(context, store),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Tâche'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          const _EmptyHint(
            icon: Icons.event_busy_rounded,
            message: 'Aucune activité planifiée.',
          )
        else
          for (var index = 0; index < slots.length; index++)
            AnimatedReveal(
              delay: Duration(milliseconds: index * 80),
              child: _AgendaSlot(
                time: slots[index].time,
                title: slots[index].title,
                project: slots[index].project,
                done: slots[index].status == 'Terminée',
                last: index == slots.length - 1,
              ),
            ),
      ],
    );
  }
}

/// Directory entry for the site team.
class _Member {
  const _Member({
    required this.name,
    required this.role,
    required this.project,
    required this.phone,
    required this.onSite,
  });

  final String name;
  final String role;
  final String project;
  final String phone;

  /// Rattache a un chantier actif (statut « sur site »).
  final bool onSite;
}

/// One timeline entry of the daily agenda.
class _AgendaSlot extends StatelessWidget {
  const _AgendaSlot({
    required this.time,
    required this.title,
    required this.project,
    required this.done,
    required this.last,
  });
  final String time;
  final String title;
  final String project;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = done ? kAccent : kAmber;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .5)),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.schedule_rounded,
                  size: 15,
                  color: accent,
                ),
              ),
              if (!last)
                Expanded(child: Container(width: 2, color: kCardBorder)),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _Tag(
                            label: project,
                            icon: Icons.apartment_rounded,
                            color: kAccent,
                          ),
                          const SizedBox(width: 7),
                          _Tag(
                            label: done ? 'Terminé' : 'À venir',
                            icon: done
                                ? Icons.verified_rounded
                                : Icons.hourglass_bottom_rounded,
                            color: accent,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demande le titre d'une nouvelle activite, puis l'ajoute a l'agenda.
/// La tache est enregistree sur l'API lorsque la session est ouverte.
Future<void> _promptActivity(BuildContext context, LocalStore store) async {
  final title = TextEditingController();
  String project = store.projects.isEmpty
      ? 'Général'
      : store.projects.first.name;

  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nouvelle activité'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Intitulé'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: project,
            decoration: const InputDecoration(labelText: 'Chantier'),
            items: [
              for (final item in store.projects)
                DropdownMenuItem(value: item.name, child: Text(item.name)),
              if (store.projects.isEmpty)
                const DropdownMenuItem(
                  value: 'Général',
                  child: Text('Général'),
                ),
            ],
            onChanged: (value) {
              if (value != null) project = value;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );

  final text = title.text.trim();
  title.dispose();
  if (created != true || text.isEmpty || !context.mounted) return;

  store.addActivity(title: text, project: project);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Activité « $text » ajoutée')));
}

/// Etat vide partage : affiche quand une liste issue de l'API ne contient
/// aucune donnee, plutot que de laisser un panneau vide.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({required this.store, super.key});

  final LocalStore store;

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _search = TextEditingController();
  String _query = '';
  String _roleFilter = 'Tous';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Vue d'affichage derivee du store : l'API et les seeds passent par le
  /// meme modele, seule la source change.
  List<_Member> get members => widget.store.people
      .map(
        (person) => _Member(
          name: person.name,
          role: person.role,
          project: person.project,
          phone: person.phone.isEmpty ? 'Aucun numéro' : person.phone,
          onSite: person.onSite,
        ),
      )
      .toList();

  List<String> get _roles => [
    'Tous',
    ...widget.store.people.map((person) => person.role).toSet(),
  ];

  List<_Member> get _visible {
    final needle = _query.trim().toLowerCase();
    return members
        .where(
          (member) =>
              (_roleFilter == 'Tous' || member.role == _roleFilter) &&
              (needle.isEmpty ||
                  member.name.toLowerCase().contains(needle) ||
                  member.project.toLowerCase().contains(needle)),
        )
        .toList();
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Ajoute un collaborateur au repertoire (et a l'API si la session est active).
  Future<void> _promptPerson() async {
    final name = TextEditingController();
    final role = TextEditingController();
    final phone = TextEditingController();
    var project = widget.store.projects.isEmpty
        ? 'Non affecté'
        : widget.store.projects.first.name;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau collaborateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: role,
                decoration: const InputDecoration(labelText: 'Fonction'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: project,
                decoration: const InputDecoration(labelText: 'Chantier'),
                items: [
                  for (final item in widget.store.projects)
                    DropdownMenuItem(value: item.name, child: Text(item.name)),
                  const DropdownMenuItem(
                    value: 'Non affecté',
                    child: Text('Non affecté'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) project = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    final fullName = name.text.trim();
    final job = role.text.trim();
    final tel = phone.text.trim();
    name.dispose();
    role.dispose();
    phone.dispose();

    if (created != true || fullName.isEmpty || job.isEmpty) return;
    widget.store.addPerson(
      name: fullName,
      role: job,
      phone: tel,
      project: project,
    );
    _notify('$fullName a été ajouté à l’équipe');
  }

  @override
  Widget build(BuildContext context) {
    final members = this.members;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PageIntro(
          title: 'Équipe terrain',
          eyebrow: 'Répertoire des collaborateurs',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PeopleStat(label: 'Effectif', value: '${members.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PeopleStat(
                label: 'Sur site',
                value: '${members.where((member) => member.onSite).length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PeopleStat(
                label: 'Chantiers',
                value:
                    '${members.map((member) => member.project).toSet().length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un collaborateur...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: _promptPerson,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.person_add_alt_rounded, size: 15),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final role in _roles)
              ChoiceChip(
                label: Text(role),
                selected: _roleFilter == role,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _roleFilter = role),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_visible.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              child: Text(
                'Aucun collaborateur ne correspond à ce filtre.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          )
        else
          for (var index = 0; index < _visible.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedReveal(
                delay: Duration(milliseconds: index * 60),
                child: _PersonTile(
                  member: _visible[index],
                  onCall: () => _notify('Appel vers ${_visible[index].name}'),
                  onBrief: () =>
                      _notify('Brief envoyé à ${_visible[index].name}'),
                ),
              ),
            ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.member,
    required this.onCall,
    required this.onBrief,
  });
  final _Member member;
  final VoidCallback onCall;
  final VoidCallback onBrief;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final presence = member.onSite ? kAccent : const Color(0xff93a1b3);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.primary,
                  child: Text(
                    initials(member.name),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: presence,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    member.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(
                        label: member.project,
                        icon: Icons.apartment_rounded,
                        color: kAccent,
                      ),
                      _Tag(
                        label: member.phone,
                        icon: Icons.call_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Appeler',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded, size: 17),
                ),
                IconButton(
                  tooltip: 'Envoyer un brief',
                  visualDensity: VisualDensity.compact,
                  onPressed: onBrief,
                  icon: const Icon(Icons.send_rounded, size: 17),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact statistic tile used in the people directory header.
class _PeopleStat extends StatelessWidget {
  const _PeopleStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: kAccent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Small tinted pill used across the feature pages.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class FinancePage extends StatelessWidget {
  const FinancePage({required this.store, super.key});
  final LocalStore store;
  Map<String, double> get _byProject {
    final totals = <String, double>{};
    for (final payment in store.payments) {
      totals.update(
        payment.project,
        (value) => value + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final received = store.totalReceived;
    final expenses = store.totalExpenses;
    final balance = received - expenses;
    final burn = received <= 0 ? 0.0 : (expenses / received).clamp(0.0, 1.0);
    final breakdown = _byProject;
    final peak = breakdown.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PageIntro(
          title: 'Finances',
          eyebrow: 'Suivi de trésorerie par chantier',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 3 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 86,
              children: [
                _FinanceMetric(
                  label: 'Total reçu',
                  amount: received,
                  icon: Icons.south_west_rounded,
                  color: kAccent,
                ),
                _FinanceMetric(
                  label: 'Dépenses',
                  amount: expenses,
                  icon: Icons.north_east_rounded,
                  color: kAmber,
                ),
                _FinanceMetric(
                  label: 'Solde disponible',
                  amount: balance,
                  icon: Icons.account_balance_rounded,
                  color: kNavy,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _BudgetPanel(
          received: received,
          expenses: expenses,
          burn: burn,
          barColor: burn >= .8 ? const Color(0xffd1524f) : kAccent,
          subtleColor: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Répartition par chantier',
          badge: '${breakdown.length} chantiers',
        ),
        const SizedBox(height: 10),
        for (final entry in breakdown.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProjectBar(
              project: entry.key,
              amount: entry.value,
              share: peak <= 0 ? 0 : entry.value / peak,
            ),
          ),
        const SizedBox(height: 6),
        _SectionHeader(
          title: 'Paiements récents',
          badge: '${store.payments.length} entrées',
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < store.payments.length; index++)
          AnimatedReveal(
            delay: Duration(milliseconds: index * 70),
            child: _PaymentTile(payment: store.payments[index]),
          ),
      ],
    );
  }
}

/// Title + count badge used to separate the finance sections.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      _Tag(label: badge, icon: Icons.insights_rounded, color: kAccent),
    ],
  );
}

/// Budget consumption summary with an animated progress bar.
class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({
    required this.received,
    required this.expenses,
    required this.burn,
    required this.barColor,
    required this.subtleColor,
  });
  final double received;
  final double expenses;
  final double burn;
  final Color barColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: kAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consommation du budget',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Dépenses rapportées aux encaissements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtleColor,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(burn * 100).round()}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: burn),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                minHeight: 7,
                value: value,
                color: barColor,
                backgroundColor: kSurfaceHigh,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Ledger(
                  label: 'Encaissé',
                  value: money(received),
                  color: kAccent,
                ),
              ),
              Container(width: 1, height: 28, color: kCardBorder),
              Expanded(
                child: _Ledger(
                  label: 'Dépensé',
                  value: money(expenses),
                  color: kNavy,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: alignEnd ? 14 : 0),
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

/// Share of encaissements for one chantier.
class _ProjectBar extends StatelessWidget {
  const _ProjectBar({
    required this.project,
    required this.amount,
    required this.share,
  });
  final String project;
  final double amount;
  final double share;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                money(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: kAccent,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 800),
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
  );
}

/// Single movement of money in the treasury list.
class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: kAccent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.project,
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
                      '${payment.date} · ${payment.method}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${money(payment.amount)}',
                    style: const TextStyle(
                      color: kAccent,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const _Tag(
                    label: 'Encaissé',
                    icon: Icons.verified_rounded,
                    color: kAccent,
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

class ReportsPage extends StatelessWidget {
  const ReportsPage({required this.store, super.key});

  final LocalStore store;

  /// Les rapports viennent de l'API ; le statut « Validé » est derive de la
  /// date (un rapport du jour reste un brouillon).
  List<_ReportData> get _reports => store.reports.map((report) {
    final now = DateTime.now();
    final sameDay =
        report.date.year == now.year &&
        report.date.month == now.month &&
        report.date.day == now.day;
    final delta = now.difference(report.date).inDays;
    final label = sameDay
        ? 'Aujourd’hui'
        : delta == 1
        ? 'Hier'
        : 'Il y a $delta jours';
    return _ReportData(
      report.project,
      label,
      report.summary,
      sameDay ? 'Brouillon' : 'Validé',
      !sameDay,
    );
  }).toList();

  /// Publie un rapport : il part sur l'API quand la session est ouverte.
  Future<void> _promptReport(BuildContext context) async {
    final summary = TextEditingController();
    var project = store.projects.isEmpty
        ? 'Général'
        : store.projects.first.name;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau rapport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: project,
              decoration: const InputDecoration(labelText: 'Chantier'),
              items: [
                for (final item in store.projects)
                  DropdownMenuItem(value: item.name, child: Text(item.name)),
                if (store.projects.isEmpty)
                  const DropdownMenuItem(
                    value: 'Général',
                    child: Text('Général'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) project = value;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: summary,
              autofocus: true,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Compte rendu',
                hintText: 'Avancement, livraisons, blocages…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publier'),
          ),
        ],
      ),
    );

    final text = summary.text.trim();
    summary.dispose();
    if (created != true || text.isEmpty || !context.mounted) return;

    store.addReport(
      title: 'Rapport journalier',
      summary: text,
      project: project,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rapport publié')));
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final intro = _PageIntro(
              title: 'Rapports',
              eyebrow: 'Briefs et comptes rendus de chantier',
              icon: Icons.description_rounded,
            );
            final action = FilledButton.icon(
              onPressed: () => _promptReport(context),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(compact ? 'Nouveau' : 'Nouveau rapport'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [intro, const SizedBox(height: 12), action],
              );
            }
            return Row(
              children: [
                Expanded(child: intro),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'Rapports récents',
          badge: '${reports.length} rapport${reports.length > 1 ? 's' : ''}',
        ),
        const SizedBox(height: 10),
        if (reports.isEmpty)
          const _EmptyHint(
            icon: Icons.description_outlined,
            message: 'Aucun rapport publié pour le moment.',
          )
        else
          for (var index = 0; index < reports.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedReveal(
                delay: Duration(milliseconds: index * 70),
                child: _ReportCard(report: reports[index]),
              ),
            ),
        const SizedBox(height: 8),
        const _SectionHeader(
          title: 'Contenu du prochain rapport',
          badge: 'Aperçu',
        ),
        const SizedBox(height: 10),
        const _ReportPreviewCard(),
      ],
    );
  }
}

class _ReportData {
  const _ReportData(
    this.project,
    this.date,
    this.summary,
    this.status,
    this.validated,
  );
  final String project;
  final String date;
  final String summary;
  final String status;
  final bool validated;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) {
    final color = report.validated ? kAccent : kNavy;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ouverture du rapport · ${report.project}')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.project,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.date,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Tag(
                    label: report.status,
                    icon: report.validated
                        ? Icons.verified_rounded
                        : Icons.edit_note_rounded,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.summary,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xff465268),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  const _ReportPreviewCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PreviewLine(
            icon: Icons.schedule_rounded,
            text: '08:30 · Réunion de chantier',
          ),
          SizedBox(height: 10),
          _PreviewLine(
            icon: Icons.construction_rounded,
            text: 'Fondations · Résidence Kasaï · En cours',
          ),
          SizedBox(height: 10),
          _PreviewLine(
            icon: Icons.payments_outlined,
            text: 'Acompte reçu · Atelier Kalenda · Validé',
          ),
        ],
      ),
    ),
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: kAccent),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: Color(0xff465268)),
        ),
      ),
    ],
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.store, super.key});

  final LocalStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool biometricLock = false;

  /// Valeur affichee : la donnee reelle si elle existe, sinon un tiret.
  static String _show(String? value, [String fallback = 'Non renseigné']) =>
      (value != null && value.trim().isNotEmpty) ? value : fallback;

  String get _statusLabel => switch (widget.store.status) {
    SyncStatus.ready => 'Synchronisé',
    SyncStatus.loading => 'Synchronisation…',
    SyncStatus.error => 'Erreur de synchronisation',
    SyncStatus.unauthenticated => 'Non connecte',
    SyncStatus.unconfigured => 'API non configuree',
  };

  /// Sections construites depuis le store : hors session, l'application tourne
  /// et l'API reste celle injectee a la compilation.
  List<_SettingsSectionData> get sections => [
    _SettingsSectionData('Profil', 'Votre identité et votre organisation', [
      _SettingRowData('Compte', _show(widget.store.userEmail, 'Non connecté')),
      _SettingRowData(
        'Source',
        ApiClient.isConfigured ? 'API configurée' : 'API non configurée',
      ),
      _SettingRowData('État', _statusLabel),
    ]),
    _SettingsSectionData(
      'Devise & dates',
      'Formats utilisés dans toute l’application',
      [
        _SettingRowData('Devise', r'USD ($)'),
        _SettingRowData('Format de date', 'JJ/MM/AAAA'),
        _SettingRowData('Langue', 'Français'),
      ],
    ),
    _SettingsSectionData(
      'Synchronisation',
      'État de vos données sur cet appareil',
      [
        _SettingRowData(
          'Source',
          ApiClient.isConfigured ? 'Backend REST API' : 'Aucune API configurée',
        ),
        _SettingRowData(
          'Dernière synchro',
          widget.store.status == SyncStatus.ready ? 'À l’instant' : '—',
        ),
        if (widget.store.errorMessage != null)
          _SettingRowData('Erreur', widget.store.errorMessage!),
      ],
    ),
  ];

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _PageIntro(
        title: 'Paramètres',
        eyebrow: 'Profil, préférences et synchronisation',
        icon: Icons.tune_rounded,
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 850 ? 3 : 1;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 255,
            children: [
              for (var index = 0; index < sections.length; index++)
                AnimatedReveal(
                  delay: Duration(milliseconds: index * 70),
                  child: _SettingsCard(section: sections[index]),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Préférences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: notifications,
                onChanged: (value) => setState(() => notifications = value),
                title: const Text(
                  'Notifications chantier',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Alertes de messages et d’échéances',
                  style: TextStyle(fontSize: 11.5),
                ),
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: kAccent,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: biometricLock,
                onChanged: (value) => setState(() => biometricLock = value),
                title: const Text(
                  'Verrouillage de l’application',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Protéger l’accès à votre espace',
                  style: TextStyle(fontSize: 11.5),
                ),
                secondary: const Icon(Icons.lock_outline_rounded, color: kNavy),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _AppearanceCard(
        onDarkTap: () => _message('Le thème sombre arrivera bientôt.'),
      ),
      const SizedBox(height: 14),
      _SessionCard(store: widget.store),
    ],
  );
}

/// Actions de session : synchronisation manuelle et deconnexion.
///
/// La deconnexion est proposee uniquement lorsqu'une session existe : en mode
/// sans session il n'y a rien a fermer.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.store});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              store.isOnline
                  ? 'Vos données sont enregistrées sur le serveur Alliya Kalenda.'
                  : 'Aucune session ouverte : connectez-vous pour charger vos données.',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: store.isOnline
                      ? () async {
                          await store.refreshFromApi();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Synchronisation terminée'),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Synchroniser'),
                ),
                if (store.isOnline)
                  FilledButton.icon(
                    onPressed: () {
                      store.logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vous êtes déconnecté')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Se déconnecter'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionData {
  const _SettingsSectionData(this.title, this.description, this.rows);
  final String title;
  final String description;
  final List<_SettingRowData> rows;
}

class _SettingRowData {
  const _SettingRowData(this.label, this.value);
  final String label;
  final String value;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.section});
  final _SettingsSectionData section;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: kAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            section.description,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < section.rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      section.rows[index].label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      section.rows[index].value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.onDarkTap});
  final VoidCallback onDarkTap;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apparence',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _ThemeOption(
            label: 'Clair',
            icon: Icons.light_mode_outlined,
            selected: true,
          ),
          const SizedBox(height: 8),
          _ThemeOption(
            label: 'Sombre',
            icon: Icons.dark_mode_outlined,
            selected: false,
            onTap: onDarkTap,
          ),
        ],
      ),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? kAccent.withValues(alpha: .08) : Colors.white,
        border: Border.all(color: selected ? kAccent : const Color(0xffdce3ec)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? kAccent : Colors.black45),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? null : Colors.black45,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: kAccent, size: 18),
        ],
      ),
    ),
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.title,
    required this.eyebrow,
    required this.icon,
  });
  final String title;
  final String eyebrow;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kAccent, kNavy],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: .14),
                foregroundColor: color,
                child: Icon(icon, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedCounter(value: amount, formatter: money),
        ],
      ),
    ),
  );
}
