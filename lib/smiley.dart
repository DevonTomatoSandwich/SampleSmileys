library smiley;

class Smiley {
  final String name;
  final String art;
  final String productID;
  bool isPurchased;
  bool isRestorable; 
  
  Smiley(
    this.name,
    this.art,
    this.productID,
    this.isPurchased,
    this.isRestorable,
  );

  @override
  String toString() {
    return '{name:$name, art:$art, productID:$productID, isPurchased:$isPurchased, isRestorable:$isRestorable}';
  }
}