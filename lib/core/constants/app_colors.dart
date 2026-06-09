import 'package:flutter/material.dart';

/// NamkhaZoe Design Tokens — matched exactly to NZ object in data.jsx
class NZColors {
  NZColors._();

  // ── Core Brand ──
  static const maroon     = Color(0xFF6B1414);
  static const maroonLight= Color(0xFF8B2020);
  static const maroonDark = Color(0xFF4A0E0E);

  static const gold       = Color(0xFFB8860B);
  static const goldLight  = Color(0xFFD4A830);
  static const goldDim    = Color(0x1FB8860B); // rgba(184,134,11,0.12)

  static const saffron    = Color(0xFFC8700A);
  static const saffronLight = Color(0xFFE8920E);

  static const cream      = Color(0xFFF5EFE0);
  static const creamDark  = Color(0xFFE8DBC8);

  // ── Neutrals ──
  static const charcoal   = Color(0xFF2C2420);
  static const stone      = Color(0xFF7A6A58);
  static const stoneLight = Color(0xFF9A8A78);
  static const turquoise  = Color(0xFF2A7A7A);
  static const midnight   = Color(0xFF1A120E);

  static const white      = Color(0xFFFFFFFF);
  static const offWhite   = Color(0xFFFAFAF7);

  // ── Semantic ──
  static const border     = Color(0x1F7A6A58); // rgba(122,106,88,0.12)
  static const overlay    = Color(0x991A120E); // rgba(26,18,14,0.6)

  // ── Dark mode surfaces ──
  static const darkBg     = Color(0xFF1A120E);
  static const darkSurface= Color(0xFF2C1F1A);
  static const darkCard   = Color(0xFF3A2A22);
}
