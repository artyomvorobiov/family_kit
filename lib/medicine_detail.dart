import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_med.dart';
import 'main_screen.dart';
import 'medicine_provider.dart';

// ignore: must_be_immutable
class MedicineDetailPage extends StatefulWidget {
  String name;
   String expiryDate;
   String comment;
   String quantity;
   String storageOptions;
   String address;
   String imageUrl;
   String? id;

  MedicineDetailPage({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.comment,
    required this.quantity,
    required this.storageOptions,
    required this.address,
    required this.imageUrl,
  });

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  Future<void> _deleteMedicine(BuildContext context) async {
    try {
      
      DocumentReference medicineReference =
          FirebaseFirestore.instance.collection('drugs').doc(widget.id);

      
      Reference storageReference = FirebaseStorage.instance.refFromURL(widget.imageUrl);
      

      await medicineReference.delete();


      await storageReference.delete();

      Provider.of<MedicineProvider>(context, listen: false).refreshMedicines();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Stack(
            children: [
              MainScreen(),
            ],
          ),
        ),
      );
    } catch (e) {
  
      print('Error deleting medicine: $e');

    }
  }

  Future<void> _fetchMedicine() async {

    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('drugs')
        .doc(widget.id)
        .get();

    setState(() {
      widget.name = documentSnapshot['name'];
      widget.expiryDate = documentSnapshot['expiryDate'];
      widget.comment = documentSnapshot['comment'];
      widget.quantity = documentSnapshot['quantity'];
      widget.storageOptions = documentSnapshot['storageOptions'];
      widget.address = documentSnapshot['address'];
      widget.imageUrl = documentSnapshot['imageUrl'];
    });
  }

   Future<void> _editMedicine(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMedicinePage(
          name: widget.name,
          expiryDate: widget.expiryDate,
          comment: widget.comment,
          quantity: widget.quantity,
          storageOptions: widget.storageOptions,
          address: widget.address,
          imageUrl: widget.imageUrl,
          medicineId: widget.id,
          isEditing: true,
        ),
      ),
    ).then((_) {
      _fetchMedicine();
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchMedicine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        title: Text('Информация о лекарстве'),
         leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Stack(
            children: [
              MainScreen(),
            ],
          ),
        ),
      );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            if (widget.imageUrl.isNotEmpty) 
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            
            Text(
              '${widget.name}',
              style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold), 
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20.0), 

            
            if (widget.comment.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.comment, size: 28.0), 
                  SizedBox(width: 12.0), 
                  Expanded(
                    child: Text(
                      '${widget.comment}',
                      style: TextStyle(fontSize: 20.0), 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12.0), 

           
            if (widget.expiryDate.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.date_range_outlined, size: 28.0), 
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'До ${widget.expiryDate}',
                      style: TextStyle(fontSize: 20.0), 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12.0), 

            Row(
              children: [
                Icon(Icons.shopping_cart, size: 28.0), 
                SizedBox(width: 12.0), 
                Expanded(
                  child: Text(
                    '${widget.quantity} ${widget.storageOptions}',
                    style: TextStyle(fontSize: 20.0), 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0), 

            // Address
            if (widget.address != 'Выберите адрес')
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.0), 
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 28.0), 
                    SizedBox(width: 12.0), 
                    Expanded(
                      child: FittedBox(
                        child: Text(
                        '${widget.address}',
                        style: TextStyle(fontSize: 20.0), 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),),
                  ],
                ),
              ),
            const SizedBox(height: 12.0), 


            InkWell(
              onTap: () {
                launch('https://www.vidal.ru/search?t=all&q=${Uri.encodeComponent(widget.name)}&bad=on');
              },
              child: Text(
                'Инструкция и другая информация',
                style: TextStyle(
                  fontSize: 22.0, 
                  color: Color.fromARGB(255, 10, 114, 1),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}