import 'dart:async';
import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:empatia/features/profile/data/models/state_model.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:flutter/material.dart';

/// 📍 LOCATION SECTION
///
/// Widget reutilizável para escolher Estado, Cidade e Bairro.
///
/// IMPORTANTE — bairro válido:
/// O usuário DEVE selecionar o bairro a partir da lista de sugestões.
/// Digitar livremente não confirma as coordenadas. Use [neighborhoodConfirmed]
/// para saber se o bairro foi escolhido corretamente antes de salvar.
class LocationSection extends StatefulWidget {
  final LocationService locationService;
  final String? selectedState;
  final String? selectedCity;
  final TextEditingController neighborhoodController;
  final Function(String) onStateChanged;
  final Function(String?) onCityChanged;

  /// Chamado quando o usuário seleciona um bairro da lista,
  /// ou quando as coordenadas são limpas (passa null, null).
  final Function(double?, double?)? onCoordinatesChanged;

  /// Chamado sempre que o estado de confirmação do bairro muda.
  /// [confirmed] = true  → bairro foi escolhido da lista.
  /// [confirmed] = false → usuário editou o texto manualmente.
  final Function(bool confirmed)? onNeighborhoodConfirmed;

  const LocationSection({
    Key? key,
    required this.locationService,
    required this.selectedState,
    required this.selectedCity,
    required this.neighborhoodController,
    required this.onStateChanged,
    required this.onCityChanged,
    this.onCoordinatesChanged,
    this.onNeighborhoodConfirmed,
  }) : super(key: key);

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  // ── Estado interno ──────────────────────────────────────────
  List<CityModel> _cidades              = [];
  bool            _loadingCidades       = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool            _loadingNeighborhoods = false;
  Timer?          _debounce;
  double?         _cityLat;
  double?         _cityLng;

  /// true = bairro foi selecionado da lista; false = texto livre
  bool _neighborhoodConfirmed = false;

  // ── Design tokens ───────────────────────────────────────────
  static const _pink   = Color(0xFFFF6B9D);
  static const _navy   = Color(0xFF1E3A8A);
  static const _amber  = Color(0xFFFFC837);
  static const _purple = Color(0xFF8B5CF6);

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    widget.neighborhoodController.addListener(_onNeighborhoodTyped);
    if (widget.selectedState != null) _loadCidades(widget.selectedState!);

