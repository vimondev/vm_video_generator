enum ETitleType {
  // title01,
  // title02,
  // title03,
  // title04,
  // title05,
  title06,
  title07,
  title08,
  title09,
  title10,
  title11,
  title12,
  title13,
  title14,
  title15,
  title16,
  title17,
  title18,
  title19,
  title20,
  title21,
  title22,
  title23,
  title24,
  title25,
  title26,
  title27,
  title28,
  title29,
  title30,
  title31,
  title32,
  title33,
}

class TitleData {
  String json;
  List<String> fontFamily;
  List<String> fontBase64;
  List<String> texts = [];

  TitleData(this.json, this.fontFamily, this.fontBase64);
}

class ExportedTitlePNGSequenceData {
  String folderPath;
  double width;
  double height;
  double frameRate;

  ExportedTitlePNGSequenceData(
      this.folderPath, this.width, this.height, this.frameRate);
}
