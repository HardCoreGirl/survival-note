// GENERATED CODE - Hive TypeAdapter & JSON Serialization for Item

part of 'item.dart';

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 1;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String,
      mode: fields[1] as SurvivalMode,
      category: fields[2] as String,
      name: fields[3] as String,
      storageLocation: fields[4] as String?,
      expiryMonth: fields[5] as DateTime,
      defaultShelfLifeMonths: fields[6] as int,
      isConsumed: fields[7] as bool? ?? false,
      isOwned: fields[8] as bool? ?? false,
      hasExpiry: fields[9] as bool? ?? true,
      nameKo: fields[10] as String?,
      qtyPerPerson: fields[11] as int? ?? 1,
      isSharedEquipment: fields[12] as bool? ?? false,
      unitEn: fields[13] as String? ?? 'pcs',
      unitKo: fields[14] as String? ?? '개',
      memo: fields[15] as String?,
      importance: fields[16] as int? ?? 2,
      catalogItemId: fields[17] as String?,
      affiliateUrlKr: fields[18] as String?,
      affiliateUrlEn: fields[19] as String?,
      affiliateImageUrl: fields[20] as String?,
      displayOrder: fields[21] as int? ?? 999,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.storageLocation)
      ..writeByte(5)
      ..write(obj.expiryMonth)
      ..writeByte(6)
      ..write(obj.defaultShelfLifeMonths)
      ..writeByte(7)
      ..write(obj.isConsumed)
      ..writeByte(8)
      ..write(obj.isOwned)
      ..writeByte(9)
      ..write(obj.hasExpiry)
      ..writeByte(10)
      ..write(obj.nameKo)
      ..writeByte(11)
      ..write(obj.qtyPerPerson)
      ..writeByte(12)
      ..write(obj.isSharedEquipment)
      ..writeByte(13)
      ..write(obj.unitEn)
      ..writeByte(14)
      ..write(obj.unitKo)
      ..writeByte(15)
      ..write(obj.memo)
      ..writeByte(16)
      ..write(obj.importance)
      ..writeByte(17)
      ..write(obj.catalogItemId)
      ..writeByte(18)
      ..write(obj.affiliateUrlKr)
      ..writeByte(19)
      ..write(obj.affiliateUrlEn)
      ..writeByte(20)
      ..write(obj.affiliateImageUrl)
      ..writeByte(21)
      ..write(obj.displayOrder);
  }
}

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      id: json['id'] as String,
      mode: SurvivalMode.values.byName(json['mode'] as String),
      category: json['category'] as String,
      name: json['name'] as String,
      nameKo: json['nameKo'] as String?,
      storageLocation: json['storageLocation'] as String?,
      expiryMonth: DateTime.parse(json['expiryMonth'] as String),
      defaultShelfLifeMonths: json['defaultShelfLifeMonths'] as int,
      isConsumed: json['isConsumed'] as bool? ?? false,
      isOwned: json['isOwned'] as bool? ?? false,
      hasExpiry: json['hasExpiry'] as bool? ?? true,
      qtyPerPerson: json['qtyPerPerson'] as int? ?? 1,
      isSharedEquipment: json['isSharedEquipment'] as bool? ?? false,
      unitEn: json['unitEn'] as String? ?? 'pcs',
      unitKo: json['unitKo'] as String? ?? '개',
      memo: json['memo'] as String?,
      importance: json['importance'] as int? ?? 2,
      catalogItemId: json['catalogItemId'] as String?,
      affiliateUrlKr: json['affiliateUrlKr'] as String?,
      affiliateUrlEn: json['affiliateUrlEn'] as String?,
      affiliateImageUrl: json['affiliateImageUrl'] as String?,
      displayOrder: json['display_order'] as int? ?? json['displayOrder'] as int? ?? 999,
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'mode': instance.mode.name,
      'category': instance.category,
      'name': instance.name,
      'nameKo': instance.nameKo,
      'storageLocation': instance.storageLocation,
      'expiryMonth': instance.expiryMonth.toIso8601String(),
      'defaultShelfLifeMonths': instance.defaultShelfLifeMonths,
      'isConsumed': instance.isConsumed,
      'isOwned': instance.isOwned,
      'hasExpiry': instance.hasExpiry,
      'qtyPerPerson': instance.qtyPerPerson,
      'isSharedEquipment': instance.isSharedEquipment,
      'unitEn': instance.unitEn,
      'unitKo': instance.unitKo,
      'memo': instance.memo,
      'importance': instance.importance,
      'catalogItemId': instance.catalogItemId,
      'affiliateUrlKr': instance.affiliateUrlKr,
      'affiliateUrlEn': instance.affiliateUrlEn,
      'affiliateImageUrl': instance.affiliateImageUrl,
      'display_order': instance.displayOrder,
    };
