from rest_framework import serializers
from .models import Obra

#Aquesta classee ara com ara tan sols prepara l'informacio per ser
# resnderitzada a json, pot ser canvii.

class ObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Obra
        fields = '__all__'  # Serializes all fields of the Obra model
