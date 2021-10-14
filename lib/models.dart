import 'dart:convert';

SIMCheck SIMCheckFromJSON(String jsonString) =>
    SIMCheck.fromJSON(json.decode(jsonString));

class SIMCheck {
  bool simChanged;

  SIMCheck({required this.simChanged});

  factory SIMCheck.fromJSON(Map<String, dynamic> JSON) =>
      SIMCheck(simChanged: !JSON["no_sim_change"]);
}
