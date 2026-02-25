from rest_framework import serializers
from .models import (Obra, Treballador, Empresa, Contrasenya,
 Permis, PermisTreballador, LogDeSessio, Configuracio, Verificacio,
    DocumentObra, Tasca, TascaTreballador, Incidencia, Solucio,
    Recurs, SolRecurs, ResponsableObra,   
    ResponsableObra,ContracteTreballador
)
#Aquesta classee ara com ara tan sols prepara l'informacio per ser
# resnderitzada a json, pot ser canvii.

class ObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Obra
        fields = '__all__'  # Serializes all fields of the Obra model
'''
class UsuariSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuari
        fields = '__all__'

class UPersonaSerializer(serializers.ModelSerializer):
    class Meta:
        model = UPersona
        fields = '__all__'

class UEmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = UEmpresa
        fields = '__all__'
'''

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = '__all__'

class TreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Treballador
        fields = '__all__'
class ContrasenyaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contrasenya
        fields = '__all__'

class UbicacioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Treballador
        fields = '__all__'

class PermisSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permis
        fields = '__all__'

class PermisTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = PermisTreballador
        fields = '__all__'

class LogDeSessioSerializer(serializers.ModelSerializer):
    class Meta:
        model = LogDeSessio
        fields = '__all__'

class ConfiguracioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Configuracio
        fields = '__all__'

class VerificacioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Verificacio
        fields = '__all__'

class DocumentObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = DocumentObra
        fields = '__all__'

class ContracteTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContracteTreballador
        fields = '__all__'  # Assuming you want to serialize all fields of the Contracte model      

class TascaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tasca
        fields = '__all__'

class TascaTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = TascaTreballador
        fields = '__all__'

class IncidenciaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Incidencia
        fields = '__all__'

class SolucioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Solucio
        fields = '__all__'

class RecursSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recurs
        fields = '__all__'

class SolRecursSerializer(serializers.ModelSerializer):
    class Meta:
        model = SolRecurs
        fields = '__all__'

class ResponsableObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = ResponsableObra
        fields = '__all__'

        
