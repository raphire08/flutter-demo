import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemModel extends ChangeNotifier {
  static List<Map<String, dynamic>> categoryMap = [];
  static List<String> categoryList = [];
  static List<bool> catButtonTapStatus;
  static List<dynamic> subCatList;
  static List<bool> subCatButtonTapStatus;
  static Map<String, List> itemMap = {};
  List<dynamic> get itemList => itemMap[subCatSelected];
  Map<String, List<bool>> isOrdered = Map.fromIterable(itemMap.keys,
      key: (key) => key,
      value: (key) => List.generate(itemMap[key].length, (index) => false));
  static String subCatSelected = 'Fruits';

  Future<bool> getCategory() async {
    await FirebaseFirestore.instance
        .collection('categories')
        .get()
        .then((QuerySnapshot querySnapshot) async {
      querySnapshot.docs.forEach((doc) async {
        String category = doc.data()['category'];
        Map<String, dynamic> map = {
          'categoryName': category,
          'subCatList': doc.data()['subCategory'] // this is a list
        };
        categoryMap.add(map);
        if (categoryList.indexOf(category) == -1) {
          categoryList.add(category);
        }
        await loadInitialData();
        notifyListeners();
      });
    }).catchError((error) => print(' getCategory error  $error'));
    return true;
  }

  Future<void> loadInitialData() async {
    catButtonTapStatus = List.generate(categoryList.length, (index) => false);
    subCatList = categoryMap[0]['subCatList']; // list
    subCatButtonTapStatus = List.generate(subCatList.length, (index) => false);
    notifyListeners();
  }

  bool isCatButtonTapped(categoryName) {
    int buttonIndex = categoryList.indexOf(categoryName);
    return catButtonTapStatus[buttonIndex];
  }

  void toggleCatButton(categoryName) {
    if (catButtonTapStatus.indexOf(true) != -1) {
      catButtonTapStatus.remove(true);
      catButtonTapStatus.add(false);
    }
    int buttonIndex = categoryList.indexOf(categoryName);
    catButtonTapStatus[buttonIndex] = true;
    notifyListeners();
  }

  void createSubCatList(categoryName) {
    subCatList = categoryMap
        .where((e) => e['categoryName'] == categoryName)
        .toList()[0]['subCatList'];
    subCatButtonTapStatus = List.generate(subCatList.length, (index) => false);
    notifyListeners();
  }

  bool isSubCatButtonTapped(subCatName) {
    int buttonIndex = subCatList.indexOf(subCatName);
    return subCatButtonTapStatus[buttonIndex];
  }

  void toggleSubCatButton(subCatName) {
    if (subCatButtonTapStatus.indexOf(true) != -1) {
      subCatButtonTapStatus.remove(true);
      subCatButtonTapStatus.add(false);
    }
    int buttonIndex = subCatList.indexOf(subCatName);
    subCatButtonTapStatus[buttonIndex] = true;
    notifyListeners();
  }

  Future<void> getItem(String subCat, {refresh = false}) async {
    if (itemMap[subCat] == null || refresh == true) {
      await FirebaseFirestore.instance
          .collection('Item')
          .doc(subCat)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        itemMap.addAll({
          subCat: documentSnapshot.data().entries.map((e) => e.value).toList()
        });
      }).catchError((error) => print(error));
    }
    itemMap.forEach((key, value) {
      value.forEach((item) {
        if (item['discount'] != 0) {
          item['netPrice'] =
              item['sellingPrice'] * (1 - (0.01 * item['discount']));
        }
      });
    });
    notifyListeners();
  }

  bool getIsOrdered(String itemId) {
    int itemIndex =
        itemMap[subCatSelected].indexWhere((item) => item['itemId'] == itemId);
    return isOrdered[subCatSelected][itemIndex];
  }

  Future<void> changeSubCat(subCat) async {
    subCatSelected = subCat;
    await getItem(subCat);
    if (isOrdered[subCat] == null) {
      isOrdered.addAll(
          {subCat: List.generate(itemMap[subCat].length, (index) => false)});
    }
    notifyListeners();
  }

  void sortItem(String sortValue) {
//    List<int> indexList =
//        List.generate(itemMap[subCatSelected].length, (index) => index);
//    Map<String, dynamic> itemIndexMap = Map.fromIterable(indexList,
//        key: (k) => itemMap[subCatSelected][k]['itemId'], value: (v) => v);
//    Map<int, bool> isOrderedIndexMap = Map.fromIterable(indexList,
//        key: (k) => k, value: (v) => isOrdered[subCatSelected][v]);

    switch (sortValue) {
      case 'A-Z':
        itemMap[subCatSelected].sort((a, b) => a['name'].compareTo(b['name']));
//        indexList = [
//          for (Map map in itemMap[subCatSelected]) itemIndexMap[map['itemId']]
//        ];
//        isOrdered[subCatSelected] = [
//          for (int index in indexList) isOrderedIndexMap[index]
//        ];
        break;
      case 'Z-A':
        itemMap[subCatSelected].sort((b, a) => a['name'].compareTo(b['name']));
        break;
      case 'Lowest':
        itemMap[subCatSelected]
            .sort((a, b) => a['sellingPrice'].compareTo(b['sellingPrice']));
        break;
      case 'Highest':
        itemMap[subCatSelected]
            .sort((b, a) => a['sellingPrice'].compareTo(b['sellingPrice']));
        break;
    }
    notifyListeners();
  }

  static List<dynamic> orderMapList = [];
  int orderLength = 0;
  static Map<String, int> itemQtyOrdered = {};

  List<dynamic> generateOrder() {
    orderMapList = [];
    List<String> itemIdList = itemQtyOrdered.keys.toList();
    itemMap.forEach((String key, List value) {
      value
          .where((map) => itemIdList.contains(map['itemId']))
          .toList()
          .forEach((item) {
        orderMapList.add({
          'subCategory': key,
          'itemId': item['itemId'],
          'name': item['name'],
          'sellingPrice': item['sellingPrice'],
          'discount': item['discount'],
          'unit': item['unit'],
          'qtyOrdered': itemQtyOrdered[item['itemId']],
        });
      });
    });
    return orderMapList;
  }

  int qtyOrdered(String itemId) {
    return itemQtyOrdered[itemId];
  }

  void addItem(String itemId) {
    int itemIndex =
        itemMap[subCatSelected].indexWhere((item) => item['itemId'] == itemId);
    if (itemQtyOrdered[itemId] == null) {
      isOrdered[subCatSelected][itemIndex] = true;
      itemQtyOrdered.addAll({itemId: 1});
      orderLength++;
    } else {
      itemQtyOrdered[itemId]++;
    }
    notifyListeners();
  }

  void minusItem(String itemId) {
    int itemIndex =
        itemMap[subCatSelected].indexWhere((item) => item['itemId'] == itemId);
    if (itemQtyOrdered[itemId] == 1) {
      isOrdered[subCatSelected][itemIndex] = false;
      orderLength--;
      itemQtyOrdered.remove(itemId);
    } else {
      itemQtyOrdered[itemId]--;
    }
    notifyListeners();
  }

  void addItemFromCart(String itemId) {
    int orderIndex =
        orderMapList.indexWhere((item) => item['itemId'] == itemId);
    orderMapList[orderIndex]['qtyOrdered']++;
    itemQtyOrdered[itemId]++;
    notifyListeners();
  }

  void minusItemFromCart(String itemId) {
    int orderIndex =
        orderMapList.indexWhere((item) => item['itemId'] == itemId);
    String subCat = orderMapList[orderIndex]['subCategory'];
    int itemIndex =
        itemMap[subCat].indexWhere((item) => item['itemId'] == itemId);
    if (itemQtyOrdered[itemId] == 1) {
      isOrdered[subCat][itemIndex] = false;
      orderMapList.removeAt(orderIndex);
      itemQtyOrdered.remove(itemId);
      orderLength--;
    } else {
      orderMapList[orderIndex]['qtyOrdered']--;
      itemQtyOrdered[itemId]--;
    }
    notifyListeners();
  }

  List<double> billDetails() {
    if (itemQtyOrdered.length == 0 || itemQtyOrdered == null) {
      return [0.0, 0.0];
    } else {
      double mrpAmount = 0;
      double discountAmount = 0;
      orderMapList.forEach((item) {
        mrpAmount += item['sellingPrice'] * item['qtyOrdered'];
        discountAmount +=
            item['discount'] * item['sellingPrice'] * item['qtyOrdered'];
      });
      //notifyListeners();
      return [mrpAmount, discountAmount];
    }
  }

  void resetOrder() {
    //orderMapList.removeRange(0, orderLength);
    itemQtyOrdered.clear();
    orderLength = 0;
    isOrdered.forEach((key, value) {
      value.replaceRange(
          0, value.length, List.generate(value.length, (index) => false));
    });
    notifyListeners();
  }
}
