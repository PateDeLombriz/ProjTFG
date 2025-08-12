"""
DEBUG DB ENVIRONMENT:
ENGINE: django.db.backends.postgresql
NAME: obraAgil
USER: dbuser
PASSWORD: dbpassword
HOST: db
PORT: 5432
"""
# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.utils import timezone

class Obra(models.Model):
    id = models.AutoField(db_column='id', primary_key=True)  # Field name made lowercase.
    nom = models.CharField(db_column='nom', max_length=100)  # Field name made lowercase.
    ubicacio = models.CharField(db_column='ubicacio', max_length=200, blank=True, null=True)  # Field name made lowercase.
    data_inici = models.DateField(db_column='data_inici')  # Field name made lowercase.
    data_prev_fi = models.DateField(db_column='data_prev_fi', blank=True, null=True)  # Field name made lowercase.
    pressupost = models.DecimalField(db_column='pressupost', max_digits=12, decimal_places=2, blank=True, null=True)  # Field name made lowercase.
    descripcio = models.TextField(db_column='descripcio', blank=True, null=True)  # Field name made lowercase.
    estat = models.CharField(db_column='estat', max_length=50)  # Field name made lowercase.

    class Meta:
        #Indica que Django gestionarà/no gestionarà la creación, modificación o eliminación de aquesta taula.
        # si makemigration i migrate tambe deixen de funcionar
        managed = False  
        db_table = 'obra'

class Ubicacio(models.Model):
    adreça = models.CharField(max_length=150, blank=True, null=True)
    ciutat = models.CharField(max_length=50, blank=True, null=True)
    codi_postal = models.CharField(max_length=10, blank=True, null=True)
    provincia = models.CharField(max_length=50, blank=True, null=True)
    país = models.CharField(max_length=50, default='Espanya')

    def __str__(self):
        parts = filter(None, [self.adreça, self.ciutat, self.provincia])
        return ', '.join(parts)
    
    class Meta:
        managed = False
        db_table = 'ubicacio'


class Empresa(models.Model):

    ESTAT_EMPRESA = [
        ('activa', 'Activa'),
        ('inactiva', 'Inactiva'),
        ('suspesa', 'Suspesa'),
    ]

    nom_empresa = models.CharField(max_length=100)
    cif = models.CharField(max_length=20, unique=True)
    ubicacio = models.ForeignKey(Ubicacio, on_delete=models.SET_NULL, null=True, blank=True)
    telefon = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(max_length=100, blank=True, null=True)
    web = models.URLField(max_length=100, blank=True, null=True)
    sector = models.CharField(max_length=50, blank=True, null=True)
    data_alta = models.DateField(auto_now_add=True)
    estat = models.CharField(max_length=20, choices=ESTAT_EMPRESA, default='activa')
    persona_contacte = models.CharField(max_length=100, blank=True, null=True)
    comentaris = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.nom_empresa
    
    class Meta:
        managed = False
        db_table = 'empresa'

class Treballador(models.Model):
    nom = models.CharField(max_length=50)
    cognoms = models.CharField(max_length=100)
    dni_nie_passaport = models.CharField(max_length=20, unique=True)
    data_naixement = models.DateField(blank=True, null=True)
    ubicacio = models.ForeignKey(Ubicacio, on_delete=models.SET_NULL, null=True, blank=True)
    telefon = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(max_length=100, blank=True, null=True)
    foto = models.ImageField(upload_to='fotos_treballadors/', blank=True, null=True)
    comentaris = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.nom} {self.cognoms}"
    
    class Meta:
        managed  = False          # 🔸 Django no l’ha de crear
        db_table = 'treballador'  # 🔸 nom real a PostgreSQL
    
