class EmpresaRegisterInput {
  final String nomEmpresa;
  final String cif;
  final String email;
  final String password;
  final String passwordConfirm;
  final String? telefon;
  final String? personaContacte;
  final String? sector;

  const EmpresaRegisterInput({
    required this.nomEmpresa,
    required this.cif,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    this.telefon,
    this.personaContacte,
    this.sector,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom_empresa': nomEmpresa.trim(),
      'cif': cif.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'password_confirm': passwordConfirm,
      if (telefon != null && telefon!.trim().isNotEmpty)
        'telefon': telefon!.trim(),
      if (personaContacte != null &&
          personaContacte!.trim().isNotEmpty)
        'persona_contacte': personaContacte!.trim(),
      if (sector != null && sector!.trim().isNotEmpty)
        'sector': sector!.trim(),
    };
  }
}

class EmpresaRegisterResult {
  final int? empresaId;
  final String email;
  final String message;
  final bool requiresVerification;

  const EmpresaRegisterResult({
    required this.empresaId,
    required this.email,
    required this.message,
    required this.requiresVerification,
  });

  factory EmpresaRegisterResult.fromMap(
    Map<String, dynamic> map,
  ) {
    return EmpresaRegisterResult(
      empresaId: _parseInt(map['empresa_id']),
      email: map['email']?.toString() ?? '',
      message: map['message']?.toString() ??
          'Compte creat correctament',
      requiresVerification:
          map['requires_verification'] == true,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}