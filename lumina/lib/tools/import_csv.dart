import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lumina/firebase_options.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV to Firebase Uploader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CsvUploader(),
    );
  }
}

class CsvUploader extends StatefulWidget {
  @override
  _CsvUploaderState createState() => _CsvUploaderState();
}

class _CsvUploaderState extends State<CsvUploader> {
  bool _isLoading = false;
  String _status = '';
  int _uploadedCount = 0;
  int _totalCount = 0;
  String _filePath = '';

  Future<void> pickAndUploadCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path!;
          _status = 'Selected file: $_filePath';
        });
        uploadCsvToFirebase(_filePath);
      } else {
        setState(() {
          _status = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error selecting file: ${e.toString()}';
      });
    }
  }

  Future<void> uploadCsvToFirebase(String filePath) async {
    setState(() {
      _isLoading = true;
      _status = 'Reading CSV file...';
      _uploadedCount = 0;
    });

    try {
      // Read the CSV file from the path
      final File file = File(filePath);
      final String csvString = await file.readAsString();
      
      // Parse the CSV
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      // Extract headers (first row)
      List<String> headers = csvTable[0].map((header) => header.toString().trim()).toList();
      
      // Remove the header row
      csvTable.removeAt(0);
      
      setState(() {
        _totalCount = csvTable.length;
        _status = 'Uploading ${csvTable.length} records to Firebase...';
      });

      // Get Firebase instance
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection('stories'); // Change to your collection name

      // Upload each row
      for (var i = 0; i < csvTable.length; i++) {
        var row = csvTable[i];
        
        // Create a map for the current row data
        Map<String, dynamic> data = {};
        
        // Map CSV fields to Firebase fields
        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            String header = headers[j];
            dynamic value = row[j];
            
            // Handle specific field mappings
            switch (header) {
              case 'Country':
                data['country'] = value.toString();
                break;
              case 'Story':
                data['story'] = value.toString();
                break;
              case 'Themes':
                // Convert themes to an array if it's a string
                if (value is String) {
                  List<String> themes = value.split(',')
                      .map((theme) => theme.trim())
                      .where((theme) => theme.isNotEmpty)
                      .toList();
                  data['themes'] = themes;
                } else {
                  data['themes'] = [];
                }
                break;
              case 'Title':
                data['title'] = value.toString();
                break;
              // Ignore 'Cluster' as it's not in Firebase schema
              case 'Cluster':
                // Skip this field
                break;
              default:
                // Handle any other fields
                data[header.toLowerCase()] = value;
            }
          }
        }
        
        // Add missing fields
        data['likes'] = 0;
        data['reports'] = 0;
        data['userId'] = 'anonymous';
        data['timestamp'] = Timestamp.now().toDate().toUtc().toString();
        
        // Extract keywords (example: taking first 3 words from story)
        String story = data['story'] ?? '';
        List<String> words = story.split(' ')
            .where((word) => word.trim().isNotEmpty)
            .take(3)
            .toList();
        data['keywords'] = words;
        
        // Upload to Firebase
        await collectionRef.add(data);
        
        setState(() {
          _uploadedCount++;
          _status = 'Uploaded $_uploadedCount of $_totalCount records...';
        });
      }

      setState(() {
        _status = 'Successfully uploaded $_uploadedCount records to Firebase!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSV to Firebase Uploader'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading)
                CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : pickAndUploadCsv,
                child: Text('Select and Upload CSV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}