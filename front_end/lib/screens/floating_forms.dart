//AQUESTA CLASSE CONTÉ TOTS ELS WIDGETS DELS FORMULARIES FLOTANTS QUE S'UTILITZEN A L'APLICACIÓ
import 'package:flutter/material.dart';


class IncidenciaForm extends StatefulWidget {
  final int idObra;

  const IncidenciaForm({super.key, required this.idObra});

  @override
  State<IncidenciaForm> createState() => _IncidenciaFormState();
}

class _IncidenciaFormState extends State<IncidenciaForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcioController = TextEditingController();
  DateTime? _dataInici;
  DateTime? _dataFi;
  int? _criticitat;
  int? _prioritat;
  int? _categoria;
  String _estat = 'OBERTA';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final novaIncidencia = {
        'id_obra': widget.idObra,
        'descripcio': _descripcioController.text,
        'data_inici': _dataInici?.toIso8601String(),
        'data_fi': _dataFi?.toIso8601String(),
        'criticitat': _criticitat,
        'prioritat': _prioritat,
        'categoria': _categoria,
        'estat': _estat,
      };
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('Nova Incidència', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _descripcioController,
              decoration: const InputDecoration(labelText: 'Descripció'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obligatori' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Data inici (YYYY-MM-DD)'),
              onChanged: (v) => _dataInici = DateTime.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Data fi (opcional)'),
              onChanged: (v) => _dataFi = DateTime.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Criticitat (1-5)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _criticitat = int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Prioritat (1-5)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _prioritat = int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Categoria (ID o número)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _categoria = int.tryParse(v),
            ),
            DropdownButtonFormField<String>(
              value: _estat,
              decoration: const InputDecoration(labelText: 'Estat'),
              items: ['OBERTA', 'TANCADA', 'EN CURS']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _estat = v!),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Desar'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}



class TascaForm extends StatefulWidget {
  final int idObra;

  const TascaForm({super.key, required this.idObra});

  @override
  State<TascaForm> createState() => _TascaFormState();
}

class _TascaFormState extends State<TascaForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcioController = TextEditingController();
  DateTime? _dataInici;
  DateTime? _dataFi;
  int? _prioritat;
  bool _visibilitat = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final novaTasca = {
        'id_obra': widget.idObra,
        'descripcio': _descripcioController.text,
        'data_inici': _dataInici?.toIso8601String(),
        'data_fi': _dataFi?.toIso8601String(),
        'prioritat': _prioritat,
        'visibilitat_tasca': _visibilitat,
      };
      // Crida API
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('Nova Tasca', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _descripcioController,
              decoration: const InputDecoration(labelText: 'Descripció'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obligatori' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Data d\'inici (YYYY-MM-DD)'),
              onChanged: (v) => _dataInici = DateTime.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Data de fi (opcional)'),
              onChanged: (v) => _dataFi = DateTime.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Prioritat (0-5)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _prioritat = int.tryParse(v),
            ),
            SwitchListTile(
              title: const Text('Visible als treballadors'),
              value: _visibilitat,
              onChanged: (v) => setState(() => _visibilitat = v),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Desar'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}




class DocumentForm extends StatefulWidget {
  final int idObra;


  const DocumentForm({super.key, required this.idObra});

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _creadorController = TextEditingController();
  final _comentariController = TextEditingController();
  String _tipus = 'Pla';
  String _format = 'PDF';
  double? _mida;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nouDocument = {
        'id_obra': widget.idObra,
        'id_creador': _creadorController.text, // Ha de venir del context o d'un altre lloc
        'nom': _nomController.text,
        'format': _format,
        'mida': _mida,
        'comentari': _comentariController.text,
        'tipus': _tipus,
        'data_pujada': DateTime.now().toIso8601String(),
      };
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('Nou Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom del document'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obligatori' : null,
            ),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: ['PDF', 'DOCX', 'XLSX', 'ALTRES']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _format = v!),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Mida (MB)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _mida = double.tryParse(v),
            ),
            DropdownButtonFormField<String>(
              value: _tipus,
              decoration: const InputDecoration(labelText: 'Tipus de document'),
              items: ['Pla', 'Informe', 'Factura', 'Altres']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _tipus = v!),
            ),
            TextFormField(
              controller: _comentariController,
              decoration: const InputDecoration(labelText: 'Comentari (opcional)'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Desar'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}


class SolRecForm extends StatefulWidget {
  final int idObra;

  const SolRecForm({super.key, required this.idObra});

  @override
  State<SolRecForm> createState() => _SolRecFormState();
}

class _SolRecFormState extends State<SolRecForm> {
  final _formKey = GlobalKey<FormState>();
  int? _quantitat;
  DateTime? _dataNecessitat;
  DateTime? _dataEntrega;
  final _comentariController = TextEditingController();
  final _proveidorController = TextEditingController();

  int? _idRecursSeleccionat; // ← hauria de venir d’un dropdown amb la llista de recursos

  void _submit() {
    if (_formKey.currentState!.validate() && _idRecursSeleccionat != null) {
      final novaSol = {
        'id_obra': widget.idObra,
        'id_recurs': _idRecursSeleccionat,
        'quantitat': _quantitat,
        'data_necessitat': _dataNecessitat?.toIso8601String(),
        'data_entrada': _dataEntrega?.toIso8601String(),
        'comentari': _comentariController.text,
        'proveidor': _proveidorController.text,
        'data_creacio': DateTime.now().toIso8601String(),
      };
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('Nova Sol·licitud de Recurs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // ⚠️ Ex: A canviar per un dropdown amb dades reals
            DropdownButtonFormField<int>(
              value: _idRecursSeleccionat,
              decoration: const InputDecoration(labelText: 'Recurs'),
              items: [1, 2, 3].map((id) => DropdownMenuItem(value: id, child: Text('Recurs $id'))).toList(),
              onChanged: (v) => setState(() => _idRecursSeleccionat = v),
              validator: (v) => v == null ? 'Selecciona un recurs' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Quantitat'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _quantitat = int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Data necessitat (YYYY-MM-DD)'),
              onChanged: (v) => _dataNecessitat = DateTime.tryParse(v),
            ),
            TextFormField(
              controller: _comentariController,
              decoration: const InputDecoration(labelText: 'Comentari'),
            ),
            TextFormField(
              controller: _proveidorController,
              decoration: const InputDecoration(labelText: 'Proveïdor (opcional)'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Desar'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}



