import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/widgets/treballador_widgets.dart';

class TreballadorProfileScreen extends StatefulWidget {
  final int? treballadorId;

  const TreballadorProfileScreen({
    super.key,
    this.treballadorId,
  });

  @override
  State<TreballadorProfileScreen> createState() =>
      _TreballadorProfileScreenState();
}

class _TreballadorProfileScreenState extends State<TreballadorProfileScreen> {
  late final TreballadorService _service;
  late Future<TreballadorProfileData> _futureProfile;

  static String get _apiBase {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: _apiBase);
    _futureProfile = _loadProfile();
  }

  Future<TreballadorProfileData> _loadProfile() {
    if (widget.treballadorId != null) {
      return _service.fetchTreballadorProfile(widget.treballadorId!);
    }
    return _service.fetchMyProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _futureProfile = _loadProfile();
    });
    await _futureProfile;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Perfil del treballador'),
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<TreballadorProfileData>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileLoadingView();
          }

          if (snapshot.hasError) {
            return _ProfileErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _ProfileErrorView(
              message: 'No s’han rebut dades del perfil.',
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                TreballadorHeaderCard(profile: profile),
                const SizedBox(height: 16),
                TreballadorContactCard(profile: profile),
                const SizedBox(height: 16),
                TreballadorSummaryCard(profile: profile),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        TreballadorLoadingCard(),
        SizedBox(height: 16),
        TreballadorLoadingCard(),
        SizedBox(height: 16),
        TreballadorLoadingCard(),
      ],
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        TreballadorErrorCard(
          message: message,
          onRetry: () {
            onRetry();
          },
        ),
      ],
    );
  }
}