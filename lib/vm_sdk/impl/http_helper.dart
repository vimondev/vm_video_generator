import 'package:http/http.dart' as http;

String _endpoint = "https://api-prod.viiv.ai";

Future<http.Response> httpGet(String url, Map<String, String>? headers) async {
  if (!url.startsWith("http")) {
    url = "$_endpoint$url";
  }

  final uri = Uri.parse(url);
  return await http.get(uri, headers: headers);
}
