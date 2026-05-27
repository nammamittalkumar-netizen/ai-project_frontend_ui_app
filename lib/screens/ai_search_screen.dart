import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../providers/providers.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'AI Search',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          MainOverflowMenu(
            onNavigate: widget.onNavigate,
            currentIndex: widget.currentIndex,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: accentColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ask anything about your video footage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Show deliveries yesterday, or find after hours activity',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_query.isNotEmpty) ...[
            const _SectionTitle('Search Results'),
            if ((_results.isEmpty ? fallbackAlerts : _results).isEmpty)
              const _EmptyResult()
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
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${alert.cameraName} · ${DateFormat('MMM d, hh:mm a').format(alert.timestamp)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
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
                            const Icon(
                              Icons.play_circle_outline_rounded,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
          ],
          const _SectionTitle('Popular Searches'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((query) {
              return ActionChip(
                label: Text(query),
                avatar: const Icon(Icons.search_rounded, size: 18),
                backgroundColor: const Color(0xFF1A1A1A),
                side: const BorderSide(color: Color(0xFF2A2A2A)),
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () {
                  _controller.text = query;
                  _search();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _search() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      _query = value;
      _isSearching = true;
    });
    final config = ref.read(serverConfigProvider);
    final results = config.isDemo
        ? ref.read(alertsProvider).valueOrNull ?? const <Alert>[]
        : await ref.read(apiServiceProvider).searchAlerts(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Text(
        'No matching alerts yet. Connect your server or use demo mode to test results.',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
