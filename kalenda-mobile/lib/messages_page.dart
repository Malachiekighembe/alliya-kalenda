import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'core/animations.dart';
import 'core/colors.dart';
import 'core/formatting.dart';
import 'data/local_store.dart';
import 'domain/models.dart';

/// A slice of conversations belonging to one chantier.
class _ProjectConversations {
  const _ProjectConversations({
    required this.project,
    required this.conversations,
  });
  final String project;
  final List<Conversation> conversations;
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({required this.store, super.key});

  final LocalStore store;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _composer = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _attachments = <_PickedAttachment>[];
  String? _selectedConversationId;
  String _projectFilter = 'Tous les projets';
  String _conversationQuery = '';

  Conversation get _selectedConversation =>
      widget.store.conversations.firstWhere(
        (conversation) =>
            conversation.id ==
            (_selectedConversationId ?? widget.store.conversations.first.id),
      );

  @override
  void dispose() {
    _composer.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final content = _chatView(context);
      return AnimatedBuilder(
        animation: widget.store,
        builder: (context, child) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: wide
              ? Row(
                  children: [
                    SizedBox(width: 260, child: _conversationList()),
                    const SizedBox(width: 12),
                    Expanded(child: content),
                  ],
                )
              : Column(
                  children: [
                    _mobileMessageHeader(),
                    const SizedBox(height: 10),
                    Expanded(child: content),
                  ],
                ),
        ),
      );
    },
  );

  Widget _conversationList() => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Conversations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (_unreadTotal > 0)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      '$_unreadTotal non lus',
                      style: const TextStyle(
                        color: kAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 3, 16, 10),
          child: Text(
            'Briefs et échanges chantier',
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _conversationQuery = value),
            decoration: const InputDecoration(
              hintText: 'Rechercher une conversation...',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Expanded(
          child: _groupedConversations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aucune conversation pour ce projet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  children: [
                    for (
                      var groupIndex = 0;
                      groupIndex < _groupedConversations.length;
                      groupIndex++
                    )
                      _buildGroup(
                        _groupedConversations[groupIndex],
                        groupIndex * 90,
                      ),
                  ],
                ),
        ),
      ],
    ),
  );

  int get _unreadTotal => widget.store.conversations.fold(
    0,
    (sum, conversation) => sum + conversation.unread,
  );

  /// Renders one chantier group: header + staggered conversation tiles.
  Widget _buildGroup(_ProjectConversations group, int baseDelay) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildProjectHeader(group),
      for (var index = 0; index < group.conversations.length; index++)
        AnimatedReveal(
          delay: Duration(milliseconds: baseDelay + index * 50),
          child: _conversationTile(group.conversations[index]),
        ),
    ],
  );

  /// Header for a chantier group: coloured badge + project name + counters.
  Widget _buildProjectHeader(_ProjectConversations group) {
    final project = group.project;
    final count = group.conversations.length;
    final unread = group.conversations.fold(0, (sum, c) => sum + c.unread);
    final colors = [kAccent, kAmber, kNavy, const Color(0xff6366f1)];
    final icons = [
      Icons.apartment_rounded,
      Icons.construction_rounded,
      Icons.home_rounded,
      Icons.factory_rounded,
    ];
    final seed = project.codeUnits.fold<int>(
      0,
      (sum, u) => (sum + u) & 0x7fffffff,
    );
    final color = colors[seed % colors.length];
    final icon = icons[seed % icons.length];
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: color.withValues(alpha: .14),
            foregroundColor: color,
            child: Icon(icon, size: 10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              project,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$count conversation${count > 1 ? 's' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: Text(
                  '$unread non lus',
                  style: const TextStyle(
                    color: kAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conversationTile(Conversation conversation) {
    final scheme = Theme.of(context).colorScheme;
    final selected =
        conversation.id ==
        (_selectedConversationId ?? widget.store.conversations.first.id);
    final messages = widget.store.messagesFor(conversation.id);
    final preview = messages.isEmpty
        ? conversation.subtitle
        : messages.last.body;
    final stamp = messages.isEmpty ? null : clockLabel(messages.last.sentAt);
    final nameStyle = TextStyle(
      fontSize: 13.5,
      height: 1.25,
      fontWeight: conversation.unread > 0 ? FontWeight.w800 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: .6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              setState(() => _selectedConversationId = conversation.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: selected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      foregroundColor: selected ? Colors.white : scheme.primary,
                      child: Text(
                        conversation.initials,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (conversation.unread > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: kAmber,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '${conversation.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: nameStyle,
                            ),
                          ),
                          if (stamp != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              stamp,
                              style: TextStyle(
                                color: conversation.unread > 0
                                    ? kAccent
                                    : scheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: conversation.unread > 0
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Conversations grouped by chantier, ordered like [LocalStore.projects]
  /// then any unknown project alphabetically. Only projects that actually own
  /// a visible conversation (matching the search) are emitted.
  List<_ProjectConversations> get _groupedConversations {
    final needle = _conversationQuery.trim().toLowerCase();
    final seed = widget.store.projects.map((project) => project.name).toList();
    final matched = [
      for (final conversation in widget.store.conversations)
        if (needle.isEmpty ||
            conversation.title.toLowerCase().contains(needle) ||
            conversation.projectName.toLowerCase().contains(needle))
          conversation,
    ];
    final buckets = <String, List<Conversation>>{};
    for (final conversation in matched) {
      buckets
          .putIfAbsent(conversation.projectName, () => <Conversation>[])
          .add(conversation);
    }
    final order = [
      for (final name in seed)
        if (buckets.containsKey(name)) name,
      for (final name in buckets.keys.toSet().where(
        (name) => !seed.contains(name),
      ))
        ...[name]..sort(),
    ];
    return [
      for (final name in order)
        _ProjectConversations(project: name, conversations: buckets[name]!),
    ];
  }

  List<Conversation> get _visibleConversations => widget.store.conversations
      .where(
        (conversation) =>
            (_projectFilter == 'Tous les projets' ||
                conversation.projectName == _projectFilter) &&
            (_conversationQuery.isEmpty ||
                conversation.title.toLowerCase().contains(
                  _conversationQuery.toLowerCase(),
                )),
      )
      .toList();

  List<String> get _projectFilters => [
    'Tous les projets',
    ...widget.store.conversations
        .map((conversation) => conversation.projectName)
        .where((name) => name != 'Tous les projets')
        .toSet(),
  ];

  Widget _mobileMessageHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'Choisir un projet',
            onSelected: _setProjectFilter,
            itemBuilder: (context) => [
              for (final project in _projectFilters)
                PopupMenuItem(value: project, child: Text(project)),
            ],
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.apartment_rounded, color: scheme.primary),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedConversation.id,
              isDense: true,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Équipe',
                prefixIcon: Icon(Icons.forum_outlined),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
              ),
              items: [
                for (final conversation in _visibleConversations)
                  DropdownMenuItem(
                    value: conversation.id,
                    child: Text(
                      conversation.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedConversationId = value),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: _projectFilter,
            child: Icon(
              Icons.filter_alt_rounded,
              size: 20,
              color: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _setProjectFilter(String value) {
    final conversations = widget.store.conversations
        .where(
          (conversation) =>
              value == 'Tous les projets' || conversation.projectName == value,
        )
        .toList();
    setState(() {
      _projectFilter = value;
      if (conversations.isNotEmpty &&
          !conversations.any(
            (conversation) => conversation.id == _selectedConversation.id,
          )) {
        _selectedConversationId = conversations.first.id;
      }
    });
  }

  Widget _chatView(BuildContext context) {
    final conversation = _selectedConversation;
    final messages = widget.store.messagesFor(conversation.id);
    return Card(
      child: Column(
        children: [
          _chatHeader(conversation),
          const Divider(height: 1),
          Expanded(
            child: messages.isEmpty
                ? _emptyState(conversation)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _messageBubble(messages[index], conversation),
                  ),
          ),
          _composerArea(conversation),
        ],
      ),
    );
  }

  Widget _chatHeader(Conversation conversation) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(
            conversation.initials,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                conversation.projectName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Créer un brief',
          onPressed: () => _insertBrief(conversation),
          icon: const Icon(Icons.summarize_outlined),
        ),
      ],
    ),
  );

  Widget _emptyState(Conversation conversation) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez le brief de ${conversation.projectName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajoutez les travaux réalisés et les photos du jour.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );

  Widget _messageBubble(ChatMessage message, Conversation conversation) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: message.isMine
          ? colorScheme.secondaryContainer
          : colorScheme.primaryContainer,
      foregroundColor: colorScheme.primary,
      child: Text(
        message.isMine ? 'MK' : conversation.initials,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
      decoration: BoxDecoration(
        gradient: message.isMine
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kAccent, const Color(0xff2051a8)],
              )
            : null,
        color: message.isMine ? null : kSurfaceHigh,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isMine ? 16 : 4),
          bottomRight: Radius.circular(message.isMine ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.body,
            style: TextStyle(
              color: message.isMine ? Colors.white : null,
              height: 1.35,
            ),
          ),
          if (message.attachmentNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final name in message.attachmentNames)
                  Container(
                    width: 116,
                    height: 58,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: message.isMine ? Colors.white12 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 20,
                          color: message.isMine
                              ? Colors.white
                              : colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: message.isMine ? Colors.white : null,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 5),
          Text(
            _time(message.sentAt),
            style: TextStyle(
              color: message.isMine ? Colors.white70 : Colors.black45,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: message.isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: message.isMine
          ? [Flexible(child: bubble), const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), Flexible(child: bubble)],
    );
  }

  Widget _composerArea(Conversation conversation) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
    ),
    child: Column(
      children: [
        if (_attachments.isNotEmpty) _attachmentPreview(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.filledTonal(
              tooltip: 'Ajouter des images',
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message ou un brief...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: () => _send(conversation),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _attachmentPreview() => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < _attachments.length; index++)
            InputChip(
              avatar: Image.memory(
                _attachments[index].bytes,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  _attachments[index].name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onDeleted: () => setState(() => _attachments.removeAt(index)),
            ),
        ],
      ),
    ),
  );

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (mounted) {
      final picked = <_PickedAttachment>[];
      for (final file in result) {
        picked.add(
          _PickedAttachment(name: file.name, bytes: await file.readAsBytes()),
        );
      }
      if (mounted) setState(() => _attachments.addAll(picked));
    }
  }

  void _insertBrief(Conversation conversation) {
    _composer.text =
        'Brief du jour - ${conversation.projectName}\n\nTravaux réalisés :\n\nPoints à signaler :\n\nSuite prévue demain :';
    _composer.selection = TextSelection.collapsed(
      offset: _composer.text.length,
    );
  }

  void _send(Conversation conversation) {
    final body = _composer.text.trim();
    if (body.isEmpty && _attachments.isEmpty) return;
    widget.store.sendMessage(
      conversationId: conversation.id,
      body: body.isEmpty ? 'Photos du chantier' : body,
      projectName: conversation.projectName,
      attachmentNames: _attachments.map((file) => file.name).toList(),
    );
    _composer.clear();
    setState(() => _attachments.clear());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _PickedAttachment {
  const _PickedAttachment({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
