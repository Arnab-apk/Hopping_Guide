import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../widgets/pandal_detail_sheet.dart';

/// Pandal detail screen supporting direct link access, route arguments,
/// or looking up by ID from [LocalAssetPandalRepository].
class PandalDetailScreen extends StatelessWidget {
  const PandalDetailScreen({super.key, this.pandalId, this.pandal});

  final String? pandalId;
  final Pandal? pandal;

  @override
  Widget build(BuildContext context) {
    if (pandal != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(pandal!.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: PandalDetailSheet(pandal: pandal!),
        ),
      );
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Pandal) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(routeArgs.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: PandalDetailSheet(pandal: routeArgs),
        ),
      );
    }

    final id = pandalId ?? (routeArgs is String ? routeArgs : null);
    if (id != null && id.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Pandal Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Pandal?>(
          future: LocalAssetPandalRepository().byId(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final foundPandal = snapshot.data;
            if (foundPandal == null) {
              return Center(
                child: Text(
                  'Pandal not found (ID: $id)',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }
            return SingleChildScrollView(
              child: PandalDetailSheet(pandal: foundPandal),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pandal Detail')),
      body: const Center(
        child: Text('No pandal specified'),
      ),
    );
  }
}
