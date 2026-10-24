import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'data/app_data.dart';

const _canvasDark = Color(0xFF111210);
const _panelDark = Color(0xFF1C1E1A);
const _gold = Color(0xFFC9A56A);
const _muted = Color(0xFF9A9B94);

class AppController extends ChangeNotifier {
  AppController() {
    initialize();
  }

  final store = LocalStore.instance;
  List<FilmProject> projects = [];
  String theme = 'cinema';
  String fontStyle = 'modern';
  int accent = _gold.toARGB32();
  bool loading = true;
  Object? loadError;

  Future<void> initialize() async {
    try {
      final values = await Future.wait<Object>([
        store.getProjects(),
        UserPreferences.instance.getTheme(),
        UserPreferences.instance.getAccent(),
        UserPreferences.instance.getFontStyle(),
      ]);
      projects = values[0] as List<FilmProject>;
      theme = values[1] as String;
      accent = values[2] as int;
      fontStyle = values[3] as String;
      loadError = null;
    } catch (error) {
      loadError = error;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveProject(FilmProject project) async {
    await store.saveProject(project);
    projects = await store.getProjects();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await store.deleteProject(id);
    projects = await store.getProjects();
    notifyListeners();
  }

  Future<void> saveTake(TakeRecord take) async {
    await store.saveTake(take);
    notifyListeners();
  }

  Future<void> updateTake(TakeRecord take) async {
    await store.updateTake(take);
    notifyListeners();
  }

  Future<void> deleteTake(int id) async {
    await store.deleteTake(id);
    notifyListeners();
  }

  Future<void> refresh() async {
    projects = await store.getProjects();
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await UserPreferences.instance.setTheme(value);
    notifyListeners();
  }

  Future<void> setAccent(int value) async {
    accent = value;
    await UserPreferences.instance.setAccent(value);
    notifyListeners();
  }

  Future<void> setFontStyle(String value) async {
    fontStyle = value;
    await UserPreferences.instance.setFontStyle(value);
    notifyListeners();
  }
}

class TakeOneApp extends StatefulWidget {
  const TakeOneApp({super.key});

  @override
  State<TakeOneApp> createState() => _TakeOneAppState();
}

class _TakeOneAppState extends State<TakeOneApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final light = controller.theme == 'light';
      final cinematic = controller.theme == 'cinema';
      final accent = Color(controller.accent);
      final scheme = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: light ? Brightness.light : Brightness.dark,
        surface: light
            ? const Color(0xFFF6F4F0)
            : cinematic
            ? _canvasDark
            : const Color(0xFF090A0A),
      );
      return MaterialApp(
        title: 'TakeOne',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: switch (controller.fontStyle) {
            'serif' => 'serif',
            'mono' => 'monospace',
            _ => null,
          },
          colorScheme: scheme,
          scaffoldBackgroundColor: light
              ? const Color(0xFFF6F4F0)
              : cinematic
              ? _canvasDark
              : const Color(0xFF090A0A),
          appBarTheme: AppBarTheme(
            backgroundColor: light
                ? const Color(0xFFF6F4F0)
                : cinematic
                ? _canvasDark
                : const Color(0xFF090A0A),
            foregroundColor: light ? const Color(0xFF20211E) : Colors.white,
          ),
          cardTheme: CardThemeData(
            color: light
                ? Colors.white
                : cinematic
                ? _panelDark
                : const Color(0xFF171717),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: light
                    ? const Color(0xFFE6E2DA)
                    : Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: light
                ? const Color(0xFFF1EFEA)
                : Colors.white.withValues(alpha: .045),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
          ),
        ),
        home: HomeScreen(controller: controller),
      );
    },
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  Future<void> _createProject(BuildContext context) async {
    final project = await Navigator.of(context).push<FilmProject>(
      MaterialPageRoute(builder: (_) => const ProjectEditorScreen()),
    );
    if (project != null) await controller.saveProject(project);
  }

  Future<void> _editProject(BuildContext context, FilmProject project) async {
    final updated = await Navigator.of(context).push<FilmProject>(
      MaterialPageRoute(builder: (_) => ProjectEditorScreen(project: project)),
    );
    if (updated != null) await controller.saveProject(updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.loadError != null
          ? _LoadFailure(
              error: controller.loadError!,
              onRetry: controller.initialize,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Projects',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '[${controller.projects.length}]',
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _createProject(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New project'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(controller.accent),
                          foregroundColor: const Color(0xFF191712),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Appearance',
                        onPressed: () => _showAppearance(context, controller),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                      itemCount: controller.projects.isEmpty
                          ? 1
                          : controller.projects.length,
                      itemBuilder: (context, index) {
                        if (controller.projects.isEmpty) {
                          return _EmptyProjects(
                            onCreate: () => _createProject(context),
                          );
                        }
                        final project = controller.projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: _ProjectCard(
                            project: project,
                            accent: Color(controller.accent),
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectWorkspace(
                                  controller: controller,
                                  projectId: project.id,
                                ),
                              ),
                            ),
                            onEdit: () => _editProject(context, project),
                            onDelete: () => _confirmDeleteProject(
                              context,
                              controller,
                              project,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.projects});

  final List<FilmProject> projects;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          const _Metric(label: 'IN PRODUCTION', value: 'READY'),
          const Spacer(),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: .1),
          ),
          const Spacer(),
          _Metric(label: 'PROJECTS', value: '${projects.length}'),
          const Spacer(),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: .1),
          ),
          const Spacer(),
          const _Metric(label: 'ON SET', value: 'OFFLINE'),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.accent,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final FilmProject project;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
        child: Row(
          children: [
            // Container(
            //   width: 46,
            //   height: 51,
            //   decoration: BoxDecoration(
            //     color: accent.withValues(alpha: .12),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Icon(Icons.movie_outlined, color: accent, size: 23),
            // ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (project.director.isNotEmpty) project.director,
                      project.productionDate,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit project')),
                PopupMenuItem(value: 'delete', child: Text('Delete project')),
              ],
              icon: const Icon(Icons.more_horiz_rounded, color: _muted),
            ),
            // Icon(
            //   Icons.chevron_right_rounded,
            //   color: Theme.of(
            //     context,
            //   ).colorScheme.onSurface.withValues(alpha: .4),
            // ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const Icon(Icons.movie_filter_outlined, color: _gold, size: 34),
          const SizedBox(height: 13),
          const Text('Create a project to get started'),
        ],
      ),
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            'Could not load your projects',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteProject(
  BuildContext context,
  AppController controller,
  FilmProject project,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this project?'),
      content: Text(
        '“${project.name}” and its complete take history will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteProject(project.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project deleted')));
    }
  }
}

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({this.project, super.key});

  final FilmProject? project;

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _director;
  late final TextEditingController _dop;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late String _productionDate;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _name = TextEditingController(text: project?.name ?? '');
    _director = TextEditingController(text: project?.director ?? '');
    _dop = TextEditingController(text: project?.dop ?? '');
    _location = TextEditingController(text: project?.location ?? '');
    _notes = TextEditingController(text: project?.notes ?? '');
    _productionDate =
        project?.productionDate ??
        DateFormat('MMM d, yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _name.dispose();
    _director.dispose();
    _dop.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.project;
    final project = FilmProject(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      productionDate: _productionDate,
      director: _director.text.trim(),
      dop: _dop.text.trim(),
      location: _location.text.trim(),
      notes: _notes.text.trim(),
      roll: old?.roll ?? 'A001',
      scene: old?.scene ?? '1',
      shot: old?.shot ?? '1',
      take: old?.take ?? 1,
      soundEnabled: old?.soundEnabled ?? true,
      fields: old?.fields ?? FilmProject.defaultSlateFields,
    );
    Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.project == null ? 'New project' : 'Edit project'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
      actions: [
        TextButton(
          onPressed: _save,
          child: Text(
            widget.project == null ? 'Create project' : 'Save changes',
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          TextFormField(
            controller: _name,
            autofocus: widget.project == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Project name *'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Project name is required'
                : null,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 2,
              ),
              leading: const Icon(Icons.calendar_today_outlined, size: 19),
              title: const Text(
                'Production date',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                _productionDate,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final now = DateTime.now();
                final selected = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) {
                  setState(
                    () => _productionDate = DateFormat(
                      'MMM d, yyyy',
                    ).format(selected),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          _EditorField(controller: _director, label: 'Director'),
          const SizedBox(height: 12),
          _EditorField(controller: _dop, label: 'Director of photography'),
          const SizedBox(height: 12),
          _EditorField(controller: _location, label: 'Location'),
          const SizedBox(height: 12),
          _EditorField(controller: _notes, label: 'Production notes', lines: 3),
          // const SizedBox(height: 25),
          // FilledButton(
          //   onPressed: _save,
          //   style: FilledButton.styleFrom(
          //     padding: const EdgeInsets.symmetric(vertical: 15),
          //   ),
          //   child: Text(
          //     widget.project == null ? 'Create project' : 'Save changes',
          //   ),
          // ),
        ],
      ),
    ),
  );
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.lines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int lines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    maxLines: lines,
    decoration: InputDecoration(labelText: label),
  );
}

