enum ETitleType { title01, title02, title03, title04, title05 }

class TitleData {
  String json;
  String fontFamily;
  String fontBase64;
  List<String> texts = [];

  TitleData(this.json, this.fontFamily, this.fontBase64);
}

class ExportedTitlePNGSequenceData {
  String folderPath;
  int width;
  int height;
  double frameRate;

  ExportedTitlePNGSequenceData(
      this.folderPath, this.width, this.height, this.frameRate);
}
