import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:barcode_scan2/model/model.dart';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_places/flutter_google_places.dart' as loc;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_api_headers/google_api_headers.dart' as header;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'main_screen.dart';

class CreateMedicinePage extends StatefulWidget {
  final bool isEditing;
  final String? medicineId;
  final String? name;
  final String? expiryDate;
  final String? address;
  final String? comment;
  final String? addedBy;
  final String? notificationDays;
  final String? quantity;
  final String? quantityNum;
  final String? storageOptions;
  final String? imageUrl;
  final bool? isFavorite;
  final bool? isPrivate;
  final List<dynamic>? likedBy;

  CreateMedicinePage({
    Key? key,
    this.isEditing = false,
    this.medicineId,
    this.name,
    this.expiryDate,
    this.quantityNum,
    
    this.address,
    this.comment,
    this.quantity,
    this.storageOptions,
    this.imageUrl,
    this.isFavorite,
    this.isPrivate,
    this.likedBy, 
    this.notificationDays, 
    this.addedBy,
  }) : super(key: key);
  @override
  _CreateMedicinePageState createState() => _CreateMedicinePageState();
}

class _CreateMedicinePageState extends State<CreateMedicinePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _notificationDaysController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _quantityNumController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedStorageOption = 'мл';
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedAddress = 'Выберите адрес';
  GoogleMapController? _controller;
  double latitude = 0;
  double longitude = 0;
  bool creator = false;
  final Map<String, Marker> _markers = {};
  bool isFavorite = false;
  bool isPrivate = false;
  bool isEditing = false;
  late String medicineId;
  bool isLoading = false;
  String imageRed = '';
  bool photoChange = false;
  List<dynamic> likedBy = [];
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
       User? user = _auth.currentUser;
       if (user!= null &&  widget.likedBy!.contains(user.uid)) {
         isFavorite = true;
       } else {
        isFavorite = false;
       }
      isEditing = true;
      medicineId = widget.medicineId!;
      _nameController.text = widget.name!;
      _expiryDateController.text = widget.expiryDate!;
      _selectedAddress = widget.address!;
      // isFavorite = widget.isFavorite!;
      isPrivate = widget.isPrivate!;
      _commentController.text = widget.comment!;
      likedBy = widget.likedBy!;
       _notificationDaysController.text = widget.notificationDays!;
        _quantityController.text = widget.quantity!;
        imageRed = widget.imageUrl!;
      photoChange = widget.isEditing;
      _quantityNumController.text = widget.quantityNum!;
      
    }
  }

  Future<String> _getFamilyId() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        if (userSnapshot['selectedFamily'] == 1) {
          return userSnapshot['familyId'];
        } else if (userSnapshot['selectedFamily'] == 2) {
          return userSnapshot['familyId2'];
        } else {
          return userSnapshot['familyId3'];
        }
      }
    }

    return '';
  }

  Future getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      photoChange = false;
    });
  }

  Future getImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
      photoChange = false;
    });
  }

  void _scan() async {
    try {
      var result = await BarcodeScanner.scan(
          options: const ScanOptions(
        strings: {
          'cancel': 'X',
          'flash_on': 'Фонарик вкл.',
          'flash_off': 'Фонарик вык.',
        },
      ));
      // _showScanResult(result.rawContent);
      await _fetchProductName(result.rawContent);
    } catch (e) {
      print('Error during barcode scanning: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сканировании штрих-кода')),
      );
    }
  }

  void _showScanResult(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Результат сканирования'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchProductName(String barcode) async {
    final url = 'https://barcode-list.ru/barcode/RU/Поиск.htm?barcode=$barcode';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final productNameElement = document.querySelector(
            '#main > div > table > tbody > tr > td.main_column > h1');
        if (productNameElement != null) {
          final productName = productNameElement.text.trim();
          // print('Product Name: $productName');
          final List<String> words = productName.split(' ');
          if (words.isNotEmpty && !words.first.contains('Поиск')) {
            final firstName = words.first;
            _nameController.text = firstName;
            print('First Name: $firstName');
          } else if (words.isNotEmpty && words.first.contains('Поиск')) {
            Fluttertoast.showToast(
      msg: 'Лекарство не найдено',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
          }
          // print(words.first);
           
        } else {
          print('Product name element not found on the page.');
        }
      } else {
        print(
            'Failed to fetch product information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product information: $e');
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      _expiryDateController.text =
          "${pickedDate.toLocal()}".split(' ')[0]; 
    }
  }

  Future<void> _handleSearch() async {
    places.Prediction? p = await loc.PlacesAutocomplete.show(
      context: context,
      apiKey:
          'AIzaSyBYg4SD_fvydAJIOBwZcKIVGqj_QxdFM1U', 
      onError: onError,
      mode: loc.Mode.overlay,
      language: 'RU',
      strictbounds: false,
      types: [],
      decoration: InputDecoration(
        hintText: 'search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      components: [],
    );

    if (p != null) {
      displayPrediction(p, homeScaffoldKey.currentState);
      setState(() {
        _selectedAddress = p.description!;
      });
    }
  }

  void onError(places.PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Сообщение',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  Future<void> displayPrediction(
      places.Prediction p, ScaffoldState? currentState) async {
    places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(
        apiKey:
            'AIzaSyBYg4SD_fvydAJIOBwZcKIVGqj_QxdFM1U', 
        apiHeaders: await const header.GoogleApiHeaders().getHeaders());
    places.PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(p.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    _markers.clear();
    final marker = Marker(
      markerId: const MarkerId('deliveryMarker'),
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(
        title: '',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15),
        ),
      );
    });
  }

  Future<List<String>> _getFamilyMedicineAddresses() async {
    User? user = _auth.currentUser;
    List<String> addresses = [];

    if (user != null) {
      String userFamilyId = await _getFamilyId();

      if (userFamilyId.isNotEmpty) {
        QuerySnapshot medicineSnapshot = await _firestore
            .collection('drugs')
            .where('familyId', isEqualTo: userFamilyId)
            .get();

        addresses = medicineSnapshot.docs
            .map((DocumentSnapshot doc) => doc['address'] as String).where((address) => !address.contains('Выберите адрес'))
            .toList();
      }
    }

    return addresses;
  }

  Future<void> _showAddressSelectionPopup() async {
    List<String> medicineAddresses = await _getFamilyMedicineAddresses();

    if (medicineAddresses.isNotEmpty) {
      String? selectedAddress = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Выберите адрес'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: medicineAddresses
                  .map((address) => ListTile(
                        title: Text(address),
                        onTap: () {
                          Navigator.pop(context, address);
                        },
                      ))
                  .toList(),
            ),
          );
        },
      );

      if (selectedAddress != null) {
        setState(() {
          _selectedAddress = selectedAddress;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нет сохраненных адресов лекарств')),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите источник изображения'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                GestureDetector(
                  child: Text('Выбрать из галереи'),
                  onTap: () {
                    Navigator.of(context).pop();
                    getImageFromGallery();
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Сделать снимок'),
                  onTap: () {
                    Navigator.of(context).pop();
                    getImageFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMedicine() async {
    if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Введите название лекарства'),
      ),
    );
    return;
  }
    setState(() {
      isLoading =
          true; 
    });
    User? user = _auth.currentUser;
    try {
      if (user != null) {
        String userFamilyId = await _getFamilyId();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/loading.gif',
                        height: 200), 
                    SizedBox(height: 30.0),
                    Text('Сохранение лекарства...'),
                  ],
                ),
              ),
            );
          },
        );
        if (isEditing) {
          if (isFavorite && !likedBy.contains(user.uid)) {
            likedBy.add(user.uid);
          } else if (!isFavorite && likedBy.contains(user.uid)) {
            likedBy.remove(user.uid);
          }
          await _firestore.collection('drugs').doc(medicineId).update({
            'name': _nameController.text,
            'expiryDate': _expiryDateController.text,
            'notificationDays': _notificationDaysController.text,
            'storageOptions': _selectedStorageOption,
            'quantity': _quantityController.text,
            'comment': _commentController.text,
            'address': _selectedAddress,
            // 'addedBy': user.uid,
            'familyId': userFamilyId,
            'isFavorite': isFavorite,
            'isPrivate': isPrivate,
            'likedBy': likedBy,
            'quantityNum': _quantityNumController.text,
          });

          if (_image != null) {
            Reference storageReference = FirebaseStorage.instance
                .ref()
                .child('medicine_images/${medicineId}.png');

            UploadTask uploadTask =
                storageReference.putFile(File(_image!.path));

            await uploadTask.whenComplete(() async {
              String imageUrl = await storageReference.getDownloadURL();

              await _firestore.collection('drugs').doc(medicineId).update({
                'imageUrl': imageUrl,
              });
            });
          }
        } else {
          if (isFavorite) {
            likedBy.add(user.uid);
          }
          DocumentReference medicineReference =
              await _firestore.collection('drugs').add({
            'name': _nameController.text,
            'expiryDate': _expiryDateController.text,
            'notificationDays': _notificationDaysController.text,
            'storageOptions': _selectedStorageOption,
            'quantity': _quantityController.text,
            'comment': _commentController.text,
            'address': _selectedAddress,
            'addedBy': user.uid,
            'addedOn': FieldValue.serverTimestamp(),
            'familyId': userFamilyId,
            'imageUrl': '',
            'isPrivate': isPrivate,
            'isFavorite': isFavorite,
            'likedBy': likedBy,
            'quantityNum': _quantityNumController.text,
          });

          if (_image != null) {
            Reference storageReference = FirebaseStorage.instance
                .ref()
                .child('medicine_images/${medicineReference.id}.png');

            UploadTask uploadTask =
                storageReference.putFile(File(_image!.path));

            await uploadTask.whenComplete(() async {
              String imageUrl = await storageReference.getDownloadURL();

              await medicineReference.update({
                'imageUrl': imageUrl,
              });
            });
          }
        }
        Navigator.pop(context); 

        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Лекарство успешно сохранено'),
            duration: Duration(seconds: 2),
          ),
        );

        _nameController.clear();
        _expiryDateController.clear();
        _notificationDaysController.clear();
        _quantityController.clear();
        _commentController.clear();
        _quantityNumController.clear();
        setState(() {
          _selectedAddress = 'Выберите адрес';
          _image = null;
          photoChange = false;
          isFavorite = false;
          isPrivate = false;
        });
      }
    } catch (error) {
      print('Error saving medicine: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка при сохранении лекарства')),
      );
    } finally {
      setState(() {
        isLoading = false; 
      });
    }
  }

  bool _isCurrentUserCreator() {
    User? user = _auth.currentUser;
    return user != null && user.uid == widget.addedBy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        title: Text('Создание лекарства'),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Название'),
              ),
              SizedBox(height: 8.0),
              GestureDetector(
                onTap: () => _selectExpiryDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(labelText: 'Срок годности'),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                    onPressed: _handleSearch, 
                    child: Icon(Icons.search),
                  ),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1),
  ),
                      onPressed: _showAddressSelectionPopup,
                      child: FittedBox(
                        child: Text(_selectedAddress),
                      ),
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1),
  ),
                    onPressed: _showImageSourceDialog,
                    child: Text('Добавить фотографию'),
                  ),
                  SizedBox(width: 8.0),
                  photoChange ? 
                  Container(
                    height: 80,
                    width: 80,
                    child:
                  (imageRed != '') ?
                   Image.network(
                    imageRed,
                    // height: 100,
                    // width: double.infinity,
                    fit: BoxFit.cover,
                  ):
                  null )
                  :
                  Container(
                    height: 80,
                    width: 80,
                    child: _image != null
                        ? Image.file(File(_image!.path), fit: BoxFit.cover)
                        : null,
                  ),
                ],
              ),
              
              TextField(
                controller: _notificationDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText:
                        'Предупреждение до истечения годности. (дней)'),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedStorageOption,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStorageOption = newValue!;
                      });
                    },
                    items: <String>['мл', 'саше', 'таблетки']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 40.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                    onPressed: _scan,
                    child: Text("Сканировать штрих-код"),
                  ),
                ],
              ),

              SizedBox(height: 8.0),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Количество'),
              ),
              TextField(
                controller: _quantityNumController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Меньше какого кол-ва предупредить ($_selectedStorageOption)'),
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(labelText: 'Комментарий'),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isFavorite = !isFavorite;
                        
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Color.fromARGB(255, 10, 114, 1) : null,
                    ),
                  ),
                  Text('Избранное', style: TextStyle(
                    // color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                  ),),
                  SizedBox(width: 3.0),
                   if (!widget.isEditing || _isCurrentUserCreator())
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isPrivate = !isPrivate;
                      });
                    },
                    icon: Icon(
                      isPrivate ? Icons.lock : Icons.lock_open,
                      color: isPrivate ? Color.fromARGB(255, 10, 114, 1) : null,
                    ),
                  ),
                   if (!widget.isEditing || _isCurrentUserCreator())
                  Text('Приватное', style: TextStyle(
                    // color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                  ),), SizedBox(width: 10.0),
                   isLoading
                  ? Center()
                  : ElevatedButton(
                    style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                      onPressed: _saveMedicine,
                      child: Text('Сохранить', style: TextStyle(
                    // color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  
}
