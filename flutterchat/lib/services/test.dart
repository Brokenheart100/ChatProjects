void main() {
  // 用工厂构造函数创建不同形状

  // 调用形状的方法
}

// 抽象形状类（基类）
abstract class Shape {
  // 工厂构造函数：根据类型创建不同形状实例
  factory Shape.create(String type,
      {double? radius, double? width, double? height}) {
    switch (type) {
      case 'circle':
        // 校验参数并创建圆形
        if (radius == null) throw '创建圆形需要传入 radius';
        return Circle(radius);
      case 'rectangle':
        // 校验参数并创建矩形
        if (width == null || height == null) throw '创建矩形需要传入 width 和 height';
        return Rectangle(width, height);
      default:
        throw '不支持的形状类型: $type';
    }
  }

  // 抽象方法：计算面积
  double calculateArea();
}

// 圆形（继承自Shape）
class Circle implements Shape {
  final double radius;

  Circle(this.radius);

  @override
  double calculateArea() {
    return 3.14 * radius * radius; // 圆面积公式：πr²
  }
}

// 矩形（继承自Shape）
class Rectangle implements Shape {
  final double width;
  final double height;

  Rectangle(this.width, this.height);

  @override
  double calculateArea() {
    return width * height; // 矩形面积公式：长×宽
  }
}
