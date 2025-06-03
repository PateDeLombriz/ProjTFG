from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Obra
from .serializer import ObraSerializer

class ObraList(APIView):
    def get(self, request, format=None):
        obres = Obra.objects.all()  # obtenim totes les obres
        serializer = ObraSerializer(obres, many=True)
        return Response(serializer.data)  # retornem la llista serialitzada
