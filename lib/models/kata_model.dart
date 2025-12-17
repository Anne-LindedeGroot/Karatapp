enum KataCategory {
  all('Alle'),
  wadoRyu('Wado Ryu'),
  shotokan('Shotokan'),
  gojuRyu('Goju Ryu'),
  shitoRyu('Shito Ryu'),
  kyokushin('Kyokushin'),
  other('Andere');

  const KataCategory(this.displayName);
  
  final String displayName;
  
  static KataCategory? fromStyle(String style) {
    final styleLower = style.toLowerCase();
    for (final category in KataCategory.values) {
      if (category == KataCategory.all) continue;
      if (styleLower.contains(category.displayName.toLowerCase())) {
        return category;
      }
    }
    return KataCategory.other;
  }
}

class Kata {
  final int id;
  final String name;
  final String description;
  final String style;
  final DateTime createdAt;
  final List<String>? imageUrls;
  final List<String>? videoUrls;
  final int order;
  final bool isLiked;
  final int likeCount;

  const Kata({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    required this.createdAt,
    this.imageUrls,
    this.videoUrls,
    this.order = 0,
    this.isLiked = false,
    this.likeCount = 0,
  });

  factory Kata.fromMap(Map<String, dynamic> map) {
    return Kata(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      style: map['style'] as String? ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : (map['Time'] != null 
              ? DateTime.parse(map['Time'] as String)
              : DateTime.now()),
      imageUrls: map['image_urls'] != null
          ? List<String>.from(map['image_urls'] as List)
          : null,
      videoUrls: map['video_urls'] != null
          ? List<String>.from(map['video_urls'] as List)
          : null,
      order: map['order'] as int? ?? 0,
      isLiked: map['is_liked'] as bool? ?? false,
      likeCount: map['like_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'style': style,
      'created_at': createdAt.toIso8601String(),
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'order': order,
      'is_liked': isLiked,
      'like_count': likeCount,
    };
  }

  Kata copyWith({
    int? id,
    String? name,
    String? description,
    String? style,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<String>? videoUrls,
    int? order,
    bool? isLiked,
    int? likeCount,
  }) {
    return Kata(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      order: order ?? this.order,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  @override
  String toString() {
    return 'Kata(id: $id, name: $name, description: $description, style: $style, createdAt: $createdAt, imageUrls: $imageUrls, videoUrls: $videoUrls)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kata &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.style == style &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        style.hashCode ^
        createdAt.hashCode;
  }
}

class KataState {
  final List<Kata> katas;
  final List<Kata> filteredKatas;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final KataCategory? selectedCategory;
  final bool isOfflineMode;

  const KataState({
    this.katas = const [],
    this.filteredKatas = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
    this.isOfflineMode = false,
  });

  KataState.initial()
      : katas = const [],
        filteredKatas = const [],
        isLoading = false,
        error = null,
        searchQuery = '',
        selectedCategory = null,
        isOfflineMode = false;

  KataState copyWith({
    List<Kata>? katas,
    List<Kata>? filteredKatas,
    bool? isLoading,
    String? error,
    String? searchQuery,
    KataCategory? selectedCategory,
    bool? isOfflineMode,
  }) {
    return KataState(
      katas: katas ?? this.katas,
      filteredKatas: filteredKatas ?? this.filteredKatas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  @override
  String toString() {
    return 'KataState(katas: ${katas.length}, filteredKatas: ${filteredKatas.length}, isLoading: $isLoading, error: $error, searchQuery: $searchQuery, selectedCategory: $selectedCategory, isOfflineMode: $isOfflineMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KataState &&
        other.katas == katas &&
        other.filteredKatas == filteredKatas &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.searchQuery == searchQuery &&
        other.selectedCategory == selectedCategory &&
        other.isOfflineMode == isOfflineMode;
  }

  @override
  int get hashCode {
    return katas.hashCode ^
        filteredKatas.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        searchQuery.hashCode ^
        selectedCategory.hashCode ^
        isOfflineMode.hashCode;
  }
}
