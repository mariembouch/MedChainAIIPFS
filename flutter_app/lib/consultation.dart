import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // For JSON parsing
import 'contract_linking.dart'; // Import the ContractLinking class

class ImagePickerExample extends StatefulWidget {
  @override
  _ImagePickerExampleState createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  Uint8List? _imageData;
  String? _result;
  bool _isLoading = false;
  String? predictedClass;
  double? predictedProbability;
  String _ipfsHash = "";

  // Pinata API keys (replace with valid ones)
  final String pinataApiKey = '0241008a407056f2cf25';
  final String pinataSecretApiKey =
      'd6997b03f26525b8193f19e4dfc8aabeb3517eaed045abe963a889ceee23f2e3';

  // Form field controllers
  final TextEditingController AdresseController = TextEditingController();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController genderController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorIDController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
        _result = null;
        predictedClass = null;
        predictedProbability = null;
        _ipfsHash = "";
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _sendImageToServer() async {
    if (_imageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Send image to server
      final uri = Uri.parse('http://127.0.0.1:5000/api/classify');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'imagefile',
          _imageData!,
          filename: 'image.jpg',
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          Map<String, dynamic> resultMap = jsonDecode(responseBody);
          predictedClass = resultMap['predicted_class'];
          predictedProbability = resultMap['predicted_probability'];
        });
      } else {
        setState(() {
          _result = 'Error: ${response.reasonPhrase}';
        });
      }

      // Step 2: Upload the image to IPFS
      final ipfsUri =
          Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
      final ipfsRequest = http.MultipartRequest('POST', ipfsUri)
        ..headers.addAll({
          'pinata_api_key': pinataApiKey,
          'pinata_secret_api_key': pinataSecretApiKey,
        })
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _imageData!,
          filename: 'image.jpg',
        ));

      final ipfsResponse = await ipfsRequest.send();
      final ipfsResponseBody = await ipfsResponse.stream.bytesToString();
      final jsonResponse = jsonDecode(ipfsResponseBody);

      if (ipfsResponse.statusCode == 200) {
        setState(() {
          _ipfsHash = jsonResponse['IpfsHash'] ?? 'Hash not found';
        });
      } else {
        throw Exception('IPFS Upload Error: ${ipfsResponse.reasonPhrase}');
      }
      // Step 3: Add patient data to blockchain
      if (AdresseController.text.isNotEmpty &&
          nameController.text.isNotEmpty &&
          surnameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          genderController.text.isNotEmpty &&
          doctorNameController.text.isNotEmpty &&
          doctorIDController.text.isNotEmpty &&
          _ipfsHash.isNotEmpty &&
          predictedClass != null &&
          predictedProbability != null) {
        final doctorId = int.tryParse(doctorIDController.text) ?? 0;

        final contractLinking =
            Provider.of<ContractLinking>(context, listen: false);

        await contractLinking.addPatient(
          AdresseController.text,
          nameController.text,
          surnameController.text,
          emailController.text,
          genderController.text,
          doctorNameController.text,
          doctorId,
          predictedClass!,
          predictedProbability!.toStringAsFixed(4),
          _ipfsHash,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Patient data successfully added to blockchain")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please complete all fields")),
        );
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select and Upload Image',
          style: TextStyle(
            color: Colors.teal, // Set your desired color here
            fontWeight: FontWeight.bold, // Optional: Make it bold
            fontSize: 20.0, // Optional: Adjust font size
          ),
        ),
        backgroundColor:
            Colors.white, // Optional: Change AppBar background color
        iconTheme:
            IconThemeData(color: Colors.teal), // Optional: Change icon colors
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Form Fields

              TextFormField(
                  controller: AdresseController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 10),
              TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'name',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 10),
              TextFormField(
                  controller: surnameController,
                  decoration: InputDecoration(
                    labelText: 'surname',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 10),
              TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'email',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 10),
              TextFormField(
                  controller: genderController,
                  decoration: InputDecoration(
                    labelText: 'gender',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 10),
              TextFormField(
                  controller: doctorNameController,
                  decoration: InputDecoration(
                    labelText: 'doctorName',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),

              SizedBox(height: 20),
              TextFormField(
                  controller: doctorIDController,
                  decoration: InputDecoration(
                    labelText: 'doctorId',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  )),
              SizedBox(height: 20),
// Results
              if (predictedClass != null)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Predicted Class',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  initialValue: predictedClass,
                  readOnly: true,
                ),
              SizedBox(height: 10),
              if (predictedProbability != null)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Predicted Probability',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  initialValue: predictedProbability!.toStringAsFixed(4),
                  readOnly: true,
                ),
              SizedBox(height: 20),
              if (_ipfsHash.isNotEmpty)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'IPFS CID',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  initialValue: _ipfsHash,
                  readOnly: true,
                ),
              // Image Display
              if (_imageData != null)
                Image.memory(
                  _imageData!,
                  height: 200,
                )
              else
                Text('No image selected', style: TextStyle(color: Colors.teal)),

              SizedBox(height: 20),

              // Buttons
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal, // Couleur du texte
                  textStyle: TextStyle(
                    fontSize: 16, // Taille du texte
                    fontWeight: FontWeight.bold, // Gras
                  ),
                ),
                child: Text('Pick an Image'),
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _sendImageToServer,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal, // Couleur du texte
                    textStyle: TextStyle(
                      fontSize: 16, // Taille du texte
                      fontWeight: FontWeight.bold, // Gras
                    ),
                  ),
                  child: Text('Send to Server'),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (AdresseController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Please enter an address to fetch data"),
                      ),
                    );
                    return;
                  }
                  print(AdresseController.text);
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Call the getPatient function
                    final contractLinking =
                        Provider.of<ContractLinking>(context, listen: false);
                    final patientData = await contractLinking
                        .getPatient(AdresseController.text);

                    if (patientData != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Patient data fetched successfully"),
                        ),
                      );

                      // Optionally display the fetched data
                      print(patientData);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("No data found for the given address"),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error fetching data: $e"),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal, // Couleur du text
                  textStyle: TextStyle(
                    fontSize: 16, // Taille du texte
                    fontWeight: FontWeight.bold, // Style gras
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Fetch Patient Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
