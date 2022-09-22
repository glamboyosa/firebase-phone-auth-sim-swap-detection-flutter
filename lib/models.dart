class SimCheck {
  bool noSimChange = true;

  SimCheck({required this.noSimChange});

  factory SimCheck.fromJson(Map<dynamic, dynamic> json) {
    return SimCheck(
      noSimChange: json['no_sim_change'] ?? true,
    );
  }
}
