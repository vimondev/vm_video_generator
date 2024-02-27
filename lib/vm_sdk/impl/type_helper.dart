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