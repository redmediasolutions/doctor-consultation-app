import '../../core/utils/formatters.dart';
import 'json_utils.dart';

class Store {
  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.pharmacistName,
    required this.drugLicenseNo,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String pharmacistName;
  final String drugLicenseNo;

  String get shortName => Fmt.shortStore(name);

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: asString(j['id']),
        name: asString(j['name']),
        address: asString(j['address']),
        city: asString(j['city']),
        phone: asString(j['phone']),
        pharmacistName: asString(j['pharmacistName']),
        drugLicenseNo: asString(j['drugLicenseNo']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'pharmacistName': pharmacistName,
        'drugLicenseNo': drugLicenseNo,
      };
}
