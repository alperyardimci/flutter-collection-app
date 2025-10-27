import 'package:flutter/material.dart';

class CountryShape {
  final String isoCode; // "TR", "US", "JP"
  final Path path;      // the actual geometry of that country

  CountryShape({
    required this.isoCode,
    required this.path,
  });
}
