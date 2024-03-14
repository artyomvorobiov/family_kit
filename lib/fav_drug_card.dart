import 'package:flutter/material.dart';
import 'medicine_detail.dart';

class MedicineFavCard extends StatelessWidget {
  final String name;
  final String comment;
  final String expiryDate;
  final String quantity;
  final String storageOptions;
  final String notificationDays;
  final String address;
  final String imageUrl;
  final String? medicine;
  final bool? isFavorite;
  final bool? isPrivate;
  final Function(String id, bool isSwipeRight) onSwiped;

  MedicineFavCard({
    Key? key,
    required this.name,
    required this.comment,
    required this.expiryDate,
    required this.quantity,
    required this.storageOptions,
    required this.address,
    required this.imageUrl,
    required this.medicine,
    required this.onSwiped,
    this.isFavorite,
    this.isPrivate,
    required this.notificationDays
  }) : super(key: key);

  Color _getCardColor() {
    DateTime currentDate = DateTime.now();

    if (expiryDate == '' || expiryDate.isEmpty) {
      return Colors.grey;
    }

    try {
      DateTime parsedExpiryDate = DateTime.parse(expiryDate);

      if (currentDate.isAfter(parsedExpiryDate)) {
        return const Color.fromARGB(255, 202, 18, 5);
      } else {
        try {
          if (notificationDays != '') {
          int notification = int.parse(notificationDays);
          print('AAAAAASSAA $notification');
          if (currentDate
              .add(Duration(days: notification))
              .isAfter(parsedExpiryDate)) {
            return Color.fromARGB(255, 196, 111, 14);
          }
        }
        } catch (e) {
          print('Invalid quantity format: $quantity');
        }

        return Color.fromARGB(255, 10, 114, 1);
      }
    } catch (e) {
      print('Invalid expiryDate format: $expiryDate');
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(
              id: medicine,
              name: name,
              comment: comment,
              expiryDate: expiryDate,
              quantity: quantity,
              storageOptions: storageOptions,
              address: address,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Dismissible(
        key: Key('${medicine ?? UniqueKey()}'),
        direction: DismissDirection.horizontal,
        onDismissed: (DismissDirection direction) {
          if (direction == DismissDirection.startToEnd) {

            onSwiped(medicine!, true);
          } else if (direction == DismissDirection.endToStart) {

            onSwiped(medicine!, false);
          }
        },
        background: Container(
          color: Color.fromARGB(255, 10, 114, 1), 
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 16.0),
          child: Center(
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.white),
                SizedBox(width: 10.0),
                Text(
                  'Редактировать',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
        ),
         secondaryBackground: Container(
          color: Colors.red, 
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 16.0),
          child: const Row(
             mainAxisAlignment: MainAxisAlignment.end,
              children: [
                
                Icon(Icons.heart_broken_sharp, color: Colors.white),
                SizedBox(width: 10.0),
                Text(
                  'Удалить из избранного',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.all(10.0),
          color: _getCardColor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: imageUrl
                    .isNotEmpty, 
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    imageUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    cacheHeight: 800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              if (comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.comment, color: Colors.white, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(
                        comment,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.white, size: 16.0),
                    SizedBox(width: 4.0),
                    Text(
                      '$quantity $storageOptions',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (address != 'Выберите адрес')
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(
                        '$address',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
