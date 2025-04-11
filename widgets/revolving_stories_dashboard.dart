if (_pageController.hasClients) {
  _pageController.animateToPage(
    targetPage,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}