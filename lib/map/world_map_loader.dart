import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'country_shape.dart';
import 'dart:ui' show Path; // Explicitly import Path

class WorldMapLoader {
  static List<CountryShape>? _cachedShapes;

  // NOTE: In a production app, this SVG data must be loaded from an asset file 
  // (e.g., 'assets/world_map.svg') using rootBundle.loadString.
  // This hardcoded string uses simple Path commands (M=move, L=line, Z=close)
  // that roughly match the bounding boxes of the old rectangles, but the structure 
  // is now ready for a real world map SVG.
  static const String _worldMapSvgContent = '''
    <svg viewBox="0 0 800 400">
      <path id="US" d="M170 80 L250 80 L250 130 L170 130 Z" fill="#cfd8dc"/>
      <path id="CA" d="M170 40 L250 40 L250 75 L170 75 Z" fill="#cfd8dc"/>
      <path id="MX" d="M170 135 L250 135 L250 170 L170 170 Z" fill="#cfd8dc"/>
      <path id="BR" d="M250 200 L300 200 L300 250 L250 250 Z" fill="#cfd8dc"/>
      <path id="RU" d="M450 40 L650 40 L650 100 L450 100 Z" fill="#cfd8dc"/>
      <path id="CN" d="M550 120 L650 120 L650 170 L550 170 Z" fill="#cfd8dc"/>
      <path id="IN" d="M500 150 L540 150 L540 200 L500 200 Z" fill="#cfd8dc"/>
      <path id="AU" d="M600 250 L680 250 L680 300 L600 300 Z" fill="#cfd8dc"/>
      <path id="GB" d="M400 60 L430 60 L430 80 L400 80 Z" fill="#cfd8dc"/>
      <path id="FR" d="M420 80 L450 80 L450 100 L420 100 Z" fill="#cfd8dc"/>
      <path id="DE" d="M440 70 L470 70 L470 90 L440 90 Z" fill="#cfd8dc"/>
      <path id="IT" d="M450 90 L480 90 L480 110 L450 110 Z" fill="#cfd8dc"/>
      <path id="JP" d="M650 100 L690 100 L690 130 L650 130 Z" fill="#cfd8dc"/>
      <path id="TR" d="M480 110 L520 110 L520 130 L480 130 Z" fill="#cfd8dc"/>
    </svg>
  ''';

  static Future<List<CountryShape>> loadCountryShapes() async {
    if (_cachedShapes != null) {
      return _cachedShapes!;
    }
    
    try {
      // 1. Load the SVG content (using the hardcoded string for this demo)
      const svgContent = _worldMapSvgContent; 

      final shapes = <CountryShape>[];
      // Regex to find all path elements with an id and path data (d)
      final pathRegex = RegExp(r'<path[^>]*id="(\w+)"[^>]*d="([^"]+)"');

      // 2. Extract country ISO code and path data
      for (final match in pathRegex.allMatches(svgContent)) {
        final isoCode = match.group(1)!;
        final pathData = match.group(2)!;
        
        // 3. Convert SVG path data string to Flutter's Path object
        final path = _svgPathToFlutterPath(pathData);
        
        shapes.add(CountryShape(
          isoCode: isoCode,
          path: path,
        ));
      }
      
      _cachedShapes = shapes;
      return shapes;
    } catch (e) {
      debugPrint('Failed to load/parse map shapes: $e');
      return [
        CountryShape(
          isoCode: 'WORLD',
          path: Path()..addRect(const Rect.fromLTWH(0, 0, 800, 400)),
        ),
      ];
    }
  }

  // Helper to convert simple SVG path data (like "M170 80 L250 80 L250 130 L170 130 Z")
  // to a Flutter Path object. This is a minimal, custom parser.
  static Path _svgPathToFlutterPath(String svgPathData) {
    final path = Path();
    // Use a regex to extract commands (M, L, Z) and coordinates
    final regex = RegExp(r'([MLZ])\s*([\d\s\.]*)');
    final matches = regex.allMatches(svgPathData);

    for (final match in matches) {
      final command = match.group(1);
      final coordsString = match.group(2)?.trim() ?? '';
      
      final coords = coordsString
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();

      if (command == 'M' && coords.length >= 2) {
        path.moveTo(coords[0], coords[1]);
      } else if (command == 'L' && coords.length >= 2) {
        path.lineTo(coords[0], coords[1]);
      } else if (command == 'Z') {
        path.close();
      }
      // Note: A real parser would also need to handle 'C' (Curve), 'A' (Arc), 
      // relative coordinates (m, l, c), etc., which is what a dedicated package does.
    }
    return path;
  }
}