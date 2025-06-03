from django.db import models
import django.utils.timezone as timezone

# Create your models here.
# Aqui es on es definexen els models de la base de dades, es a dir, les taules i les seves columnes.
#Aquestes es creen quan s'executa la comanda: python manage.py makemigrations i python manage.py migrate

class Obra(models.Model):
    # Identificador único de la obra (clave primaria)
    Id = models.AutoField(primary_key=True)

# Nombre de la obra
    Nom = models.CharField(max_length=100)

# Ubicación donde se realiza la obra
    Ubicacio = models.CharField(max_length=200,null=True)

# Fecha de inicio de la obra
    Data_inici = models.DateField(default=timezone.now)

    # Fecha prevista de finalización de la obra
    Data_prev_fi = models.DateField(null=True)

    # Presupuesto asignado a la obra
    Pressupost = models.DecimalField(max_digits=12, decimal_places=2,null=True)

    # Descripción detallada de la obra
    Descripcio = models.TextField(null=True, blank=True)

    # Estado actual de la obra (por ejemplo: 'En ejecución', 'Finalizada', etc.)
    Estat = models.CharField(default='Res Firmat',max_length=50)

    #Identitat del teu model
    class Meta:
        verbose_name = "Obra"
        verbose_name_plural = "Obres"
        ordering = ['Nom']

    def __str__(self):
        return self.Nom
