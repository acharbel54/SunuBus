import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/bus_providers.dart';

/// Champ de recherche permettant de trouver un arrêt par son nom.
class SearchStopField extends ConsumerStatefulWidget {
  const SearchStopField({super.key});

  @override
  ConsumerState<SearchStopField> createState() => _SearchStopFieldState();
}

class _SearchStopFieldState extends ConsumerState<SearchStopField> {
  late final TextEditingController _controller =
      TextEditingController(text: ref.read(stopSearchQueryProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(stopSearchQueryProvider);

    return TextField(
      controller: _controller,
      onChanged: (value) => ref.read(stopSearchQueryProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: 'Rechercher un arrêt (ex: Guédiawaye)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(stopSearchQueryProvider.notifier).state = '';
                },
              ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}
