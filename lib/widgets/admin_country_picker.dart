import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../services/admin_contact.dart';

class AdminCountryPicker extends StatelessWidget {
  final AdminCountry value;
  final ValueChanged<AdminCountry> onChanged;
  final bool enabled;
  const AdminCountryPicker({super.key, required this.value, required this.onChanged, this.enabled = true});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      icon: const Icon(Icons.public),
      label: Text('${value.name} (${value.dialCode})'),
      onPressed: !enabled ? null : () => showCountryPicker(
        context: context, showPhoneCode: true,
        onSelect: (country) => onChanged(AdminCountry(
          country.countryCode, '+${country.phoneCode}', country.name)),
      ),
    ),
  );
}
