import '../types/types.dart';

EMediaLabel getMediaLabel(String type) {
  switch (type) {
    case "background":
      return EMediaLabel.background;

    case "person":
      return EMediaLabel.person;

    case "action":
      return EMediaLabel.action;

    case "object":
      return EMediaLabel.object;

    case "food":
      return EMediaLabel.food;

    case "animal":
      return EMediaLabel.animal;

    case "others":
      return EMediaLabel.others;

    default:
      return EMediaLabel.none;
  }
}

EMusicSpeed getMusicSpeed(String speed) {
  switch (speed) {
    case "F":
      return EMusicSpeed.fast;
      
    case "S":
      return EMusicSpeed.slow;

    case "M":
    default:
      return EMusicSpeed.medium;
  }
}