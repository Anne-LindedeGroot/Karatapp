// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedKataAdapter extends TypeAdapter<CachedKata> {
  @override
  final int typeId = 0;

  @override
  CachedKata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedKata(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[4] as DateTime,
      lastSynced: fields[5] as DateTime,
      imageUrls: (fields[6] as List).cast<String>(),
      style: fields[3] as String?,
      isFavorite: fields[7] as bool,
      needsSync: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedKata obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.style)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastSynced)
      ..writeByte(6)
      ..write(obj.imageUrls)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedKataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedForumPostAdapter extends TypeAdapter<CachedForumPost> {
  @override
  final int typeId = 1;

  @override
  CachedForumPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedForumPost(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      authorId: fields[3] as String,
      authorName: fields[4] as String,
      createdAt: fields[5] as DateTime,
      lastSynced: fields[6] as DateTime,
      likesCount: fields[7] as int,
      commentsCount: fields[8] as int,
      needsSync: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedForumPost obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.authorId)
      ..writeByte(4)
      ..write(obj.authorName)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastSynced)
      ..writeByte(7)
      ..write(obj.likesCount)
      ..writeByte(8)
      ..write(obj.commentsCount)
      ..writeByte(9)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedForumPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
