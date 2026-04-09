import 'dart:convert';

class TreballadorProfileData {
  final int id;
  final String nom;
  final String cognoms;
  final String? nickname;
  final String? telefon;
  final String? email;
  final String? fotoUrl;
  final TreballadorEmpresaActualRef? empresaActual;
  final String? carrecActual;
  final String? estatContracte;
  final int tasquesCount;
  final int obresCount;

  const TreballadorProfileData({
    required this.id,
    required this.nom,
    required this.cognoms,
    required this.nickname,
    required this.telefon,
    required this.email,
    required this.fotoUrl,
    required this.empresaActual,
    required this.carrecActual,
    required this.estatContracte,
    required this.tasquesCount,
    required this.obresCount,
  });

  factory TreballadorProfileData.fromMap(Map<String, dynamic> map) {
    final contracte = _asMap(map['contracte_vigent']);
    final subjecte = _asMap(map['subjecte']);

    return TreballadorProfileData(
      id: _asInt(
        map['id'] ??
            subjecte?['id'] ??
            map['id_treballador'],
      ),
      nom: _asString(
            map['nom'] ??
                subjecte?['nom'],
          ) ??
          'Treballador',
      cognoms: _asString(
            map['cognoms'] ??
                subjecte?['cognoms'],
          ) ??
          '',
      nickname: _asString(
        map['nickname'] ?? subjecte?['nickname'],
      ),
      telefon: _asString(map['telefon']),
      email: _asString(map['email']),
      fotoUrl: _resolveFotoUrl(map),
      empresaActual: TreballadorEmpresaActualRef.fromDynamic(
        map['empresa_actual'] ??
            map['empresa'] ??
            map['empresa_info'],
      ),
      carrecActual: _asString(
        map['carrec_actual'] ??
            contracte?['carrec'] ??
            map['carrec'],
      ),
      estatContracte: _asString(
        map['estat_contracte'] ??
            contracte?['estat'] ??
            map['estat'],
      ),
      tasquesCount: _asInt(
        map['tasques_count'] ??
            map['num_tasques'] ??
            map['tasquesCount'],
      ),
      obresCount: _asInt(
        map['obres_count'] ??
            map['num_obres'] ??
            map['obresCount'],
      ),
    );
  }

  factory TreballadorProfileData.fromJson(String source) {
    return TreballadorProfileData.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  String get nomComplet {
    final parts = <String>[
      nom.trim(),
      if ((cognoms).trim().isNotEmpty) cognoms.trim(),
    ];
    return parts.join(' ').trim();
  }

  String get aliasVisible {
    final nick = nickname?.trim();
    if (nick != null && nick.isNotEmpty) {
      return '@$nick';
    }
    return nomComplet;
  }

  String get empresaLabel {
    return empresaActual?.nomEmpresa?.trim().isNotEmpty == true
        ? empresaActual!.nomEmpresa!
        : 'Sense empresa activa';
  }

  String get carrecLabel {
    final value = carrecActual?.trim();
    return (value == null || value.isEmpty) ? 'Sense càrrec' : value;
  }

  String get estatLabel {
    final value = estatContracte?.trim();
    return (value == null || value.isEmpty) ? 'Sense estat' : value;
  }

  bool get hasContactInfo {
    return (telefon?.trim().isNotEmpty == true) ||
        (email?.trim().isNotEmpty == true);
  }

  bool get hasFoto {
    return fotoUrl?.trim().isNotEmpty == true;
  }

  String get tasquesCountLabel {
    return tasquesCount == 1 ? '1 tasca' : '$tasquesCount tasques';
  }

  String get obresCountLabel {
    return obresCount == 1 ? '1 obra' : '$obresCount obres';
  }
}

class TreballadorEmpresaActualRef {
  final int? id;
  final String? nomEmpresa;

  const TreballadorEmpresaActualRef({
    required this.id,
    required this.nomEmpresa,
  });

  factory TreballadorEmpresaActualRef.fromDynamic(dynamic value) {
    if (value == null) {
      return const TreballadorEmpresaActualRef(
        id: null,
        nomEmpresa: null,
      );
    }

    if (value is int) {
      return TreballadorEmpresaActualRef(
        id: value,
        nomEmpresa: 'Empresa #$value',
      );
    }

    if (value is String) {
      final text = value.trim();
      return TreballadorEmpresaActualRef(
        id: int.tryParse(text),
        nomEmpresa: text.isEmpty ? null : text,
      );
    }

    if (value is Map<String, dynamic>) {
      return TreballadorEmpresaActualRef(
        id: _asIntOrNull(
          value['id'] ?? value['id_empresa'],
        ),
        nomEmpresa: _asString(
          value['nom_empresa'] ??
              value['nom'] ??
              value['display_name'],
        ),
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return TreballadorEmpresaActualRef.fromDynamic(map);
    }

    return TreballadorEmpresaActualRef(
      id: null,
      nomEmpresa: value.toString(),
    );
  }
}

String? _resolveFotoUrl(Map<String, dynamic> map) {
  final directa = _asString(
    map['foto'] ??
        map['foto_url'] ??
        map['imatge_perfil'],
  );

  if (directa != null) return directa;

  final config = _asMap(map['configuracio']);
  return _asString(
    config?['imatge_perfil'] ??
        config?['foto'] ??
        config?['foto_url'],
  );
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  return _asIntOrNull(value) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}