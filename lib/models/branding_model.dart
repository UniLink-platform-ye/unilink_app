// lib/models/branding_model.dart
// نموذج بيانات الهوية البصرية القادمة من Branding API

import 'package:flutter/material.dart';

class BrandingModel {
  final String platformName;
  final String platformTagline;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonPrimaryColor;
  final Color buttonTextColor;
  final Color cardBgColor;
  final Color inputBgColor;
  final Color inputBorderColor;
  final String fontFamily;
  final String? logoUrl;
  final String activeTemplateKey;

  const BrandingModel({
    required this.platformName,
    required this.platformTagline,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonPrimaryColor,
    required this.buttonTextColor,
    required this.cardBgColor,
    required this.inputBgColor,
    required this.inputBorderColor,
    required this.fontFamily,
    this.logoUrl,
    required this.activeTemplateKey,
  });

  /// القيم الافتراضية (Deep Blue) — تُستخدم عند فشل الـ API
  static const BrandingModel defaults = BrandingModel(
    platformName:       'Trusted Social Network Platform',
    platformTagline:    'منصة التواصل الأكاديمي الموثوقة',
    primaryColor:       Color(0xFF004D8C),
    secondaryColor:     Color(0xFF007786),
    accentColor:        Color(0xFF00B4D8),
    backgroundColor:    Color(0xFFFFFFFF),
    textColor:          Color(0xFF1E293B),
    buttonPrimaryColor: Color(0xFF004D8C),
    buttonTextColor:    Color(0xFFFFFFFF),
    cardBgColor:        Color(0xFFF8FAFC),
    inputBgColor:       Color(0xFFFFFFFF),
    inputBorderColor:   Color(0xFFCBD5E1),
    fontFamily:         'Cairo',
    logoUrl:            null,
    activeTemplateKey:  'deep_blue',
  );

  /// بناء من JSON
  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      platformName:       json['platform_name']        as String? ?? 'UniLink',
      platformTagline:    json['platform_tagline']     as String? ?? '',
      primaryColor:       _hexToColor(json['primary_color'],       const Color(0xFF004D8C)),
      secondaryColor:     _hexToColor(json['secondary_color'],     const Color(0xFF007786)),
      accentColor:        _hexToColor(json['accent_color'],        const Color(0xFF00B4D8)),
      backgroundColor:    _hexToColor(json['background_color'],    const Color(0xFFFFFFFF)),
      textColor:          _hexToColor(json['text_color'],          const Color(0xFF1E293B)),
      buttonPrimaryColor: _hexToColor(json['button_primary_color'],const Color(0xFF004D8C)),
      buttonTextColor:    _hexToColor(json['button_text_color'],   const Color(0xFFFFFFFF)),
      cardBgColor:        _hexToColor(json['card_bg_color'],       const Color(0xFFF8FAFC)),
      inputBgColor:       _hexToColor(json['input_bg_color'],      const Color(0xFFFFFFFF)),
      inputBorderColor:   _hexToColor(json['input_border_color'],  const Color(0xFFCBD5E1)),
      fontFamily:         json['font_family']          as String? ?? 'Cairo',
      logoUrl:            json['logo_url']             as String?,
      activeTemplateKey:  json['active_template_key'] as String? ?? 'deep_blue',
    );
  }

  static Color _hexToColor(dynamic hex, Color fallback) {
    if (hex == null || hex is! String) return fallback;
    final s = hex.replaceAll('#', '').trim();
    if (s.length == 6) {
      final value = int.tryParse('FF$s', radix: 16);
      return value != null ? Color(value) : fallback;
    }
    return fallback;
  }

  Map<String, dynamic> toJson() => {
    'platform_name':        platformName,
    'platform_tagline':     platformTagline,
    'primary_color':        _colorToHex(primaryColor),
    'secondary_color':      _colorToHex(secondaryColor),
    'accent_color':         _colorToHex(accentColor),
    'background_color':     _colorToHex(backgroundColor),
    'text_color':           _colorToHex(textColor),
    'button_primary_color': _colorToHex(buttonPrimaryColor),
    'button_text_color':    _colorToHex(buttonTextColor),
    'card_bg_color':        _colorToHex(cardBgColor),
    'input_bg_color':       _colorToHex(inputBgColor),
    'input_border_color':   _colorToHex(inputBorderColor),
    'font_family':          fontFamily,
    'logo_url':             logoUrl,
    'active_template_key':  activeTemplateKey,
  };

  static String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
}
