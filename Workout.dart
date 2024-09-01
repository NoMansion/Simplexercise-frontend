class Workout {
  String name;
  String plan;

  Workout({required this.name, required this.plan});

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        name: json["name"],
        plan: json["plan"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "plan": plan,
    };
}
