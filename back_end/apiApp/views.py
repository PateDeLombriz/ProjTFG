from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Obra
from .serializer import ObraSerializer

from rest_framework import status

class ObraList(APIView):
    def get(self, request, format=None):
        obres = Obra.objects.all()
        serializer = ObraSerializer(obres, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
        serializer = ObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
