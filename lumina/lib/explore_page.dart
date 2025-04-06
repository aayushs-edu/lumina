import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/navbar.dart';

class ExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'explore'),
      ),
      backgroundColor: Colors.white,
      body: StoryListView(),
    );
  }
}

class StoryListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
        child: Column(
          children: [
            // Search bar and filter
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stories...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.tune),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Story list
            Expanded(
              child: ListView(
                children: [
                  ExpandableStoryCard(
                    title: "They wouldn't let me work",
                    theme: "Workplace",
                    themeColor: Colors.red,
                    country: "India",
                    shortContent: "I have experience gender inequality at my job ever since I started working there...",
                    fullContent: "I have experience gender inequality at my job ever since I started working there. Nepal's total population is about 30 million. Out of this more than fifty percent is Women.\n\nIn Nepal, like other developing countries, the state of women is not satisfactory. Male dominated family system provides very little scope for the female to assert their identity. They are marginalized from economic and social opportunities due to illiteracy, poverty and conservative social taboos. The present status of women is said to be strong than the past but it is the same.\n\n32 women have been Members of Parliament after restoration of democracy but it is only limited up to the written forms but not so practically. The status of women is the same as it used to be in the past. Along with the passes of time different changes has been made and in various sectors reservation seats no. for women have been extended.",
                    likes: 25,
                  ),
                  SizedBox(height: 16),
                  ExpandableStoryCard(
                    title: "My husband beat me",
                    theme: "Domestic",
                    themeColor: Colors.purple,
                    country: "Saudi Arabia",
                    shortContent: "I have experience gender inequality at my job ever since I started working there...",
                    fullContent: "I have experience gender inequality at my job ever since I started working there. This is a placeholder for the full story content.",
                    likes: 14,
                  ),
                  SizedBox(height: 16),
                  ExpandableStoryCard(
                    title: "They wouldn't let me work",
                    theme: "Workplace",
                    themeColor: Colors.red,
                    country: "India",
                    shortContent: "I have experience gender inequality at my job ever since I started working there...",
                    fullContent: "I have experience gender inequality at my job ever since I started working there. This is a placeholder for the full story content.",
                    likes: 25,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableStoryCard extends StatefulWidget {
  final String title;
  final String theme;
  final Color themeColor;
  final String country;
  final String shortContent;
  final String fullContent;
  final int likes;

  const ExpandableStoryCard({
    Key? key,
    required this.title,
    required this.theme,
    required this.themeColor,
    required this.country,
    required this.shortContent,
    required this.fullContent,
    required this.likes,
  }) : super(key: key);

  @override
  _ExpandableStoryCardState createState() => _ExpandableStoryCardState();
}

class _ExpandableStoryCardState extends State<ExpandableStoryCard> {
  bool _isExpanded = false;
  bool _isHovering = false;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: _isHovering && !_isExpanded
              ? Matrix4.translationValues(0, -5, 0)
              : Matrix4.translationValues(0, 0, 0),
          decoration: BoxDecoration(
            border: Border.all(color: widget.themeColor, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovering || _isExpanded
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and theme tag
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '"${widget.title}"',
                            style: GoogleFonts.baloo2(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.themeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.theme,
                              style: GoogleFonts.baloo2(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Country name
                    Text(
                      widget.country,
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Story content - short or full based on expansion state
                Text(
                  _isExpanded ? widget.fullContent : widget.shortContent,
                  style: GoogleFonts.baloo2(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                // Like counter - clickable when expanded
                Align(
                  alignment: Alignment.bottomRight,
                  child: _isExpanded
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_isLiked) {
                                _likeCount--;
                              } else {
                                _likeCount++;
                              }
                              _isLiked = !_isLiked;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_likeCount',
                                style: GoogleFonts.baloo2(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.likes}',
                              style: GoogleFonts.baloo2(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}