class ProjectWorkspace extends StatefulWidget {
  const ProjectWorkspace({
    required this.controller,
    required this.projectId,
    super.key,
  });

  final AppController controller;
  final String projectId;

  @override
  State<ProjectWorkspace> createState() => _ProjectWorkspaceState();
}

class _ProjectWorkspaceState extends State<ProjectWorkspace> {
  int _tab = 0;
  int _historyKey = 0;

  void _selectTab(int index) {
    setState(() {
      _tab = index;
      if (index == 1) _historyKey++;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final matches = widget.controller.projects.where(
        (project) => project.id == widget.projectId,
      );
      if (matches.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('This project is no longer available')),
        );
      }
      final project = matches.first;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 18,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                project.productionDate,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Export project PDF',
              onPressed: () =>
                  _exportProject(context, widget.controller, project),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 3, 18, 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _WorkspaceTab(
                      label: 'Slate',
                      icon: Icons.movie_outlined,
                      selected: _tab == 0,
                      onTap: () => _selectTab(0),
                    ),
                    _WorkspaceTab(
                      label: 'Takes',
                      icon: Icons.list_alt_rounded,
                      selected: _tab == 1,
                      onTap: () => _selectTab(1),
                    ),
                    _WorkspaceTab(
                      label: 'Setup',
                      icon: Icons.tune_rounded,
                      selected: _tab == 2,
                      onTap: () => _selectTab(2),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  SlatePreview(
                    project: project,
                    controller: widget.controller,
                    onOpenSlate: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClapboardScreen(
                          projectId: project.id,
                          controller: widget.controller,
                        ),
                      ),
                    ),
                  ),
                  TakeHistoryView(
                    key: ValueKey(_historyKey),
                    project: project,
                    controller: widget.controller,
                  ),
                  ProjectSetupView(
                    project: project,
                    controller: widget.controller,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: selected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Theme.of(context).colorScheme.primary : _muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : _muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SlatePreview extends StatelessWidget {
  const SlatePreview({
    required this.project,
    required this.controller,
    required this.onOpenSlate,
    super.key,
  });

  final FilmProject project;
  final AppController controller;
  final VoidCallback onOpenSlate;

  @override
  Widget build(BuildContext context) {
    final fields = project.fields;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        const _SectionEyebrow('READY FOR THE NEXT TAKE'),
        const SizedBox(height: 11),
        GestureDetector(
          onTap: onOpenSlate,
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFF171916),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -35,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(controller.accent).withValues(alpha: .07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.movie_creation_outlined,
                            size: 15,
                            color: Color(controller.accent),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            project.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1.7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white60,
                            size: 19,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: fields
                            .where((field) => field.visible)
                            .map(
                              (field) => _SlateValue(
                                label: field.label,
                                value: _fieldValue(
                                  project,
                                  field.id,
                                  customValue: field.value,
                                ),
                                accent: Color(controller.accent),
                                size: field.size,
                              ),
                            )
                            .toList(),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Color(0xFF67C995),
                            size: 8,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '00:00:00',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'TAP TO OPEN SLATE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 8,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        FilledButton.icon(
          onPressed: onOpenSlate,
          icon: const Icon(Icons.fullscreen_rounded),
          label: const Text('Open full-screen slate'),
          style: FilledButton.styleFrom(
            backgroundColor: Color(controller.accent),
            foregroundColor: const Color(0xFF191712),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: _SectionEyebrow('CURRENT SETUP')),
            TextButton.icon(
              onPressed: () => controller.saveProject(
                project.copyWith(take: project.take + 1),
              ),
              icon: const Icon(Icons.skip_next_rounded, size: 17),
              label: const Text('Next take'),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Card(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Director',
                value: project.director.isEmpty ? 'Not set' : project.director,
              ),
              const Divider(height: 1, indent: 52, endIndent: 15),
              _InfoRow(
                icon: Icons.camera_alt_outlined,
                label: 'Director of photography',
                value: project.dop.isEmpty ? 'Not set' : project.dop,
              ),
              const Divider(height: 1, indent: 52, endIndent: 15),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: project.location.isEmpty ? 'Not set' : project.location,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlateValue extends StatelessWidget {
  const _SlateValue({
    required this.label,
    required this.value,
    required this.accent,
    this.size = 1,
  });

  final String label;
  final String value;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 65),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: accent.withValues(alpha: .4)),
      color: accent.withValues(alpha: .08),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            color: accent,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 18 * size),
        ),
      ],
    ),
  );
}

