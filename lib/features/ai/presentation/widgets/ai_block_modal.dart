import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../domain/ai_config.dart';

enum AIBlockAction { modify, translate, expand }

const _actionLabels = {
  AIBlockAction.modify: 'Modificar',
  AIBlockAction.translate: 'Traducir',
  AIBlockAction.expand: 'Expandir',
};

const _actionIcons = {
  AIBlockAction.modify: Icons.edit_outlined,
  AIBlockAction.translate: Icons.translate,
  AIBlockAction.expand: Icons.open_in_full,
};

const _modelLabels = {
  AIModel.claude: 'Claude',
  AIModel.gemini: 'Gemini',
  AIModel.gpt: 'GPT',
  AIModel.qwen: 'Qwen',
};

class AIBlockModal extends StatefulWidget {
  final String selectedText;
  final ValueChanged<String> onAccept;

  const AIBlockModal({
    super.key,
    required this.selectedText,
    required this.onAccept,
  });

  static Future<void> show(BuildContext context, {
    required String selectedText,
    required ValueChanged<String> onAccept,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => AIBlockModal(
        selectedText: selectedText,
        onAccept: onAccept,
      ),
    );
  }

  @override
  State<AIBlockModal> createState() => _AIBlockModalState();
}

class _AIBlockModalState extends State<AIBlockModal> {
  AIBlockAction _selectedAction = AIBlockAction.modify;
  AIModel _selectedModel = AIModel.gpt;
  final TextEditingController _instructionCtrl = TextEditingController();
  final engine = AIEngineService();

  String? _response;
  bool _isLoading = false;
  bool _cancelled = false;
  StreamSubscription<String>? _streamSub;

  @override
  void dispose() {
    _streamSub?.cancel();
    _instructionCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _response = null;
      _cancelled = false;
    });

    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt();

    _streamSub = engine.sendPromptStreaming(
      userPrompt,
      model: _selectedModel,
      systemOverride: systemPrompt,
    ).listen(
      (chunk) {
        if (!mounted || _cancelled) return;
        setState(() => _response = (_response ?? '') + chunk);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _response = 'Error: $e';
          _isLoading = false;
        });
      },
    );
  }

  void _cancel() {
    _cancelled = true;
    _streamSub?.cancel();
    setState(() => _isLoading = false);
  }

  String _buildSystemPrompt() {
    switch (_selectedAction) {
      case AIBlockAction.modify:
        return 'Eres un editor literario de alto nivel. '
            'Modifica el texto según las instrucciones del usuario. '
            'Preserva el estilo original del autor.';
      case AIBlockAction.translate:
        return 'Eres un traductor literario de alto nivel. '
            'Traduce el texto al idioma que indique el usuario. '
            'Preserva el tono, estilo y matices del original.';
      case AIBlockAction.expand:
        return 'Eres un escritor literario de alto nivel. '
            'Expande y desarrolla el texto según las instrucciones. '
            'Mantén coherencia con el estilo original.';
    }
  }

  String _buildUserPrompt() {
    final instruction = _instructionCtrl.text.trim();
    final base = 'TEXTO:\n${widget.selectedText}\n\n';
    if (instruction.isNotEmpty) {
      return '$base\nINSTRUCCIÓN:\n$instruction';
    }
    switch (_selectedAction) {
      case AIBlockAction.modify:
        return '$base\nPor favor mejora este texto manteniendo su esencia.';
      case AIBlockAction.translate:
        return '$base\nTraduce este texto al inglés.';
      case AIBlockAction.expand:
        return '$base\nDesarrolla y expande este texto añadiendo más contenido relevante.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0F).withOpacity(0.92),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(scheme),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionSelector(scheme),
                        const SizedBox(height: 16),
                        _buildModelSelector(scheme),
                        const SizedBox(height: 16),
                        _buildInstructionField(scheme),
                        if (_response != null || _isLoading) ...[
                          const SizedBox(height: 16),
                          _buildResponseSection(scheme),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildFooter(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            'Asistente IA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.white54),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Acción', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AIBlockAction.values.map((action) {
            final selected = _selectedAction == action;
            return GestureDetector(
              onTap: () => setState(() => _selectedAction = action),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? scheme.primary.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _actionIcons[action],
                      size: 14,
                      color: selected ? scheme.primary : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _actionLabels[action]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? scheme.primary : Colors.white70,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModelSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Modelo', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AIModel.values.map((model) {
            final selected = _selectedModel == model;
            return GestureDetector(
              onTap: () => setState(() => _selectedModel = model),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF7B2CBF).withOpacity(0.2) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? const Color(0xFF7B2CBF).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  _modelLabels[model]!,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? const Color(0xFF7B2CBF) : Colors.white54,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInstructionField(ColorScheme scheme) {
    return TextField(
      controller: _instructionCtrl,
      maxLines: 2,
      minLines: 1,
      style: TextStyle(fontSize: 13, color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Instrucción adicional (opcional)...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildResponseSection(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'Respuesta',
                style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600),
              ),
              if (_isLoading) ...[
                const Spacer(),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _response ?? (_isLoading ? 'Generando...' : ''),
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (_isLoading)
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
              ),
            )
          else ...[
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: _response != null ? _generate : null,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Regenerar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: _response != null && !_isLoading
                  ? () {
                      widget.onAccept(_response!);
                      Navigator.of(context).pop();
                    }
                  : null,
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Aceptar', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
