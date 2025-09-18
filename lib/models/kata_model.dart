class Kata {
  final int id;
  final String name;
  final String description;
  final String style;
  final DateTime createdAt;
  final List<String>? imageUrls;
  final List<String>? videoUrls;
  final int order;

  const Kata({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    required this.createdAt,
    this.imageUrls,
    this.videoUrls,
    this.order = 0,
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

  Kata copyWith({
    int? id,
    String? name,
    String? description,
    String? style,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<String>? videoUrls,
    int? order,
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

  const KataState({
    this.katas = const [],
    this.filteredKatas = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  KataState.initial()
      : katas = const [],
        filteredKatas = const [],
        isLoading = false,
        error = null,
        searchQuery = '';

  KataState copyWith({
    List<Kata>? katas,
    List<Kata>? filteredKatas,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return KataState(
      katas: katas ?? this.katas,
      filteredKatas: filteredKatas ?? this.filteredKatas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  String toString() {
    return 'KataState(katas: ${katas.length}, filteredKatas: ${filteredKatas.length}, isLoading: $isLoading, error: $error, searchQuery: $searchQuery)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KataState &&
        other.katas == katas &&
        other.filteredKatas == filteredKatas &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return katas.hashCode ^
        filteredKatas.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        searchQuery.hashCode;
  }
}