class ContracteTreballador(models.Model):
    TIPUS_CONTRACTE_CHOICES = [
        ('indefinit', 'Indefinit'),
        ('temporal', 'Temporal'),
        ('subcontracta', 'Subcontracta'),
    ]

    ESTAT_TREBALLADOR_CHOICES = [
        ('actiu', 'Actiu'),
        ('baixa', 'Baixa'),
        ('acomiadat', 'Acomiadat'), ]

    id_treballador = models.ForeignKey(Treballador, on_delete=models.CASCADE, null=False)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, blank=False, null=False)
    salari = models.DecimalField(max_digits=10, decimal_places=2, blank=False, null=True)
    data_contracte = models.DateField(blank=True, null=True)
    data_fi = models.DateField(blank=True, null=True)
    tipus_contracte = models.CharField(max_length=20, choices=TIPUS_CONTRACTE_CHOICES, default='temporal')
    carrec = models.CharField(max_length=50, blank=True, null=True)
    categoria_professional = models.CharField(max_length=50, blank=True, null=True)
    nss = models.CharField(max_length=20, blank=True, null=True)
    formacions = models.TextField(blank=True, null=True)
    empresa = models.ForeignKey(Empresa, on_delete=models.SET_NULL, null=True, related_name='treballadors')
    estat = models.CharField(max_length=20, choices=ESTAT_TREBALLADOR_CHOICES, default='actiu')

    class Meta:
        unique_together = ('id_treballador', 'data_contracte')

           
class  Configuracio(models.Model):
    id = models.AutoField(primary_key=True)  # ← Cal afegir aquest!
    id_empresa = models.ForeignKey('Empresa', models.DO_NOTHING, db_column='id_empresa')
    id_treballador = models.ForeignKey('Treballador', models.DO_NOTHING, db_column='id_treballador')

    idioma = models.CharField(max_length=10, blank=True, null=True)
    acceptacio_terms = models.BooleanField()
    imatge_perfil = models.CharField(max_length=255, blank=True, null=True)
    
    class Meta:
        managed = False
        db_table = 'configuracio'


class Contrasenya(models.Model):
    
    id = models.AutoField(primary_key=True)  # ← Cal afegir aquest!
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='treballador_id')
    id_empresa = models.ForeignKey(Empresa, models.DO_NOTHING, db_column='empresa_id', blank=True, null=True)
    clau = models.CharField(max_length=255)
    data_creacio = models.DateTimeField()
    data_reemplas = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'contrasenya'

'''
class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.SmallIntegerField()
    change_message = models.TextField()
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoContentType(models.Model):
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    id = models.BigAutoField(primary_key=True)
    app = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    applied = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.CharField(primary_key=True, max_length=40)
    session_data = models.TextField()
    expire_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_session'
'''

class DocumentObra(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, related_name= 'documents', db_column='id_obra')
    nom_creador = models.CharField(max_length=120, blank=True, null=True)  # Creator's name, optional
    nom = models.CharField(max_length=160)
    format = models.CharField(max_length=40)
    mida = models.DecimalField(max_digits=6, decimal_places=2)  # Assuming size in MB
    comentari = models.TextField(blank=True, null=True)
    data_pujada = models.DateTimeField()
    tipus = models.CharField(max_length=40)

    class Meta:
        managed = False
        db_table = 'document_obra'





class LogDeSessio(models.Model):
    id_log = models.AutoField(primary_key=True) 
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='id')
    data_inici = models.DateField()
    hora_inici = models.TimeField()

    class Meta:
        managed = False
        db_table = 'log_de_sessio'

class Permis(models.Model):
    id = models.AutoField(primary_key=True) 

    clau_funcional = models.CharField(unique=True, max_length=100)
    descripcio = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'permis'


class PermisTreballador(models.Model):
    id = models.AutoField(primary_key=True) 
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='id_usuari')
    id_permis = models.ForeignKey(Permis, models.DO_NOTHING, db_column='id_permis')
    lectura = models.BooleanField()
    escriptura = models.BooleanField()
    edicio = models.BooleanField()
    data_creacio = models.DateTimeField()
    data_modif = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'permis_treballador'


