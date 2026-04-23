import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImageStorageService {
	// TODO: Replace these with values from your Cloudinary dashboard.
	static const String _cloudName = 'dlt6upoao';
	static const String _uploadPreset = 'ExpiryEase';

	Future<String> uploadProductImage({
		required File imageFile,
		String folder = 'smart_inventory',
	}) async {
		final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
		final request = http.MultipartRequest('POST', uri)
			..fields['upload_preset'] = _uploadPreset
			..fields['folder'] = folder
			..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

		final streamedResponse = await request.send();
		final responseBody = await streamedResponse.stream.bytesToString();

		if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
			throw Exception('Cloudinary upload failed (${streamedResponse.statusCode}): $responseBody');
		}

		final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
		final secureUrl = (decoded['secure_url'] as String?)?.trim();
		if (secureUrl == null || secureUrl.isEmpty) {
			throw Exception('Cloudinary upload succeeded but no secure_url was returned.');
		}

		return secureUrl;
	}
}
