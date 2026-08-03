import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/multimodal_network.dart';
import '../../../data/models/bus_stop.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/trip_planner_providers.dart';
import '../../../services/geolocation_service.dart';
import '../widgets/transport_mode_filter_sheet.dart';
import 'trip_results_screen.dart';

enum _ActiveField { none, origin, destination }

/// Écran de recherche multimodale : origine/destination (avec géolocalisation
/// automatique), planification "maintenant / plus tard", filtres de mode et
/// de confort.
class TripSearchScreen extends ConsumerStatefulWidget {
  const TripSearchScreen({super.key});

  @override
  ConsumerState<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends ConsumerState<TripSearchScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  _ActiveField _activeField = _ActiveField.none;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final origin = ref.read(originProvider);
    if (origin != null) _originController.text = origin.label;
    final destination = ref.read(destinationProvider);
    if (destination != null) _destinationController.text = destination.label;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  List<BusStop> get _suggestions {
    final controller =
        _activeField == _ActiveField.origin ? _originController : _destinationController;
    final query = controller.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return MultimodalNetwork.allKnownLocations
        .where((s) => s.name.toLowerCase().contains(query))
        .take(6)
        .toList();
  }

  void _selectLocation(BusStop stop) {
    final point = TripPoint(stop.position, stop.name);
    if (_activeField == _ActiveField.origin) {
      _originController.text = stop.name;
      ref.read(originProvider.notifier).state = point;
    } else if (_activeField == _ActiveField.destination) {
      _destinationController.text = stop.name;
      ref.read(destinationProvider.notifier).state = point;
    }
    setState(() => _activeField = _ActiveField.none);
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentPosition() async {
    setState(() => _locating = true);
    final result = await ref.refresh(currentPositionProvider.future);
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case LocationSuccess(:final position):
        const label = 'Ma position actuelle';
        _originController.text = label;
        ref.read(originProvider.notifier).state = TripPoint(position, label);
        setState(() => _activeField = _ActiveField.none);
      case LocationFailure(:final reason):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  void _swap() {
    final origin = ref.read(originProvider);
    final destination = ref.read(destinationProvider);
    ref.read(originProvider.notifier).state = destination;
    ref.read(destinationProvider.notifier).state = origin;
    _originController.text = destination?.label ?? '';
    _destinationController.text = origin?.label ?? '';
  }

  Future<void> _pickDepartureTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !mounted) return;

    ref.read(departAtProvider.notifier).state =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(authControllerProvider).phone!;
    final origin = ref.watch(originProvider);
    final destination = ref.watch(destinationProvider);
    final departAt = ref.watch(departAtProvider);
    final textTheme = Theme.of(context).textTheme;

    final canSearch = origin != null && destination != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Planifier un trajet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _LocationField(
              controller: _originController,
              hint: 'Point de départ',
              icon: Icons.trip_origin,
              trailing: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Utiliser ma position',
                      onPressed: _useCurrentPosition,
                    ),
              onTap: () => setState(() => _activeField = _ActiveField.origin),
              onChanged: (_) => setState(() => _activeField = _ActiveField.origin),
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                const Expanded(child: Divider()),
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Inverser',
                  onPressed: _swap,
                ),
              ],
            ),
            _LocationField(
              controller: _destinationController,
              hint: "Destination",
              icon: Icons.flag_outlined,
              onTap: () => setState(() => _activeField = _ActiveField.destination),
              onChanged: (_) => setState(() => _activeField = _ActiveField.destination),
            ),
            if (_activeField != _ActiveField.none && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Material(
                color: AppColors.sableCarte,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final stop in _suggestions)
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(stop.name),
                        onTap: () => _selectLocation(stop),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Maintenant'),
                    selected: departAt == null,
                    onSelected: (_) => ref.read(departAtProvider.notifier).state = null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      departAt == null
                          ? 'Plus tard'
                          : DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(departAt),
                    ),
                    selected: departAt != null,
                    onSelected: (_) => _pickDepartureTime(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showTransportModeFilterSheet(context, phone: phone),
              icon: const Icon(Icons.tune),
              label: const Text('Filtres (modes, confort, marche)'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: canSearch
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TripResultsScreen()),
                      )
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Rechercher'),
              ),
            ),
            if (!canSearch) ...[
              const SizedBox(height: 10),
              Text(
                'Choisissez un point de départ et une destination.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.charbonChaud.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.trailing,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: trailing,
      ),
    );
  }
}
