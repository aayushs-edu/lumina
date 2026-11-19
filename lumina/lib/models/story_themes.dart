/// Themes a story can be tagged with when it is posted (see PostStoryPage).
/// 'Other' is left out because it makes a poor daily spotlight.
const List<String> kSpotlightThemes = [
  'Workplace',
  'Domestic',
  'Education',
  'Cultural',
  'Public Space',
  'Identity',
  'Healthcare',
];

/// Today's spotlight theme, rotating by day of month.
String spotlightThemeFor(DateTime date) =>
    kSpotlightThemes[date.day % kSpotlightThemes.length];
