import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _apiPortController = TextEditingController(text: '$defaultApiPort');
  final _streamPortController =
      TextEditingController(text: '$defaultStreamPort');

  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    _apiPortController.dispose();
    _streamPortController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final ip = _ipController.text.trim();
    final apiPort = int.parse(_apiPortController.text.trim());
    final streamPort = int.parse(_streamPortController.text.trim());
    final config = ServerConfig.fromParts(
      ip: ip,
      apiPort: apiPort,
      streamPort: streamPort,
    );

    final canConnect = await ApiService(
      baseUrl: config.apiUrl,
      streamUrl: config.streamUrl,
    ).checkHealth();

    if (!mounted) {
      return;
    }

    if (!canConnect) {
      setState(() {
        _isConnecting = false;
        _error = 'Cannot connect to server';
      });
      return;
    }

    await ref.read(serverConfigProvider.notifier).save(
          ip: ip,
          apiPort: apiPort,
          streamPort: streamPort,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  Future<void> _useDemoMode() async {
    await ref.read(serverConfigProvider.notifier).useDemoMode();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: accentColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Security Hub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect directly to your Mini PC server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _ipController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Mini PC IP address',
                              hintText: 'LAN IP or Tailscale IP',
                              prefixIcon: Icon(Icons.computer_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter the Mini PC IP address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _PortField(
                                  controller: _apiPortController,
                                  label: 'API port',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PortField(
                                  controller: _streamPortController,
                                  label: 'Stream port',
                                ),
                              ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isConnecting ? null : _connect,
                              icon: _isConnecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.link_rounded),
                              label: Text(
                                _isConnecting ? 'Connecting...' : 'Connect',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    accentColor.withValues(alpha: 0.45),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isConnecting ? null : _useDemoMode,
                              icon:
                                  const Icon(Icons.play_circle_outline_rounded),
                              label: const Text('Use Demo Mode'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF2A2A2A),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _HelperCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PortField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final port = int.tryParse(value ?? '');
        if (port == null || port < 1 || port > 65535) {
          return 'Invalid port';
        }
        return null;
      },
    );
  }
}

class _HelperCard extends StatelessWidget {
  const _HelperCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finding your Mini PC',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use the LAN IP shown in your router or Mini PC network settings when your phone is on the same Wi-Fi. If you use Tailscale, enter the Mini PC Tailscale IP from the Tailscale app or admin console.',
            style: TextStyle(color: Colors.grey, height: 1.35),
          ),
        ],
      ),
    );
  }
}
