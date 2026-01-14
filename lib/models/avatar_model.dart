enum AvatarType {
  preset,
  custom,
}

enum AvatarFormat {
  svg,
  photo,
}

enum AvatarCategory {
  animals,
  karateMan,
  karateWoman,
  martialArtsCharacters,
  karateItems,
}

class Avatar {
  final String id;
  final String name;
  final String assetPath;
  final AvatarCategory category;
  final AvatarType type;
  final AvatarFormat format;

  const Avatar({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
    required this.type,
    this.format = AvatarFormat.svg,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'category': category.name,
      'type': type.name,
      'format': format.name,
    };
  }

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
      assetPath: json['assetPath'],
      category: AvatarCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      type: AvatarType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      format: json['format'] != null 
        ? AvatarFormat.values.firstWhere(
            (e) => e.name == json['format'],
            orElse: () => AvatarFormat.svg,
          )
        : AvatarFormat.svg,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Avatar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AvatarData {
  // photo-based avatars only
  static const List<Avatar> presetAvatars = [
    // Karate Men Photos
    Avatar(
      id: 'karate_man_white_gi',
      name: 'Karateka Witte Gi',
      assetPath: 'assets/avatars/photos/karate_men/white_gi.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_man_black_gi',
      name: 'Karateka Zwarte Gi',
      assetPath: 'assets/avatars/photos/karate_men/black_gi.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_sensei',
      name: 'Sensei Meester',
      assetPath: 'assets/avatars/photos/karate_men/sensei_master.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_student',
      name: 'Jonge Student',
      assetPath: 'assets/avatars/photos/karate_men/student_young.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_competitor',
      name: 'Toernooi Deelnemer',
      assetPath: 'assets/avatars/photos/karate_men/competitor_tournament.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_referee',
      name: 'Scheids',
      assetPath: 'assets/avatars/photos/karate_men/referee.jpg',
      category: AvatarCategory.karateMan,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),

    //Karate Women Photos
    Avatar(
      id: 'karate_woman_white_gi',
      name: 'Karateka Witte Gi',
      assetPath: 'assets/avatars/photos/karate_women/white_gi.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_woman_black_gi',
      name: 'Karateka Zwarte Gi',
      assetPath: 'assets/avatars/photos/karate_women/black_gi.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_female_sensei',
      name: 'Sensei Vrouw',
      assetPath: 'assets/avatars/photos/karate_women/sensei_master.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_female_student',
      name: 'Jonge Student',
      assetPath: 'assets/avatars/photos/karate_women/student_young.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_female_competitor',
      name: 'Toernooi Deelneemster',
      assetPath: 'assets/avatars/photos/karate_women/competitor_tournament.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'karate_female_referee',
      name: 'Scheids',
      assetPath: 'assets/avatars/photos/karate_women/referee.jpg',
      category: AvatarCategory.karateWoman,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),

    // Martial Arts Characters Photos
    Avatar(
      id: 'samurai_warrior',
      name: 'Traditionele Samurai',
      assetPath: 'assets/avatars/photos/characters/samurai_traditional.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'ninja',
      name: 'Traditionele Ninja',
      assetPath: 'assets/avatars/photos/characters/ninja_modern.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'kung_fu_master',
      name: 'Kung Fu Meester',
      assetPath: 'assets/avatars/photos/characters/kung_fu_master.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'aikido_practitioner',
      name: 'Aikido Meester',
      assetPath: 'assets/avatars/photos/characters/aikido_master.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'judo_fighter',
      name: 'Judo Kampioen',
      assetPath: 'assets/avatars/photos/characters/judo_champion.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'taekwondo_athlete',
      name: 'Taekwondo Atleet',
      assetPath: 'assets/avatars/photos/characters/taekwondo_athlete.jpg',
      category: AvatarCategory.martialArtsCharacters,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),

    //  Animals Photos
    Avatar(
      id: 'animal_dog',
      name: 'Hond',
      assetPath: 'assets/avatars/photos/animals/dog.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_cat',
      name: 'Kat',
      assetPath: 'assets/avatars/photos/animals/cat.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_panda',
      name: 'Panda',
      assetPath: 'assets/avatars/photos/animals/panda.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_fox',
      name: 'Vos',
      assetPath: 'assets/avatars/photos/animals/fox.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_lion',
      name: 'Leeuw',
      assetPath: 'assets/avatars/photos/animals/lion.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_flamingo',
      name: 'Flamingo',
      assetPath: 'assets/avatars/photos/animals/flamingo.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'animal_unicorn',
      name: 'Eenhoorn',
      assetPath: 'assets/avatars/photos/animals/unicorn.jpg',
      category: AvatarCategory.animals,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),

    //  Karate Items Photos
    Avatar(
      id: 'katana_sword',
      name: 'Katana',
      assetPath: 'assets/avatars/photos/items/katana.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'nunchucks',
      name: 'Nunchaku',
      assetPath: 'assets/avatars/photos/items/nunchucks.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'trophy',
      name: 'Trofee',
      assetPath: 'assets/avatars/photos/items/trophy.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'medal',
      name: 'Medaille',
      assetPath: 'assets/avatars/photos/items/medal.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'dojo_building',
      name: 'Dojo',
      assetPath: 'assets/avatars/photos/items/dojo.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
    Avatar(
      id: 'yin_yang',
      name: 'Yin Yang',
      assetPath: 'assets/avatars/photos/items/yin_yang.jpg',
      category: AvatarCategory.karateItems,
      type: AvatarType.preset,
      format: AvatarFormat.photo,
    ),
  ];

  static List<Avatar> getAvatarsByCategory(AvatarCategory category) {
    return presetAvatars.where((avatar) => avatar.category == category).toList();
  }

  static Avatar? getAvatarById(String id) {
    try {
      return presetAvatars.firstWhere((avatar) => avatar.id == id);
    } catch (e) {
      return null;
    }
  }

  static String getCategoryDisplayName(AvatarCategory category) {
    switch (category) {
      case AvatarCategory.animals:
        return 'Dieren';
      case AvatarCategory.karateMan:
        return 'Karate Mannen';
      case AvatarCategory.karateWoman:
        return 'Karate Vrouwen';
      case AvatarCategory.martialArtsCharacters:
        return 'Vechtsporten';
      case AvatarCategory.karateItems:
        return 'Dojo & voorwerpen';
    }
  }
}

/// User avatar model for storing user's avatar preferences
class UserAvatar {
  final String? presetAvatarId;
  final String? customAvatarUrl;
  final AvatarType type;
  final DateTime? lastUpdated;

  const UserAvatar({
    required this.type,
    this.presetAvatarId,
    this.customAvatarUrl,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'preset_avatar_id': presetAvatarId,
      'custom_avatar_url': customAvatarUrl,
      'type': type.name,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      presetAvatarId: json['preset_avatar_id'],
      customAvatarUrl: json['custom_avatar_url'],
      type: AvatarType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AvatarType.preset,
      ),
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  UserAvatar copyWith({
    String? presetAvatarId,
    String? customAvatarUrl,
    AvatarType? type,
    DateTime? lastUpdated,
  }) {
    return UserAvatar(
      presetAvatarId: presetAvatarId ?? this.presetAvatarId,
      customAvatarUrl: customAvatarUrl ?? this.customAvatarUrl,
      type: type ?? this.type,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAvatar &&
        other.presetAvatarId == presetAvatarId &&
        other.customAvatarUrl == customAvatarUrl &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(presetAvatarId, customAvatarUrl, type);
}
