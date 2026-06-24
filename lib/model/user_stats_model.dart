class UserStatsModel {
  final int points;
  final int certificates;
  final String globalRank;
  final int level;
  final int pointsToNextLevel;
  final int streakDays;

  UserStatsModel({
    required this.points,
    required this.certificates,
    required this.globalRank,
    required this.level,
    required this.pointsToNextLevel,
    required this.streakDays,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      points: json['points'] ?? 0,
      certificates: json['certificates'] ?? 0,
      globalRank: json['globalRank'] ?? 'Unranked',
      level: json['level'] ?? 1,
      pointsToNextLevel: json['pointsToNextLevel'] ?? 100,
      streakDays: json['streakDays'] ?? 0,
    );
  }
}

class AchievementModel {
  final String title;
  final String description;
  final String icon;
  final String colorTheme; // e.g., "primary", "secondary", "tertiary"

  AchievementModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.colorTheme,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'star',
      colorTheme: json['colorTheme'] ?? 'primary',
    );
  }
}

class LearningStrengthModel {
  final String skillName;
  final String icon;
  final String level; // e.g., 'PRO', 'ADV', 'BEG'
  final double progress; // 0.0 to 1.0

  LearningStrengthModel({
    required this.skillName,
    required this.icon,
    required this.level,
    required this.progress,
  });

  factory LearningStrengthModel.fromJson(Map<String, dynamic> json) {
    return LearningStrengthModel(
      skillName: json['skillName'] ?? '',
      icon: json['icon'] ?? 'psychology',
      level: json['level'] ?? 'BEG',
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }
}

class LearningGoalModel {
  final double currentHours;
  final double goalHours;
  final List<double> weeklyHours; // e.g. [2.4, 3.1, 4.5, 2.8, 0, 0, 0]
  final int avgScore;
  final double scoreIncrease;

  LearningGoalModel({
    required this.currentHours,
    required this.goalHours,
    required this.weeklyHours,
    required this.avgScore,
    required this.scoreIncrease,
  });

  factory LearningGoalModel.fromJson(Map<String, dynamic> json) {
    return LearningGoalModel(
      currentHours: (json['currentHours'] ?? 0.0).toDouble(),
      goalHours: (json['goalHours'] ?? 16.0).toDouble(),
      weeklyHours: List<double>.from(json['weeklyHours'] ?? []),
      avgScore: json['avgScore'] ?? 0,
      scoreIncrease: (json['scoreIncrease'] ?? 0.0).toDouble(),
    );
  }
}
