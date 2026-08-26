void main() {
  dynamic data = {
    "status": false,
    "message": "Endpoint not found.",
    "data": null
  };
  
  if (data is Map) {
    final msg = data['message']?.toString().trim();
    print(msg);
    final err = data['error']?.toString().trim();
    print(err);
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) print(first.first.toString());
    }
  }
}
