import 'package:http/http.dart' as http;

String _endpoint = "http://3.38.130.68:8000";

Future<http.Response> httpGet(String url, Map<String, String>? headers) async {
  if (!url.startsWith("http")) {
    url = "$_endpoint$url";
  }

  final uri = Uri.parse(url);
  return await http.get(uri, headers: headers);
}
