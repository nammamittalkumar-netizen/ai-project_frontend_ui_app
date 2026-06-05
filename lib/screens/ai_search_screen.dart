import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui.dart';
import '../widgets/alert_popup.dart';
import '../widgets/main_overflow_menu.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigate;
  final int currentIndex;

  const AiSearchScreen({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<Alert> _results = const [];
  bool _isSearching = false;

  static const _popularSearches = [
    'Fire detections this week',
    'Suspicious activity today',
    'Fall detected yesterday',
    'Smoke alerts this month',
    'Camera offline events',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackAlerts = ref.watch(alertsProvider).valueOrNull ?? [];
    final accentColor = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          MainOverflowMenu(
            onNavigate: widget.onNavigate,
            currentIndex: widget.currentIndex,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
        children: [
          const AppHeader(
            title: 'AI Search',
            subtitle: 'Ask anything about your footage',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: appCard(colors),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [appAccentLime, appAccentBlue],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: appOnFilled,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ask anything about your video footage',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  style: TextStyle(color: colors.onSurface),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Show deliveries yesterday, or find after hours activity',
                  ),
                  onSubmitted: (_) => _search(),
                ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _search,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      label: Text(_isSearching ? 'Searching...' : 'Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: appButtonShape,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (_query.isNotEmpty) ...[
            const AppSectionTitle('Search Results'),
            if ((_results.isEmpty ? fallbackAlerts : _results).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyResult(),
              )
            else
              ...(_results.isEmpty ? fallbackAlerts : _results).map(
                (alert) => GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertPopup(alert: alert),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: appCard(colors, radius: kTileRadius),
                    child: Row(
                      children: [
                        Icon(alert.typeIcon, color: alert.typeColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.typeLabel,
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${alert.displaySource} · ${DateFormat('MMM d, hh:mm a').format(alert.timestamp)}',
                                style: TextStyle(
                                  color: colors.onSurfaceDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (alert.confidence > 0)
                          Text(
                            '${(alert.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.play_circle_outline_rounded,
                          color: colors.onSurfaceDim,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
          const AppSectionTitle('Popular Searches'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _popularSearches.map((query) {
                return ActionChip(
                  label: Text(query),
                  avatar: const Icon(Icons.search_rounded, size: 18),
                  backgroundColor: colors.surface,
                  side: BorderSide(color: colors.border),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(color: colors.onSurface),
                  iconTheme: IconThemeData(color: colors.onSurfaceDim),
                  onPressed: () {
                    _controller.text = query;
                    _search();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _search() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _query = value;
      _isSearching = true;
    });
    final config = ref.read(serverConfigProvider);
    final results = config.isDemo
        ? ref.read(alertsProvider).valueOrNull ?? const <Alert>[]
        : await ref.read(apiServiceProvider).searchAlerts(value);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }
}

class _EmptyResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appCard(colors, radius: kTileRadius),
      child: Text(
        'No matching alerts yet. Connect your server or use demo mode to test results.',
        style: TextStyle(color: colors.onSurfaceDim),
      ),
    );
  }
}
