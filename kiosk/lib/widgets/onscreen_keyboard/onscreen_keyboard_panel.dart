import 'package:flutter/material.dart';

import '../../styles/color_set.dart';
import '../../theme/pos_design.dart';
import 'onscreen_keyboard.dart';

/// The docked QWERTY panel for [OnScreenKeyboard].
///
/// Laid out entirely with [Expanded] rows and keys so it fills whatever height
/// [OnScreenKeyboardScope] gives it without hard-coded pixel sizes — the kiosk
/// runs at several fixed resolutions (1366x768 through 1920x1080) and this has
/// to stay touch-sized at all of them.
///
/// Keys are [GestureDetector]s rather than [InkWell]/[ElevatedButton] on
/// purpose: a focusable key would steal focus from the very field it's typing
/// into. The panel is additionally wrapped in a [FocusScope] that can't request
/// focus, and in a [TextFieldTapRegion] by the scope, so tapping a key never
/// counts as a tap "outside" the focused field.
class OnScreenKeyboardPanel extends StatefulWidget {
  const OnScreenKeyboardPanel({super.key});

  @override
  State<OnScreenKeyboardPanel> createState() => _OnScreenKeyboardPanelState();
}

class _OnScreenKeyboardPanelState extends State<OnScreenKeyboardPanel> {
  bool _shifted = false;
  bool _symbols = false;

  static const List<List<String>> _letterRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  static const List<List<String>> _symbolRows = [
    ['[', ']', '{', '}', '#', '%', '^', '*', '+', '='],
    ['-', '/', ':', ';', '(', ')', r'$', '&', '@', '"'],
    ['_', r'\', '|', '~', '<', '>', '!', '?', "'"],
    ['.', ',', '`', '°', '£', '€', '₱'],
  ];

  void _onKey(String key) {
    OnScreenKeyboard.insert(_shifted && !_symbols ? key.toUpperCase() : key);
    // Shift is one-shot, like a phone keyboard — it releases after one letter.
    if (_shifted) setState(() => _shifted = false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _symbols ? _symbolRows : _letterRows;

    return FocusScope(
      canRequestFocus: false,
      // Material is required, not decorative: the panel is a sibling of the
      // Navigator (it lives in MaterialApp's `builder`), so without one there
      // is no Material ancestor and every key label inherits WidgetsApp's
      // fallback text style — which draws the yellow double underline.
      child: Material(
        color: POSColors.surfaceOverlay,
        child: DecoratedBox(
          decoration: const BoxDecoration(boxShadow: POSShadow.panel),
          child: Padding(
            padding: const EdgeInsets.all(POSSpacing.sm),
            child: Column(
              children: [
                for (final row in rows)
                  Expanded(
                    child: Row(
                      children: [
                        if (row == rows[2]) const Spacer(flex: 1),
                        if (row == rows[3]) _ShiftKey(
                          active: _shifted,
                          onTap: () => setState(() => _shifted = !_shifted),
                        ),
                        for (final key in row)
                          _Key(
                            label: _shifted && !_symbols ? key.toUpperCase() : key,
                            onTap: () => _onKey(key),
                          ),
                        if (row == rows[2]) const Spacer(flex: 1),
                        if (row == rows[3])
                          _Key(
                            flex: 3,
                            onTap: OnScreenKeyboard.backspace,
                            child: const Icon(
                              Icons.backspace_outlined,
                              size: 22,
                              color: POSColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(child: _BottomRow(
                  symbols: _symbols,
                  onToggleSymbols: () => setState(() => _symbols = !_symbols),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.symbols, required this.onToggleSymbols});

  final bool symbols;
  final VoidCallback onToggleSymbols;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Key(
          flex: 3,
          onTap: onToggleSymbols,
          child: Text(
            symbols ? 'ABC' : '?123',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
        ),
        _Key(label: '@', onTap: () => OnScreenKeyboard.insert('@')),
        _Key(
          flex: 2,
          onTap: () => OnScreenKeyboard.moveCaret(-1),
          child: const Icon(Icons.chevron_left, size: 24, color: POSColors.textSecondary),
        ),
        _Key(
          flex: 8,
          onTap: () => OnScreenKeyboard.insert(' '),
          child: const Text(
            'space',
            style: TextStyle(fontSize: 14, color: POSColors.textTertiary),
          ),
        ),
        _Key(
          flex: 2,
          onTap: () => OnScreenKeyboard.moveCaret(1),
          child: const Icon(Icons.chevron_right, size: 24, color: POSColors.textSecondary),
        ),
        _Key(label: '.', onTap: () => OnScreenKeyboard.insert('.')),
        _Key(
          flex: 3,
          primary: true,
          onTap: OnScreenKeyboard.submit,
          child: const Text(
            'Done',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        _Key(
          flex: 2,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            OnScreenKeyboard.hide();
          },
          child: const Icon(
            Icons.keyboard_hide_outlined,
            size: 22,
            color: POSColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ShiftKey extends StatelessWidget {
  const _ShiftKey({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Key(
      flex: 3,
      active: active,
      onTap: onTap,
      child: Icon(
        active ? Icons.keyboard_capslock : Icons.arrow_upward,
        size: 20,
        color: active ? ColorSet.primary : POSColors.textSecondary,
      ),
    );
  }
}

/// A single key. [flex] widens modifier keys relative to letter keys.
class _Key extends StatefulWidget {
  const _Key({
    this.label,
    this.child,
    required this.onTap,
    this.flex = 2,
    this.primary = false,
    this.active = false,
  });

  final String? label;
  final Widget? child;
  final VoidCallback onTap;
  final int flex;
  final bool primary;
  final bool active;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color background;
    if (widget.primary) {
      background = _pressed ? ColorSet.primary.withValues(alpha: 0.82) : ColorSet.primary;
    } else if (widget.active) {
      background = ColorSet.primary.withValues(alpha: 0.14);
    } else {
      background = _pressed ? POSColors.surfaceSubtle : POSColors.surfaceBase;
    }

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: POSAnimation.fast,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(POSRadius.sm),
              boxShadow: _pressed ? null : POSShadow.card,
            ),
            child: Center(
              child: widget.child ??
                  Text(
                    widget.label ?? '',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: POSColors.textPrimary,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