class Recurs(models.Model):
    id = models.AutoField(primary_key=True) 
    nom = models.CharField(max_length=120)
    unitats_mesura = models.CharField(max_length=40)
    quantitat_stock = models.DecimalField(max_digits=8, decimal_places=2)
    tipus_recurs = models.CharField(max_length=60)

    class Meta:
        managed = False
        db_table = 'recurs'


class ResponsableObra(models.Model):
    
    id_obra = models.OneToOneField(Obra, models.DO_NOTHING, db_column='id_obra', primary_key=True)  # The composite primary key (id_obra, id_treballador, data_inici) found, that is not supported. The first column is selected.
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='id_treballador')
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'responsable_obra'
        unique_together = (('id_obra', 'id_treballador', 'data_inici'),)


class SolRecurs(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, db_column='id_obra')
    id_recurs = models.ForeignKey(Recurs, models.DO_NOTHING, db_column='id_recurs')
    quantitat = models.IntegerField()
    data_necessitat = models.DateField()
    comentari = models.TextField(blank=True, null=True)
    data_entrega = models.DateField(blank=True, null=True)
    data_creacio = models.DateTimeField()
    proveidor = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'sol_recurs'




class Tasca(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING,related_name='tasques', db_column='id_obra')
    id_tasca_pare = models.ForeignKey('self', models.DO_NOTHING, db_column='id_tasca_pare', blank=True, null=True)
    descripcio = models.TextField()
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)
    prioritat = models.IntegerField()
    visibilitat_tasca = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'tasca'

class Incidencia(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, related_name='incidencies', db_column='id_obra')
    id_tasca = models.ForeignKey(Tasca, models.DO_NOTHING, db_column='id_tasca', blank=True, null=True)
    descripcio = models.TextField()
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)
    criticitat = models.IntegerField()
    prioritat = models.IntegerField()
    categoria = models.IntegerField() #canviar categoria a CharField si es volen categories textuals
    estat = models.CharField(max_length=40)

    class Meta:
        managed = False
        db_table = 'incidencia'

class Solucio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_incidencia = models.ForeignKey(Incidencia, models.DO_NOTHING, db_column='id_incidencia')
    id_tasca = models.ForeignKey(Tasca, models.DO_NOTHING, db_column='id_tasca', blank=True, null=True)
    descripcio = models.TextField()
    cost_monetari = models.BigIntegerField()
    eficacia = models.IntegerField()
    cost_temporal = models.IntegerField()
    impacte = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'solucio'


class TascaTreballador(models.Model):
    id = models.AutoField(primary_key=True)          # surrogate
    id_tasca = models.ForeignKey(
        Tasca, models.DO_NOTHING, db_column='id_tasca'
    )
    id_treballador = models.ForeignKey(
        Treballador, models.DO_NOTHING, db_column='id_treballador'
    )
    comentari = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'tasca_treballador'
        managed = False                        # perquè la taula ja existeix
        unique_together = (('id_tasca', 'id_treballador'),)

 

class Verificacio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_usuari = models.ForeignKey(Empresa, models.DO_NOTHING, db_column='id_usuari')
    estat_ver = models.CharField(max_length=40)
    data_ver = models.DateField(blank=True, null=True)
    token_verificacio = models.CharField(max_length=120)
    data_token = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'verificacio'


'''

class AuthGroup(models.Model):
    name = models.CharField(unique=True, max_length=150)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)
    permission = models.ForeignKey('AuthPermission', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group', 'permission'),)


class AuthPermission(models.Model):
    name = models.CharField(max_length=255)
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING)
    codename = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type', 'codename'),)


class AuthUser(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    email = models.CharField(max_length=254)
    is_staff = models.BooleanField()
    is_active = models.BooleanField()
    date_joined = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'auth_user'


class AuthUserGroups(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_groups'
        unique_together = (('user', 'group'),)


class AuthUserUserPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    permission = models.ForeignKey(AuthPermission, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_user_permissions'
        unique_together = (('user', 'permission'),)
'''