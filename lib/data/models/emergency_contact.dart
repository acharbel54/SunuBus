/// Contact d'urgence pour la sécurisation des trajets (partage de trajet,
/// bouton SOS). Persisté par numéro de téléphone (voir `TripSecurityService`).
class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
}
