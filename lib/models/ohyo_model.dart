enum OhyoCategory {
  all('Alle'),
  basic('Basis'),
  intermediate('Gemiddeld'),
  advanced('Gevorderd'),
  other('Andere');

  const OhyoCategory(this.displayName);

  final String displayName;

  static OhyoCategory? fromStyle(String style) {
    final styleLower = style.toLowerCase();
    for (final cat in OhyoCategory.values) {
      if (cat == OhyoCategory.all) continue;
      if (styleLower.contains(cat.displayName.toLowerCase())) {
        return cat;
      }
    }
    return OhyoCategory.other;
  }
}

class Ohyo {
  final int id;
  final String name;
  final String description;
  final String style;
  final DateTime createdAt;
  final List<String>? imageUrls;
  final List<String>? videoUrls;
  final int order;

  const Ohyo({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    required this.createdAt,
    this.imageUrls,
    this.videoUrls,
    this.order = 0,
  });

  factory Ohyo.fromMap(Map<String, dynamic> map) {
    return Ohyo(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      style: map['style'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : (map['Time'] != null
              ? DateTime.parse(map['Time'] as String)
              : DateTime.now()),
      imageUrls: map['imageUrls'] as List<String>?,
      videoUrls: map['video_urls'] != null
          ? List<String>.from(map['video_urls'] as List)
          : null,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'style': style,
      'created_at': createdAt.toIso8601String(),
      'video_urls': videoUrls,
      'order': order,
    };
  }

  Ohyo copyWith({
    int? id,
    String? name,
    String? description,
    String? style,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<String>? videoUrls,
    int? order,
  }) {
    return Ohyo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return 'Ohyo(id: $id, name: $name, description: $description, style: $style, createdAt: $createdAt, imageUrls: $imageUrls, videoUrls: $videoUrls)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ohyo &&
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

class OhyoState {
  final List<Ohyo> ohyos;
  final List<Ohyo> filteredOhyos;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final OhyoCategory? selectedCategory;
  final bool isOfflineMode;

  const OhyoState({
    this.ohyos = const [],
    this.filteredOhyos = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
    this.isOfflineMode = false,
  });

  OhyoState.initial()
      : ohyos = const [],
        filteredOhyos = const [],
        isLoading = false,
        error = null,
        searchQuery = '',
        selectedCategory = null,
        isOfflineMode = false;

  OhyoState copyWith({
    List<Ohyo>? ohyos,
    List<Ohyo>? filteredOhyos,
    bool? isLoading,
    String? error,
    String? searchQuery,
    OhyoCategory? selectedCategory,
    bool? isOfflineMode,
  }) {
    return OhyoState(
      ohyos: ohyos ?? this.ohyos,
      filteredOhyos: filteredOhyos ?? this.filteredOhyos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  @override
  String toString() {
    return 'OhyoState(ohyos: ${ohyos.length}, filteredOhyos: ${filteredOhyos.length}, isLoading: $isLoading, error: $error, searchQuery: $searchQuery, selectedCategory: $selectedCategory, isOfflineMode: $isOfflineMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OhyoState &&
        other.ohyos == ohyos &&
        other.filteredOhyos == filteredOhyos &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.searchQuery == searchQuery &&
        other.selectedCategory == selectedCategory &&
        other.isOfflineMode == isOfflineMode;
  }

  @override
  int get hashCode {
    return ohyos.hashCode ^
        filteredOhyos.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        searchQuery.hashCode ^
        selectedCategory.hashCode ^
        isOfflineMode.hashCode;
  }
}
