import 'package:flutter/material.dart';
import 'package:lumina/services/firebase_service.dart';
import 'widgets/navbar.dart';

class PostStoryPage extends StatefulWidget {
  @override
  _PostStoryPageState createState() => _PostStoryPageState();
}

class _PostStoryPageState extends State<PostStoryPage> {
  String? selectedTheme1;
  String? selectedTheme2; // Optional second theme
  
  String? selectedCountry;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController customTheme1Controller = TextEditingController();
  final TextEditingController customTheme2Controller = TextEditingController();

  // Updated themes list with all possible themes
  final List<String> themes = [
    'Workplace',
    'Domestic',
    'Education',
    'Cultural',
    'Public Space',
    'Identity',
    'Healthcare',
    'Other'
  ];
  final List<String> countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 
    'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 
    'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 
    'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 
    'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 
    'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica', 
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 
    'Eswatini', 'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 
    'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 'Hungary', 
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 
    'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 
    'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi', 
    'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 
    'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 
    'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 
    'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Palestine', 'Panama', 
    'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 
    'Russia', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 
    'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 
    'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 
    'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 
    'Syria', 'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 
    'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 
    'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 
    'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe', 'Other'
  ];

  void _submitStory() async {
    if (titleController.text.isNotEmpty && 
        bodyController.text.isNotEmpty && 
        selectedTheme1 != null && 
        selectedCountry != null) {
      
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        
        // Compose themes list with Theme 1 and Theme 2 (if selected)
        List<String> themesSelected = [];
        if (selectedTheme1 != null) {
          if (selectedTheme1 == 'Other' && customTheme1Controller.text.isNotEmpty) {
            themesSelected.add(customTheme1Controller.text);
          } else {
            themesSelected.add(selectedTheme1!);
          }
        }
        if (selectedTheme2 != null) {
          if (selectedTheme2 == 'Other' && customTheme2Controller.text.isNotEmpty) {
            themesSelected.add(customTheme2Controller.text);
          } else {
            themesSelected.add(selectedTheme2!);
          }
        }
        
        // Add story to Firestore with updated themes list
        await FirebaseService.addStory(
          title: titleController.text,
          story: bodyController.text,
          country: selectedCountry!,
          themes: themesSelected,
          keywords: [], // Optionally add keyword extraction here
        );
        
        // Hide loading indicator
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Your story has been posted anonymously. Thank you for sharing.")),
        );
        
        // Navigate back to explore page
        Navigator.pushNamed(context, '/explore');
      } catch (e) {
        // Hide loading indicator
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error posting story. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'postStory'),
      ),
      body: Stack(
        children: [
          // Background gradient layer
          Container(
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
          ),
          // Content layer
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 100, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main title
                  Text(
                    "Post a Story",
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5722), // Red-orange color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Subtitle with partial bold text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: "Your story is powerful -- and "),
                        TextSpan(
                          text: "100% anonymous",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Title field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Title",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "(Max 50 characters)",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: TextField(
                            controller: titleController,
                            maxLength: 50,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Body field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Body",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "(No limit! Share as much as you want.)",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: TextField(
                            controller: bodyController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Theme and Country dropdowns
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable themes panel
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select up to 2 Themes",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: themes.map((theme) {
                                // Check if theme is selected (either as Theme 1 or Theme 2)
                                bool isSelected = (selectedTheme1 == theme || selectedTheme2 == theme);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        // Unselect the theme if already selected
                                        if (selectedTheme1 == theme) {
                                          selectedTheme1 = null;
                                          customTheme1Controller.clear();
                                        } else if (selectedTheme2 == theme) {
                                          selectedTheme2 = null;
                                          customTheme2Controller.clear();
                                        }
                                      } else {
                                        // If less than 2 themes are selected, add this theme
                                        if (selectedTheme1 == null) {
                                          selectedTheme1 = theme;
                                        } else if (selectedTheme2 == null) {
                                          selectedTheme2 = theme;
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      theme,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            // If user has selected "Other", show a text field for custom theme input
                            if (selectedTheme1 == 'Other')
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: TextField(
                                  controller: customTheme1Controller,
                                  decoration: InputDecoration(
                                    labelText: 'Enter custom theme for selection 1',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            if (selectedTheme2 == 'Other')
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: TextField(
                                  controller: customTheme2Controller,
                                  decoration: InputDecoration(
                                    labelText: 'Enter custom theme for selection 2',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Country dropdown – remains unchanged
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2, // About 1/4 of screen width
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Country",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: DropdownButtonFormField<String>(
                                icon: Icon(Icons.arrow_drop_down, size: 20),
                                isExpanded: true,
                                alignment: AlignmentDirectional.centerEnd,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: InputBorder.none,
                                ),
                                hint: Text("Country", style: TextStyle(fontSize: 13)),
                                items: countries.map((String country) {
                                  return DropdownMenuItem<String>(
                                    value: country,
                                    child: Text(
                                      country,
                                      style: TextStyle(fontSize: 13),
                                      textAlign: TextAlign.right,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedCountry = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  
                  // Post button
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitStory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF3D00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Post",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}