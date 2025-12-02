import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddRatingResult {
  final int score;
  final String? comment;

  final String locationType;
  final String address;
  final String cep;
  final double? buyPrice;
  final double? rentPrice;
  final List<String> listingLinks;
  final List<String> photoUrls;
  final int? bedrooms;
  final double? areaM2;
  final int? bathrooms;

  /// Imagens escolhidas localmente para upload
  final List<XFile> localImages;

  const AddRatingResult({
    required this.score,
    this.comment,
    required this.locationType,
    required this.address,
    required this.cep,
    this.buyPrice,
    this.rentPrice,
    required this.listingLinks,
    required this.photoUrls,
    this.bedrooms,
    this.areaM2,
    this.bathrooms,
    required this.localImages,
  });
}

class AddRatingSheet extends StatefulWidget {
  final String areaName;

  /// Valores iniciais para auto-preencher conforme área clicada
  final String? initialLocationType;
  final String? initialAddress;
  final String? initialCep;

  const AddRatingSheet({
    super.key,
    required this.areaName,
    this.initialLocationType,
    this.initialAddress,
    this.initialCep,
  });

  @override
  State<AddRatingSheet> createState() => _AddRatingSheetState();
}

class _AddRatingSheetState extends State<AddRatingSheet> {
  int _score = 5;

  final _commentController = TextEditingController();
  final _addressController = TextEditingController();
  final _cepController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _rentPriceController = TextEditingController();
  final _linksController = TextEditingController();
  final _photosController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _bathroomsController = TextEditingController();

  late String _locationType;
  String? _errorText;

  final _picker = ImagePicker();
  final List<XFile> _images = [];

  bool get _showPropertyFields =>
      _locationType == 'imovel' || _locationType == 'condominio';

  @override
  void initState() {
    super.initState();
    _locationType = widget.initialLocationType ?? 'imovel';
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialCep != null && widget.initialCep!.isNotEmpty) {
      _cepController.text = widget.initialCep!;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _addressController.dispose();
    _cepController.dispose();
    _buyPriceController.dispose();
    _rentPriceController.dispose();
    _linksController.dispose();
    _photosController.dispose();
    _bedroomsController.dispose();
    _areaController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() {
        _images.addAll(picked);
      });
    } catch (e) {
      setState(() {
        _errorText = 'Erro ao selecionar imagens: $e';
      });
    }
  }

  void _submit() {
    final address = _addressController.text.trim();
    final cep = _cepController.text.trim();

    if (address.isEmpty || cep.isEmpty) {
      setState(() {
        _errorText = 'Preencha endereço e CEP.';
      });
      return;
    }

    double? parsePrice(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      final normalized = t.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    int? parseInt(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    double? parseDouble(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      final normalized = t.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    List<String> parseLines(String text) {
      return text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final buyPrice =
        _showPropertyFields ? parsePrice(_buyPriceController.text) : null;
    final rentPrice =
        _showPropertyFields ? parsePrice(_rentPriceController.text) : null;
    final bedrooms =
        _showPropertyFields ? parseInt(_bedroomsController.text) : null;
    final areaM2 =
        _showPropertyFields ? parseDouble(_areaController.text) : null;
    final bathrooms =
        _showPropertyFields ? parseInt(_bathroomsController.text) : null;

    final links = _showPropertyFields
        ? parseLines(_linksController.text)
        : <String>[];

    final photos = parseLines(_photosController.text);

    Navigator.of(context).pop(
      AddRatingResult(
        score: _score,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        locationType: _locationType,
        address: address,
        cep: cep,
        buyPrice: buyPrice,
        rentPrice: rentPrice,
        listingLinks: links,
        photoUrls: photos,
        bedrooms: bedrooms,
        areaM2: areaM2,
        bathrooms: bathrooms,
        localImages: List<XFile>.from(_images),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(16, 16, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER COM TÍTULO + BOTÃO X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Nova avaliação em ${widget.areaName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nota
            const Text('Nota'),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _score;
                return IconButton(
                  onPressed: () => setState(() => _score = i + 1),
                  icon: Icon(filled ? Icons.star : Icons.star_border),
                  color: filled ? Colors.amber[700] : Colors.grey[600],
                );
              }),
            ),
            const SizedBox(height: 8),

            // Tipo de local
            const Text('Tipo de local'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _locationType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'imovel',
                  child: Text('Imóvel'),
                ),
                DropdownMenuItem(
                  value: 'condominio',
                  child: Text('Condomínio'),
                ),
                DropdownMenuItem(
                  value: 'bairro',
                  child: Text('Bairro'),
                ),
                DropdownMenuItem(
                  value: 'cidade',
                  child: Text('Cidade'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _locationType = v);
              },
            ),
            const SizedBox(height: 12),

            // Endereço
            const Text('Endereço'),
            const SizedBox(height: 4),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Rua, número, complemento...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // CEP
            const Text('CEP'),
            const SizedBox(height: 4),
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 89251-000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Comentário
            const Text('Comentário (opcional)'),
            const SizedBox(height: 4),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Escreva um comentário curto...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Preços (somente imóvel/condomínio)
            if (_showPropertyFields) ...[
              const Text('Preços (opcional)'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Compra (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rentPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Aluguel (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Dados do imóvel (somente imóvel/condomínio)
            if (_showPropertyFields) ...[
              const Text('Dados do imóvel (opcional)'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quartos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Banheiros',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _areaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Área (m²)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Links (somente imóvel/condomínio)
            if (_showPropertyFields) ...[
              const Text('Links de imobiliárias (opcional)'),
              const SizedBox(height: 4),
              TextField(
                controller: _linksController,
                decoration: const InputDecoration(
                  hintText: 'Uma URL por linha',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
            ],

            // Fotos (todos os tipos)
            const Text('Fotos do local (opcional)'),
            const SizedBox(height: 4),
            TextField(
              controller: _photosController,
              decoration: const InputDecoration(
                hintText: 'URLs de fotos (uma por linha)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(
                _images.isEmpty
                    ? 'Selecionar imagens'
                    : 'Selecionar mais imagens (${_images.length} selecionadas)',
              ),
            ),
            const SizedBox(height: 4),
            if (_images.isNotEmpty)
              Text(
                '${_images.length} imagem(ns) selecionada(s) para upload.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 12),

            if (_errorText != null) ...[
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Salvar avaliação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
