import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'widgets/navbar.dart';

class CreateLuminaPostPage extends StatefulWidget {
  final String title;
  final String story;
  final String country;
  final List<String> themes;

  const CreateLuminaPostPage({
    Key? key,
    required this.title,
    required this.story,
    required this.country,
    required this.themes,
  }) : super(key: key);

  @override
  _CreateLuminaPostPageState createState() => _CreateLuminaPostPageState();
}

class _CreateLuminaPostPageState extends State<CreateLuminaPostPage> {
  bool isPosting = false;
  bool isLoading = false;
  String loadingMessage = "Preparing your post...";
  String errorMessage = "";

  List<String> sentences = [];
  Map<int, bool> selectedSentences = {};
  
  // Change from URL strings to base64 strings
  List<String> previewBase64Images = [];

  String generatedCaption = "";
  TextEditingController captionController = TextEditingController();

  // Color scheme toggle state (values: "orange" or "purple")
  String _colorScheme = "orange";

  // Update this variable with your backend URL.
  final String currentBackendUrl = "https://1741-73-189-131-67.ngrok-free.app";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    sentences = _tokenizeSentences(widget.story);
    for (int i = 0; i < sentences.length && i < 10; i++) {
      selectedSentences[i] = true;
    }
    _generateCaption();
  }

  List<String> _tokenizeSentences(String text) {
    final RegExp enders = RegExp(r'[.!?]\s+');
    final List<String> raw = text.split(enders);
    final List<String> clean = raw
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim() + ".")
        .toList();
    return clean.length > 10 ? clean.sublist(0, 10) : clean;
  }

  Future<void> _generateCaption() async {
    setState(() {
      isLoading = true;
      loadingMessage = "Generating caption...";
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse("$currentBackendUrl/generate-caption"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": widget.title,
          "story": widget.story,
          "country": widget.country,
          "themes": widget.themes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final caption = data['caption'];
        setState(() {
          generatedCaption = caption;
          captionController.text = caption;
        });
      } else {
        setState(() {
          generatedCaption = "Failed to generate caption. Please write your own.";
          captionController.text = generatedCaption;
          errorMessage = "Server returned status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        generatedCaption = "Failed to generate caption. Please write your own.";
        captionController.text = generatedCaption;
        errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generatePreviewImages() async {
    setState(() {
      isLoading = true;
      loadingMessage = "Generating post preview...";
      errorMessage = "";
      previewBase64Images = []; // Clear previous images
    });

    try {
      final selected = selectedSentences.entries
          .where((entry) => entry.value)
          .map((entry) => sentences[entry.key])
          .toList();

      print("Sending request to backend...");
      final response = await http.post(
        Uri.parse("$currentBackendUrl/generate-preview"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": widget.title,
          "country": widget.country,
          "caption": captionController.text,
          "color_scheme": _colorScheme,
          "sentences": selected,
          "theme": widget.themes.isNotEmpty ? widget.themes[0] : ""
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body (first 100 chars): ${response.body.substring(0, min(100, response.body.length))}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('preview_base64')) {
          final List<dynamic> base64List = data['preview_base64'];
          if (base64List.isNotEmpty) {
            setState(() {
              previewBase64Images = base64List.cast<String>();
            });
            print("📸 Received ${previewBase64Images.length} base64 images");
          } else {
            throw Exception("Empty base64 images list received");
          }
        } else {
          throw Exception("No base64 images in response");
        }
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error generating preview: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate preview: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _postToInstagram() async {
    setState(() {
      isPosting = true;
      loadingMessage = "Uploading to Instagram...";
      errorMessage = "";
    });

    try {
      final selected = selectedSentences.entries
          .where((entry) => entry.value)
          .map((entry) => sentences[entry.key])
          .toList();

      final response = await http.post(
        Uri.parse("$currentBackendUrl/post-instagram"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": widget.title,
          "country": widget.country,
          "caption": captionController.text,
          "theme": _colorScheme, // Use color_scheme instead of hardcoded "orange"
          "sentences": selected,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully posted to Instagram!")),
        );
        Navigator.pushNamed(context, '/explore');
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error posting to Instagram: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post to Instagram: $e")),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'createLuminaPost'),
      ),
      body: isLoading || isPosting ? _buildLoadingView() : _buildMainContent(),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.white,
            Color.fromARGB(255, 255, 179, 113),
          ],
          stops: [0.1, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
            SizedBox(height: 20),
            Text(
              loadingMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF5722),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.white,
            Color.fromARGB(255, 255, 179, 113),
          ],
          stops: [0.1, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Page Title with red-orange gradient
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/ig.png', // Ensure this asset is available in your assets folder.
                    width: 60,
                    height: 60,
                  ),
                  SizedBox(width: 15),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.red, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: Text(
                      "Post to Instagram",
                      style: GoogleFonts.baloo2(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // This will be masked by the gradient
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                "Choose which parts of your story to share",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              // Error message (if any)
              if (errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              SizedBox(height: 30),
              // Sentence Selection Section
              _buildSentenceSelection(),
              SizedBox(height: 30),
              // Caption Section
              _buildCaptionSection(),
              SizedBox(height: 20),
              // Color Scheme Toggle Section
              _buildColorSchemeToggle(),
              SizedBox(height: 30),
              // New Update Preview Button placed right above the post preview section
              SizedBox(height: 30),
              Center(
                child: Container(
                  width: 300, // Fixed width for the button
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: _generatePreviewImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    child: Text(
                      "Update Preview",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Preview Section
              _buildPreviewSection(),
              SizedBox(height: 40),
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select sentences to include (max 10)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: sentences.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              return CheckboxListTile(
                title: Text(
                  sentences[index],
                  style: TextStyle(fontSize: 14),
                ),
                value: selectedSentences[index] ?? false,
                activeColor: Color(0xFFFF5722),
                onChanged: (bool? value) {
                  setState(() {
                    selectedSentences[index] = value ?? false;
                  });
                },
              );
            },
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  // Color Scheme Toggle widget
  Widget _buildColorSchemeToggle() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(
        "Select Color Scheme",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      SizedBox(width: 16),
      ChoiceChip(
        label: Text("Orange"),
        selected: _colorScheme == "orange",
        selectedColor: Colors.deepOrange,
        onSelected: (selected) {
          setState(() {
            _colorScheme = "orange";
          });
        },
      ),
      SizedBox(width: 16),
      ChoiceChip(
        label: Text("Purple"),
        selected: _colorScheme == "purple",
        selectedColor: Colors.purple,
        onSelected: (selected) {
          setState(() {
            _colorScheme = "purple";
          });
        },
      ),
    ],
  );
}

  Widget _buildCaptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Instagram Caption",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: TextField(
            controller: captionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Edit your caption here...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(Icons.refresh, size: 16),
              label: Text("Regenerate Caption"),
              onPressed: _generateCaption,
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFF5722),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Post Preview",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: 12),
      previewBase64Images.isEmpty
          ? Center(
              child: Text(
                "Preview not available. Please update preview.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          : Container(
              height: 300, // Adjusted container height
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: previewBase64Images.map((base64Image) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(base64Image),
                          width: 300, // Adjusted image width
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("🛑 Image failed to load");
                            return Container(
                              width: 300,
                              height: 300,
                              color: Colors.red[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.red),
                                  Text("Error loading",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
    ],
  );
}

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            "Cancel",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: previewBase64Images.isNotEmpty ? _postToInstagram : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF3D00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            "Post to Instagram",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}