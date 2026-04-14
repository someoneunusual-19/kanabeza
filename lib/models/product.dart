import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? description;
  @HiveField(3)
  double costPrice;
  @HiveField(4)
  double sellingPrice;
  @HiveField(5)
  int currentStock;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.currentStock,
  });
}