String _fieldValue(FilmProject project, String id, {String customValue = ''}) =>
    switch (id) {
      'roll' => project.roll,
      'scene' => project.scene,
      'shot' => project.shot,
      'take' => project.take.toString().padLeft(2, '0'),
      _ => customValue,
    };

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    child: Row(
      children: [
        Icon(icon, color: _muted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class ProjectSetupView extends StatefulWidget {
  const ProjectSetupView({
    required this.project,
    required this.controller,
    super.key,
  });

  final FilmProject project;
  final AppController controller;

  @override
  State<ProjectSetupView> createState() => _ProjectSetupViewState();
}

class _ProjectSetupViewState extends State<ProjectSetupView> {
  late final TextEditingController _roll;
  late final TextEditingController _scene;
  late final TextEditingController _shot;
  late List<SlateField> _fields;

  @override
  void initState() {
    super.initState();
    _roll = TextEditingController(text: widget.project.roll);
    _scene = TextEditingController(text: widget.project.scene);
    _shot = TextEditingController(text: widget.project.shot);
    _fields = [...widget.project.fields];
  }

  @override
  void didUpdateWidget(covariant ProjectSetupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _roll.text = widget.project.roll;
      _scene.text = widget.project.scene;
      _shot.text = widget.project.shot;
      _fields = [...widget.project.fields];
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    _scene.dispose();
    _shot.dispose();
    super.dispose();
  }

  Future<void> _save({List<SlateField>? fields}) async {
    await widget.controller.saveProject(
      widget.project.copyWith(
        roll: _roll.text.trim().isEmpty ? 'A001' : _roll.text.trim(),
        scene: _scene.text.trim().isEmpty ? '1' : _scene.text.trim(),
        shot: _shot.text.trim().isEmpty ? '1' : _shot.text.trim(),
        fields: fields ?? _fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
    children: [
      const _SectionEyebrow('SLATE POSITION'),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _CompactInput(
              label: 'Roll',
              controller: _roll,
              onSubmitted: () => _save(),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _CompactInput(
              label: 'Scene',
              controller: _scene,
              onSubmitted: () => _save(),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _CompactInput(
              label: 'Shot',
              controller: _shot,
              onSubmitted: () => _save(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(child: _SectionEyebrow('SLATE FIELDS')),
          TextButton.icon(
            onPressed: () async {
              final changed = await _editField(context, null);
              if (changed != null) {
                setState(() => _fields = [..._fields, changed]);
                await _save();
              }
            },
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Add field'),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Card(
        child: Column(
          children: _fields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1, indent: 14, endIndent: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 5, 4, 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: _muted,
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final changed = await _editField(context, field);
                            if (changed != null) {
                              setState(() => _fields[index] = changed);
                              await _save();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${field.id.toUpperCase()}  ·  ${field.size.toStringAsFixed(1)}× text',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Move field up',
                        onPressed: index == 0
                            ? null
                            : () async {
                                setState(() {
                                  final item = _fields.removeAt(index);
                                  _fields.insert(index - 1, item);
                                });
                                await _save();
                              },
                        icon: const Icon(Icons.keyboard_arrow_up),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Move field down',
                        onPressed: index == _fields.length - 1
                            ? null
                            : () async {
                                setState(() {
                                  final item = _fields.removeAt(index);
                                  _fields.insert(index + 1, item);
                                });
                                await _save();
                              },
                        icon: const Icon(Icons.keyboard_arrow_down),
                        visualDensity: VisualDensity.compact,
                      ),
                      Switch(
                        value: field.visible,
                        onChanged: (value) async {
                          setState(
                            () =>
                                _fields[index] = field.copyWith(visible: value),
                          );
                          await _save();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 19),
      const _SectionEyebrow('SOUND'),
      const SizedBox(height: 8),
      Card(
        child: SwitchListTile(
          value: widget.project.soundEnabled,
          title: const Text(
            'Clapper sound',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Play the slate sound on each clap',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          onChanged: (value) => widget.controller.saveProject(
            widget.project.copyWith(soundEnabled: value),
          ),
        ),
      ),
    ],
  );
}

class _CompactInput extends StatelessWidget {
  const _CompactInput({
    required this.label,
    required this.controller,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onSubmitted: (_) {
      onSubmitted();
      FocusScope.of(context).unfocus();
    },
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
    ),
  );
}

Future<SlateField?> _editField(BuildContext context, SlateField? field) async {
  final label = TextEditingController(text: field?.label ?? '');
  final fieldValue = TextEditingController(text: field?.value ?? '');
  double size = field?.size ?? 1;
  final result = await showDialog<SlateField>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(field == null ? 'Add slate field' : 'Edit slate field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Slate label'),
            ),
            if (field == null ||
                !const [
                  'roll',
                  'scene',
                  'shot',
                  'take',
                ].contains(field.id)) ...[
              const SizedBox(height: 10),
              TextField(
                controller: fieldValue,
                decoration: const InputDecoration(labelText: 'Slate value'),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('Text size'),
                Expanded(
                  child: Slider(
                    value: size,
                    min: .75,
                    max: 1.5,
                    divisions: 3,
                    label: '${size.toStringAsFixed(2)}×',
                    onChanged: (value) => setDialogState(() => size = value),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final fieldLabel = label.text.trim();
              if (fieldLabel.isEmpty) return;
              Navigator.pop(
                context,
                SlateField(
                  id:
                      field?.id ??
                      'custom_${DateTime.now().microsecondsSinceEpoch}',
                  label: fieldLabel,
                  value:
                      field != null &&
                          const [
                            'roll',
                            'scene',
                            'shot',
                            'take',
                          ].contains(field.id)
                      ? field.value
                      : fieldValue.text.trim(),
                  visible: field?.visible ?? true,
                  size: size,
                ),
              );
            },
            child: const Text('Save field'),
          ),
        ],
      ),
    ),
  );
  label.dispose();
  fieldValue.dispose();
  return result;
}

class TakeHistoryView extends StatefulWidget {
  const TakeHistoryView({
    required this.project,
    required this.controller,
    super.key,
  });

  final FilmProject project;
  final AppController controller;

  @override
  State<TakeHistoryView> createState() => _TakeHistoryViewState();
}

class _TakeHistoryViewState extends State<TakeHistoryView> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => FutureBuilder<List<TakeRecord>>(
      future: widget.controller.store.getTakes(widget.project.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load takes: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!;
        final takes = all.where((take) {
          if (_filter == 'Good') {
            return take.rating == TakeRating.good ||
                take.rating == TakeRating.movingOn;
          }
          if (_filter == 'Bad') return take.rating == TakeRating.bad;
          if (_filter == 'Test') return take.rating == TakeRating.test;
          return true;
        }).toList();
        return Column(
          children: [
            SizedBox(
              height: 37,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                children: ['All', 'Good', 'Bad', 'Test']
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: takes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.movie_filter_outlined,
                            size: 34,
                            color: _muted,
                          ),
                          const SizedBox(height: 11),
                          Text(
                            all.isEmpty
                                ? 'No takes recorded yet'
                                : 'No ${_filter.toLowerCase()} takes',
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Your slate history will appear here.',
                            style: TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
                      itemCount: takes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final take = takes[index];
                        return _TakeCard(
                          take: take,
                          onEdit: () =>
                              _editTake(context, widget.controller, take),
                          onDelete: () =>
                              _deleteTake(context, widget.controller, take),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _TakeCard extends StatelessWidget {
  const _TakeCard({
    required this.take,
    required this.onEdit,
    required this.onDelete,
  });

  final TakeRecord take;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(take.rating);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 7, 12),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SC ${take.scene}  /  SH ${take.shot}  /  TK ${take.take.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingChip(rating: take.rating),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${take.timecode}  ·  ${DateFormat('MMM d, h:mm a').format(take.createdAt)}',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                  if (take.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      take.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit take')),
                PopupMenuItem(value: 'delete', child: Text('Delete take')),
              ],
              icon: const Icon(Icons.more_vert, size: 19, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

Color _ratingColor(TakeRating rating) => switch (rating) {
  TakeRating.good || TakeRating.movingOn => const Color(0xFF68C991),
  TakeRating.bad => const Color(0xFFE1786B),
  TakeRating.test => const Color(0xFF80A9E8),
};

String _ratingLabel(TakeRating rating) => switch (rating) {
  TakeRating.good => 'GOOD',
  TakeRating.movingOn => 'MOVED ON',
  TakeRating.bad => 'BAD',
  TakeRating.test => 'TEST',
};

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final TakeRating rating;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        _ratingLabel(rating),
        style: TextStyle(
          color: color,
          fontSize: 7,
          letterSpacing: .5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<void> _editTake(
  BuildContext context,
  AppController controller,
  TakeRecord take,
) async {
  final scene = TextEditingController(text: take.scene);
  final shot = TextEditingController(text: take.shot);
  final takeNumber = TextEditingController(text: '${take.take}');
  final timecode = TextEditingController(text: take.timecode);
  final notes = TextEditingController(text: take.notes);
  var rating = take.rating;
  final updated = await showDialog<TakeRecord>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit take'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scene,
                      decoration: const InputDecoration(labelText: 'Scene'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: shot,
                      decoration: const InputDecoration(labelText: 'Shot'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: takeNumber,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Take'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: timecode,
                      decoration: const InputDecoration(labelText: 'Timecode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<TakeRating>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: TakeRating.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_ratingLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => rating = value);
                },
              ),
              const SizedBox(height: 9),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final number = int.tryParse(takeNumber.text);
              if (scene.text.trim().isEmpty ||
                  shot.text.trim().isEmpty ||
                  number == null ||
                  number < 1 ||
                  timecode.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                take.copyWith(
                  scene: scene.text.trim(),
                  shot: shot.text.trim(),
                  take: number,
                  timecode: timecode.text.trim(),
                  rating: rating,
                  notes: notes.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  scene.dispose();
  shot.dispose();
  takeNumber.dispose();
  timecode.dispose();
  notes.dispose();
  if (updated != null) await controller.updateTake(updated);
}

Future<void> _deleteTake(
  BuildContext context,
  AppController controller,
  TakeRecord take,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete take?'),
      content: const Text(
        'This take will be removed from the project history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm == true && take.id != null) await controller.deleteTake(take.id!);
}

class ClapboardScreen extends StatefulWidget {
  const ClapboardScreen({
    required this.projectId,
    required this.controller,
    super.key,
  });

  final String projectId;
  final AppController controller;

  @override
  State<ClapboardScreen> createState() => _ClapboardScreenState();
}

class _ClapboardScreenState extends State<ClapboardScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _flash;
  Timer? _clock;
  DateTime _now = DateTime.now();
  bool _clapping = false;

  FilmProject? get project {
    for (final value in widget.controller.projects) {
      if (value.id == widget.projectId) return value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerChanged);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      reverseDuration: const Duration(milliseconds: 360),
    );
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    _clock?.cancel();
    _flash.dispose();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String get _timecode {
    return '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';
  }

  Future<void> _clap() async {
    final activeProject = project;
    if (activeProject == null) return;
    setState(() => _clapping = true);
    _flash.forward(from: 0).then((_) => _flash.reverse());
    if (activeProject.soundEnabled) {
      try {
        await _player.stop();
        await _player.play(AssetSource('audio/clap.wav'));
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not play slate sound: $error')),
          );
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) setState(() => _clapping = false);
    if (!mounted) return;
    final rating = await showDialog<TakeRating>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog.fullscreen(
          backgroundColor: const Color(0xFF111210),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Scene ${activeProject.scene}  ·  Shot ${activeProject.shot}  ·  Take ${activeProject.take}',
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 3,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      children: [
                        _RatingAction(
                          label: 'Bad take',
                          subtitle: 'Save and retake',
                          icon: Icons.close_rounded,
                          color: const Color.fromARGB(255, 231, 140, 127),
                          onTap: () => Navigator.pop(context, TakeRating.bad),
                        ),
                        _RatingAction(
                          label: 'Good take',
                          subtitle: 'Need retake',
                          icon: Icons.replay_rounded,
                          color: const Color.fromARGB(255, 190, 190, 98),
                          onTap: () => Navigator.pop(context, TakeRating.good),
                        ),
                        _RatingAction(
                          label: 'Moving on',
                          subtitle: 'Move to next shot',
                          icon: Icons.skip_next_rounded,
                          color: const Color.fromARGB(255, 120, 212, 159),
                          onTap: () =>
                              Navigator.pop(context, TakeRating.movingOn),
                        ),
                        _RatingAction(
                          label: 'Test take',
                          subtitle: 'Don\'t count it',
                          icon: Icons.science_outlined,
                          color: const Color.fromARGB(255, 167, 167, 167),
                          onTap: () => Navigator.pop(context, TakeRating.test),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (rating == null || !mounted) return;
    var nextScene = activeProject.scene;
    var nextShot = activeProject.shot;
    var nextTake = activeProject.take;
    if (rating == TakeRating.bad || rating == TakeRating.good) {
      nextTake++;
    } else if (rating == TakeRating.movingOn) {
      final moveToScene = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move on to…'),
          content: const Text('Choose the next slate position.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Next shot'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Next scene'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (moveToScene == true) {
        nextScene = _incrementCode(activeProject.scene);
        nextShot = '1';
      } else {
        nextShot = _incrementCode(activeProject.shot);
      }
      nextTake = 1;
    }
    final take = TakeRecord(
      id: null,
      projectId: activeProject.id,
      scene: activeProject.scene,
      shot: activeProject.shot,
      take: activeProject.take,
      timecode: _timecode,
      createdAt: DateTime.now(),
      rating: rating,
    );
    try {
      await widget.controller.saveTake(take);
      if (rating != TakeRating.test) {
        await widget.controller.saveProject(
          activeProject.copyWith(
            scene: nextScene,
            shot: nextShot,
            take: nextTake,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_ratingLabel(rating)} take saved'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save take: $error')));
      }
    }
  }

  Future<void> _manualTake(int delta) async {
    final activeProject = project;
    if (activeProject == null) return;
    final next = (activeProject.take + delta).clamp(1, 9999);
    await widget.controller.saveProject(activeProject.copyWith(take: next));
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = project;
    if (activeProject == null) {
      return const Scaffold(body: Center(child: Text('Project unavailable')));
    }
    final fields = activeProject.fields;
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF111210),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth >= constraints.maxHeight;
              final large = constraints.maxHeight > 400;
              final slatePanel = Container(
                width: double.infinity,
                padding: EdgeInsets.all(large ? 19 : 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D201C),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .09),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: fields
                            .where((field) => field.visible)
                            .map(
                              (field) => _SlateValue(
                                label: field.label,
                                value: _fieldValue(
                                  activeProject,
                                  field.id,
                                  customValue: field.value,
                                ),
                                accent: Color(widget.controller.accent),
                                size: field.size,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFF68C991),
                          size: 7,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timecode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_now),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              final takeStepper = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 36,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _manualTake(-1),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white54,
                        size: 17,
                      ),
                    ),
                  ),
                  Text(
                    activeProject.take.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: Color(widget.controller.accent),
                      fontSize: landscape && large ? 38 : 29,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 36,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _manualTake(1),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white54,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              );
              final clapButton = SizedBox(
                width: double.infinity,
                height: landscape && large ? 56 : 44,
                child: FilledButton.icon(
                  onPressed: _clapping ? null : _clap,
                  icon: Icon(
                    _clapping ? Icons.check_rounded : Icons.campaign_rounded,
                    size: 19,
                  ),
                  label: Text(_clapping ? 'MARK!' : 'CLAP'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(widget.controller.accent),
                    foregroundColor: const Color(0xFF15140F),
                    textStyle: const TextStyle(
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
              final landscapeControls = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ROLLING TAKE',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 8,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  takeStepper,
                  SizedBox(height: large ? 13 : 6),
                  clapButton,
                ],
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: const Color(
                          0xFFC9A56A,
                        ).withValues(alpha: _flash.value * .16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      large ? 24 : 15,
                      large ? 14 : 7,
                      large ? 24 : 15,
                      12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                              ),
                              tooltip: 'Close slate',
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 9),
                            Icon(
                              Icons.movie_creation_outlined,
                              color: Color(widget.controller.accent),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeProject.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .8),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  fontSize: large ? 12 : 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: landscape
                              ? Row(
                                  children: [
                                    Expanded(flex: 5, child: slatePanel),
                                    const SizedBox(width: 13),
                                    Expanded(flex: 3, child: landscapeControls),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(flex: 5, child: slatePanel),
                                    const SizedBox(height: 9),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'ROLLING TAKE',
                                                  style: TextStyle(
                                                    color: _muted,
                                                    fontSize: 8,
                                                    letterSpacing: 1.4,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                takeStepper,
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(flex: 2, child: clapButton),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 6),
                        if (landscape)
                          Row(
                            children: [
                              Expanded(
                                child: _BottomMeta(
                                  label: 'DIRECTOR',
                                  value: activeProject.director,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _BottomMeta(
                                  label: 'DOP',
                                  value: activeProject.dop,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _BottomMeta(
                                  label: 'DIRECTOR',
                                  value: activeProject.director,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _BottomMeta(
                                  label: 'DOP',
                                  value: activeProject.dop,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            letterSpacing: .8,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _BottomMeta extends StatelessWidget {
  const _BottomMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '$label  ',
        style: const TextStyle(color: _muted, fontSize: 7, letterSpacing: 1),
      ),
      Flexible(
        child: Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _RatingAction extends StatelessWidget {
  const _RatingAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: color.withValues(alpha: .1),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    ),
  );
}

String _two(int value) => value.toString().padLeft(2, '0');

String _incrementCode(String value) {
  final match = RegExp(r'^(.*?)(\d+)$').firstMatch(value);
  if (match == null) return '${value}2';
  final digits = match.group(2)!;
  return '${match.group(1)}${(int.parse(digits) + 1).toString().padLeft(digits.length, '0')}';
}

Future<void> _exportProject(
  BuildContext context,
  AppController controller,
  FilmProject project,
) async {
  try {
    final takes = await controller.store.getTakes(project.id);
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TAKEONE',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#B48F56'),
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    project.name,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Production report  ·  ${project.productionDate}',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#777777'),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.Text(
                '${takes.length} TAKES',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#777777'),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 21),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F1EB'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Wrap(
              spacing: 30,
              runSpacing: 14,
              children: [
                _pdfInfo('DIRECTOR', project.director),
                _pdfInfo('DIRECTOR OF PHOTOGRAPHY', project.dop),
                _pdfInfo('LOCATION', project.location),
              ],
            ),
          ),
          if (project.notes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'PRODUCTION NOTES',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#888888'),
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(project.notes, style: const pw.TextStyle(fontSize: 10)),
          ],
          pw.SizedBox(height: 23),
          pw.Text(
            'TAKE HISTORY',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 9),
          if (takes.isEmpty)
            pw.Text(
              'No takes have been recorded.',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#777777'),
                fontSize: 10,
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'SCENE',
                'SHOT',
                'TAKE',
                'TIMECODE',
                'DATE / TIME',
                'RATING',
                'NOTES',
              ],
              data: takes
                  .map(
                    (take) => [
                      take.scene,
                      take.shot,
                      take.take.toString(),
                      take.timecode,
                      DateFormat('MMM d, yyyy  h:mm a').format(take.createdAt),
                      _ratingLabel(take.rating),
                      take.notes,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#272923'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 7,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(38),
                1: const pw.FixedColumnWidth(36),
                2: const pw.FixedColumnWidth(35),
                3: const pw.FixedColumnWidth(58),
                4: const pw.FixedColumnWidth(82),
                5: const pw.FixedColumnWidth(56),
              },
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F7F6F3'),
              ),
            ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Generated ${DateFormat('MMM d, yyyy  h:mm a').format(DateTime.now())}  ·  Page ${context.pageNumber}',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#888888'),
              fontSize: 8,
            ),
          ),
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          '${project.name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_take_log.pdf',
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export project PDF: $error')),
      );
    }
  }
}

pw.Widget _pdfInfo(String label, String value) => pw.SizedBox(
  width: 210,
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          color: PdfColor.fromHex('#777777'),
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        value.isEmpty ? '—' : value,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    ],
  ),
);

Future<void> _showAppearance(
  BuildContext context,
  AppController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your preferences are saved on this device.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            const _SectionEyebrow('THEME'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in [
                  ('cinema', 'Cinematic', Icons.movie_filter_outlined),
                  ('dark', 'Dark', Icons.dark_mode_outlined),
                  ('light', 'Light', Icons.light_mode_outlined),
                ])
                  ChoiceChip(
                    avatar: Icon(option.$3, size: 16),
                    label: Text(option.$2),
                    selected: controller.theme == option.$1,
                    onSelected: (_) => controller.setTheme(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionEyebrow('TYPEFACE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in [
                  ('modern', 'Modern'),
                  ('serif', 'Serif'),
                  ('mono', 'Monospace'),
                ])
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: controller.fontStyle == option.$1,
                    onSelected: (_) => controller.setFontStyle(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionEyebrow('ACCENT COLOR'),
            const SizedBox(height: 9),
            Wrap(
              spacing: 13,
              children: [
                for (final value in const [
                  0xFFC9A56A,
                  0xFF9C83D9,
                  0xFF5BAFA7,
                  0xFFE17968,
                  0xFF6D9FE4,
                ])
                  InkWell(
                    onTap: () => controller.setAccent(value),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: controller.accent == value
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: controller.accent == value
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.black,
                            )
                          : null,
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
