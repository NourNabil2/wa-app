// lib/core/api/mock_data.dart
import 'dart:convert';

class MockData {
  static const String homeJson = '''
  {
    "data": {
      "categories": [
        {
          "id": 1,
          "name": "سبح كهرمان",
          "image": "https://dummyimage.com/200x200/000/fff&text=Kahraman",
          "slug": "kahraman"
        },
        {
          "id": 2,
          "name": "سبح خشب كوك",
          "image": "https://dummyimage.com/200x200/000/fff&text=Kuka",
          "slug": "kuka"
        },
        {
          "id": 3,
          "name": "سبح فضة",
          "image": "https://dummyimage.com/200x200/000/fff&text=Silver",
          "slug": "silver"
        }
      ],
      "banners": [
        {
          "id": 1,
          "image": "assets/images/banner_1.jpg",
          "link": ""
        },
        {
          "id": 2,
          "image": "assets/images/banner_2.jpg",
          "link": ""
        }
      ],
      "new_arrivals": [
        {
          "id": 101,
          "name": "سبحة كهرمان اصلي 33 حبة",
          "price": 450,
          "original_price": 500,
          "formatted_price": "450 ر.س",
          "image": "assets/images/rosary_amber_1786203630351.jpg",
          "slug": "kahraman-33",
          "in_stock": true,
          "brand": {"name": "أحجار كريمة"}
        },
        {
          "id": 102,
          "name": "سبحة خشب كوك اسود فخم",
          "price": 120,
          "original_price": 150,
          "formatted_price": "120 ر.س",
          "image": "assets/images/rosary_black_wood_1786203639953.jpg",
          "slug": "kuka-black",
          "in_stock": true,
          "brand": {"name": "أخشاب طبيعية"}
        },
        {
          "id": 103,
          "name": "سبحة فضة عيار 925",
          "price": 850,
          "original_price": 950,
          "formatted_price": "850 ر.س",
          "image": "assets/images/rosary_silver_1786203649816.jpg",
          "slug": "silver-925",
          "in_stock": true,
          "brand": {"name": "مجوهرات"}
        }
      ]
    }
  }
  ''';
}
