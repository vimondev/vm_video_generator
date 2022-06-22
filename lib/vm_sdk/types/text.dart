enum ETextID {
  Title_DA001,
  Title_DA002,
  Title_DA003,
  Title_DA004,
  Title_DA005,
  Title_DA006,
  Title_DA007,
  Title_DA008,
  Title_DA009,
  // Title_DA010,
  Title_DA011,
  Title_DA012,
  Title_DA013,
  Title_DA014,
  Title_DA015,
  Title_DA016,
  Title_DA017,
  Title_DA018,
  // Title_DA019,
  Title_DA020,
  Title_DA021,
  Title_DA022,
  Title_DA023,
  // Title_DA024,
  Title_HJ001,
  Title_HJ002,
  Title_HJ003,
  Title_HJ004,
  Title_HJ005,
  Title_HJ006,
  Title_HJ007,
  Title_HJ008,
  Title_HJ009,
  Title_HJ010,
  Title_HJ011,
  Title_HJ012,
  Title_HJ013,
  Title_HJ014,
  Title_HJ015,
  Title_HJ018,
  Title_HJ019,
  // Title_HJ020,
  Title_ON001,
  Title_ON002,
  Title_ON003,
  Title_ON005,
  Title_ON006,
  Title_ON007,
  Title_ON008,
  Title_ON009,
  Title_ON010,
  Title_ON011,
  Title_ON012,
  // Title_ON013,
  Title_SW001,
  Title_SW002,
  Title_SW003,
  Title_SW004,
  Title_SW005,
  Title_SW006,
  Title_SW007,
  Title_SW008,
  Title_SW009,
  // Title_SW010,
  Title_SW011,
  Title_SW012,
  Title_SW013,
  Title_SW014,
  Title_SW015,
  Title_SW016,
  Title_SW017,
  Title_SW018,
  // Title_SW019,
  Title_SW020,
  Title_SW021,
  Title_SW022,
  // Title_SW023,
  // Title_YJ001,
  // Title_YJ002,
  Title_YJ003,
  Title_YJ004,
  Title_YJ005,
  Title_YJ006,
  Title_YJ007,
  Title_YJ008,
  // Title_YJ009,
  Title_YJ010,
  Title_YJ011,
  Title_YJ012,
  Title_YJ013,
  // Title_YJ014,
  Title_YJ016,
  Title_YJ017,
  Title_YJ018,
  Title_YJ019,
  Title_YJ020,
  Title_YJ021,
  Title_YJ022,
  Caption_DA001,
  Caption_DA002,
  Caption_DA003,
  Caption_DA004,
  Caption_DA005,
  Caption_SW001,
  Caption_SW002,
  Caption_SW003,
  Caption_SW004,
  // Caption_YJ001,
  Caption_YJ002,
  Caption_YJ003,
  Caption_YJ004,
  // Caption_YJ005,
  // Caption_YJ006,
  // Caption_YJ007,
  Caption_YJ008
}

enum ETextType { Title, Caption }

class TextData {
  ETextType type;
  String json;

  List<String> fontFamily;
  List<String> fontBase64;
  List<String> texts = [];

  TextData(this.type, this.json, this.fontFamily, this.fontBase64);
}
class TextExportData {
  ETextID id;

  double x = 0;
  double y = 0;
  double width;
  double height;
  double frameRate;
  double scale = 0;
  double rotate = 0;
  String previewImagePath;
  String allSequencesPath;
  
  Map<String, String> texts = {};

  TextExportData(this.id, this.width, this.height, this.frameRate, this.previewImagePath, this.allSequencesPath);
}