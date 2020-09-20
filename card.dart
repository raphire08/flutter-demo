import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanaspati/models/image_model.dart';
import 'package:vanaspati/models/item_model.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({Key key, this.item}) : super(key: key);
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final itemCardWidth = MediaQuery.of(context).size.width;
    Future<String> url = getImage(item['itemId']);
    return Container(
      height: 150.0,
      width: itemCardWidth,
      padding: EdgeInsets.only(left: 2.0),
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                width: 150,
                padding: EdgeInsets.symmetric(horizontal: 0.0),
                child: FutureBuilder(
                    future: url,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData) {
                        return Image.network(
                          snapshot.data,
                          height: 120.0,
                          width: 100.0,
                        );
                      } else {
                        return Image.asset(
                          'images/loading.gif',
                          height: 120.0,
                          width: 100.0,
                        );
                      }
                    })),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    Text(
                      item['name'],
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      '\u{20B9} ${item['sellingPrice'].toString()} / ${item['unit']}',
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 30.0),
                    Row(
                      children: <Widget>[
                        SizedBox(width: 120.0),
                        Consumer<ItemModel>(
                          builder: (context, model, child) {
                            bool isOrdered = model.getIsOrdered(item['itemId']);
                            int qtyOrdered = model.qtyOrdered(item['itemId']);
                            return Container(
                              padding: EdgeInsets.only(left: 5.0, right: 5.0),
                              height: 30.0,
                              decoration: BoxDecoration(
                                color: isOrdered == true
                                    ? Colors.white
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: isOrdered == true
                                  ? Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            model.minusItem(item['itemId']);
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: Colors.green[400],
                                            radius: 13.0,
                                            child: Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5.0),
                                        SizedBox(
                                          width: 25.0,
                                          child: Center(
                                            child: Text(
                                              qtyOrdered.toString(),
                                              style: TextStyle(fontSize: 20.0),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5.0),
                                        GestureDetector(
                                          onTap: () {
                                            model.addItem(item['itemId']);
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: Colors.green[400],
                                            radius: 13.0,
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        model.addItem(item['itemId']);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'ADD',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          SizedBox(width: 15.0),
                                          CircleAvatar(
                                            backgroundColor: Colors.green[400],
                                            radius: 13.0,
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