    // Se já vem com bairro preenchido do banco, marca como confirmado
    if (widget.neighborhoodController.text.trim().isNotEmpty) {
      _neighborhoodConfirmed = true;
    }
  }

  @override
  void dispose() {
    widget.neighborhoodController.removeListener(_onNeighborhoodTyped);
    _debounce?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // LÓGICA DE BAIRRO
  // ══════════════════════════════════════════════════════════

  /// Chamado sempre que o usuário DIGITA no campo.
  /// Digitar invalida a confirmação anterior.
  void _onNeighborhoodTyped() {
    // Se estava confirmado e o usuário editou, invalida
    if (_neighborhoodConfirmed) {
      _neighborhoodConfirmed = false;
      widget.onNeighborhoodConfirmed?.call(false);
      widget.onCoordinatesChanged?.call(null, null);
    }

    setState(() {}); // atualiza botão X e preview

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      final text = widget.neighborhoodController.text.trim();
      if (text.length > 2 && widget.selectedCity != null) {
        _searchNeighborhoods(text);
      } else if (mounted) {
        setState(() => _suggestions = []);
      }
    });
  }

  /// Chamado quando o usuário TOCA em um item da lista de sugestões.
  void _onNeighborhoodSelected(Map<String, dynamic> suggestion) {
    final name = (suggestion['neighborhood'] ?? '')
        .replaceAll('\n', ' ')
        .trim() as String;

    // Atualiza o controller sem disparar _onNeighborhoodTyped
    widget.neighborhoodController.removeListener(_onNeighborhoodTyped);
    widget.neighborhoodController.text = name;
    widget.neighborhoodController.addListener(_onNeighborhoodTyped);

    setState(() {
      _suggestions           = [];
      _neighborhoodConfirmed = true;
    });

    widget.onNeighborhoodConfirmed?.call(true);
    widget.onCoordinatesChanged?.call(_cityLat, _cityLng);
  }

  // ══════════════════════════════════════════════════════════
  // LÓGICA DE LOCALIZAÇÃO
  // ══════════════════════════════════════════════════════════

  Future<void> _loadCidades(String sigla) async {
    setState(() { _loadingCidades = true; _cidades = []; });
    final cidades = await widget.locationService.getCidades(sigla);
    if (mounted) setState(() { _cidades = cidades; _loadingCidades = false; });
  }

  Future<void> _fetchCityCoordinates() async {
    if (widget.selectedCity == null || widget.selectedState == null) return;
    final coords = await widget.locationService.getCityCoordinates(
      city: widget.selectedCity!,
      state: widget.selectedState!,
    );
    if (coords != null) {
      _cityLat = coords['lat'];
      _cityLng = coords['lng'];
    }
  }

  Future<void> _searchNeighborhoods(String query) async {
    if (widget.selectedCity == null || widget.selectedState == null) return;
    if (mounted) setState(() => _loadingNeighborhoods = true);

    try {
      if (_cityLat == null || _cityLng == null) await _fetchCityCoordinates();

      // Descarta se o texto mudou enquanto aguardava
      if (widget.neighborhoodController.text.trim() != query) {
        if (mounted) setState(() => _loadingNeighborhoods = false);
        return;
      }

      final suggestions = await widget.locationService.searchNeighborhoods(
        query: query,
        city: widget.selectedCity!,
        state: widget.selectedState!,
        lat: _cityLat,
        lng: _cityLng,
      );

      if (!mounted) return;
      if (widget.neighborhoodController.text.trim() != query) {
        setState(() => _loadingNeighborhoods = false);
        return;
      }

      setState(() {
        _suggestions           = suggestions;
        _loadingNeighborhoods  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNeighborhoods = false);
    }
  }

  void _clearNeighborhood() {
    widget.neighborhoodController.removeListener(_onNeighborhoodTyped);
    widget.neighborhoodController.clear();
    widget.neighborhoodController.addListener(_onNeighborhoodTyped);

    setState(() {
      _suggestions           = [];
      _neighborhoodConfirmed = false;
    });
    widget.onNeighborhoodConfirmed?.call(false);
    widget.onCoordinatesChanged?.call(null, null);
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────
        Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Localização',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 10),

        // ── Container com os 3 campos ───────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              _buildRow(
                icon: '🗺️', label: 'Estado',
                child: _buildEstadoDropdown(), showDivider: true,
              ),
              _buildRow(
                icon: '🏙️', label: 'Cidade',
                child: _buildCidadeDropdown(), showDivider: true,
              ),
              _buildRow(
                icon: '🏘️', label: 'Bairro',
                child: _buildBairroField(), showDivider: false,
              ),
            ],
          ),
        ),

        // ── Aviso: bairro não selecionado da lista ──────────
        if (widget.neighborhoodController.text.trim().isNotEmpty &&
            !_neighborhoodConfirmed)
          _buildNeighborhoodWarning(),

        // ── Sugestões ───────────────────────────────────────
        if (_suggestions.isNotEmpty) _buildSuggestions(),

        // ── Preview do endereço ─────────────────────────────
        if (_neighborhoodConfirmed &&
            widget.neighborhoodController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildEnderecoPreview(),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // WIDGETS INTERNOS
  // ══════════════════════════════════════════════════════════

  Widget _buildRow({
    required String icon,
    required String label,
    required Widget child,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500)),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1, thickness: 1,
            color: _pink.withOpacity(0.1),
            indent: 16, endIndent: 16,
          ),
      ],
    );
  }

  Widget _buildEstadoDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.selectedState,
        hint: Text('Selecione',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.expand_more_rounded, color: _pink, size: 20),
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
        items: estadosBrasileiros.map((e) {
          return DropdownMenuItem<String>(
            value: e['sigla'],
            child: Text('${e['sigla']} — ${e['nome']}'),
          );
        }).toList(),
        onChanged: (sigla) {
          if (sigla == null) return;
          widget.onStateChanged(sigla);
          _loadCidades(sigla);
          setState(() {
            _cityLat = null;
            _cityLng = null;
            _suggestions = [];
          });
          _clearNeighborhood();
        },
      ),
    );
  }

  Widget _buildCidadeDropdown() {
    if (widget.selectedState == null) {
      return Text('Selecione o estado',
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500));
    }
    if (_loadingCidades) {
      return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _pink));
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.selectedCity,
        hint: Text('Selecione',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.expand_more_rounded, color: _pink, size: 20),
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
        items: _cidades.map((c) {
          return DropdownMenuItem<String>(value: c.nome, child: Text(c.nome));
        }).toList(),
        onChanged: (cidade) {
          widget.onCityChanged(cidade);
          setState(() {
            _cityLat = null;
            _cityLng = null;
            _suggestions = [];
          });
          _clearNeighborhood();
          if (cidade != null) _fetchCityCoordinates();
        },
      ),
    );
  }

  Widget _buildBairroField() {
    final hasText = widget.neighborhoodController.text.isNotEmpty;
    return TextField(
      controller: widget.neighborhoodController,
      enabled: widget.selectedCity != null,
      maxLines: 1, // ✅ impede quebra de linha no campo
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _navy,
          overflow: TextOverflow.ellipsis), // ✅ trunca com ... se muito longo
      decoration: InputDecoration(
        hintText: widget.selectedCity == null
            ? 'Selecione a cidade'
            : 'Digite para buscar...',
        hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        suffixIcon: _loadingNeighborhoods
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _pink)),
              )
            : hasText
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        size: 18, color: Colors.grey.shade400),
                    onPressed: _clearNeighborhood,
                  )
                : null,
      ),
    );
  }

  /// Aviso laranja que aparece quando o usuário digitou mas não selecionou
  /// um bairro da lista.
  Widget _buildNeighborhoodWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Selecione o bairro na lista para garantir a localização correta.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: _suggestions.take(5).map((s) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined,
                color: _pink, size: 18),
            title: Text(
              s['neighborhood'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // ✅ trunca nome do bairro na lista
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
            ),
            subtitle: Text(
              s['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // ✅ trunca descrição na lista
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () => _onNeighborhoodSelected(s),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnderecoPreview() {
    final partes = <String>[];
    final bairro = widget.neighborhoodController.text.trim();
    if (bairro.isNotEmpty) partes.add(bairro);
    if (widget.selectedCity != null) partes.add(widget.selectedCity!);
    if (widget.selectedState != null) partes.add(widget.selectedState!);
    final endereco = partes.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _pink.withOpacity(0.08),
            _purple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pink.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('📬', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              endereco,
              maxLines: 2,                        // ✅ no máximo 2 linhas
              overflow: TextOverflow.ellipsis,    // ✅ ... se passar de 2 linhas
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navy),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 18),
        ],
      ),
    );
  }
}