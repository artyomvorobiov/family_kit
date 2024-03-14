import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testiks/create_med.dart';

import 'medicine_detail.dart';

class MedicineListBottomSheet extends StatelessWidget {
  final List<DocumentSnapshot> medicines;

  MedicineListBottomSheet(this.medicines);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: medicines.length,
              separatorBuilder: (context, index) => Divider(
                thickness: 2,
              ),
              itemBuilder: (context, index) {
                var medicine = medicines[index].data() as Map<String, dynamic>;
                var name = medicine['name'] ?? '';
                var comments = medicine['comment'] ?? '';
                var imageUrl = medicine['imageUrl'] ?? ''; 
                var id = medicines[index].id;
                var expiryDate = medicine['expiryDate'];
                var quantity = medicine['quantity'];
                var storageOptions = medicine['storageOptions'];
                var address = medicine['address'];
                var comment = medicine['comment'];
                var isFavorite = medicine['isFavorite'];
                var isPrivate = medicine['isPrivate'];
                var likedBy = medicine['likedBy'];
                var notificationDays = medicine['notificationDays'];
                var quantityNum = medicine['quantityNum'];
                var addedBy = medicine['addedBy'];
                return ListTile(
  title: Row(
    children: [
      Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 8), 
      IconButton(
        icon: Icon(Icons.info),
        onPressed: () {
          Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(
              id: id,
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
      ),
      IconButton(
        icon: Icon(Icons.edit),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMedicinePage(
                name: name,
                expiryDate: expiryDate,
                comment: comment,
                quantity: quantity,
                storageOptions: storageOptions,
                address: address,
                imageUrl: imageUrl,
                notificationDays: notificationDays,
                medicineId: id,
                isEditing: true,
                isFavorite: isFavorite,
                isPrivate: isPrivate,
                quantityNum: quantityNum,
                likedBy: likedBy,
                addedBy: addedBy,
              ),
            ),
          );
        },
      ),
    ],
  ),
  subtitle: Text(
    comments,
    style: TextStyle(fontSize: 14),
  ),
  leading: imageUrl.isNotEmpty
      ? CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(imageUrl),
        )
      : null,
);

              },
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
