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

class UsuariTipus(models.TextChoices):
    TREBALLADOR = 'TREBALLADOR', 'Treballador'
    EMPRESA = 'EMPRESA', 'Empresa'
#Daptar aquests 
class Usuari(models.Model):
    id = models.AutoField(primary_key=True)  # explícit, però no necessari
    tipus = models.CharField(max_length=20, choices=UsuariTipus.choices)
    telefon = models.BigIntegerField(null=True, blank=True)
    data_creacio = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'usuari'



class UPersona(models.Model):
    usuari = models.OneToOneField(Usuari, on_delete=models.CASCADE, primary_key=True,db_column='id')
    nickname = models.CharField(max_length=60, unique=True)
    nom = models.CharField(max_length=120)
    cognoms = models.CharField(max_length=160)
    rol = models.CharField(max_length=60)
    estat = models.CharField(max_length=40)
    
    class Meta:
        managed = True
        db_table = 'u_persona'


class UEmpresa(models.Model):
    usuari = models.OneToOneField(Usuari, on_delete=models.CASCADE, primary_key=True,db_column='id')
    nom = models.CharField(max_length=120)
    correu = models.CharField(max_length=160)

    class Meta:
        managed = False
        db_table = 'u_empresa'


class Configuracio(models.Model):
    id_usuari = models.OneToOneField('Usuari', models.DO_NOTHING, db_column='id_usuari', primary_key=True)
    idioma = models.CharField(max_length=10, blank=True, null=True)
    acceptacio_terms = models.BooleanField()
    imatge_perfil = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'configuracio'


class Contrasenya(models.Model):
    
    id = models.AutoField(primary_key=True)  # ← Cal afegir aquest!
    id_usuari = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_usuari')
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
    id_obra = models.ForeignKey('Obra', models.DO_NOTHING, related_name= 'documents', db_column='id_obra')
    id_creador = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_creador')
    nom = models.CharField(max_length=160)
    format = models.CharField(max_length=40)
    mida = models.DecimalField(max_digits=6, decimal_places=2)  # Assuming size in MB
    comentari = models.TextField(blank=True, null=True)
    data_pujada = models.DateTimeField()
    tipus = models.CharField(max_length=40)

    class Meta:
        managed = False
        db_table = 'document_obra'


class Incidencia(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey('Obra', models.DO_NOTHING, related_name='incidencies', db_column='id_obra')
    id_tasca = models.ForeignKey('Tasca', models.DO_NOTHING, db_column='id_tasca', blank=True, null=True)
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


class LogDeSessio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_usuari = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_usuari')
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


class PermisUsuari(models.Model):
    id = models.AutoField(primary_key=True) 
    id_usuari = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_usuari')
    id_permis = models.ForeignKey(Permis, models.DO_NOTHING, db_column='id_permis')
    lectura = models.BooleanField()
    escriptura = models.BooleanField()
    edicio = models.BooleanField()
    data_creacio = models.DateTimeField()
    data_modif = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'permis_usuari'


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
    id_treballador = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_treballador')
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


class Solucio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_incidencia = models.ForeignKey(Incidencia, models.DO_NOTHING, db_column='id_incidencia')
    id_tasca = models.ForeignKey('Tasca', models.DO_NOTHING, db_column='id_tasca', blank=True, null=True)
    descripcio = models.TextField()
    cost_monetari = models.BigIntegerField()
    eficacia = models.IntegerField()
    cost_temporal = models.IntegerField()
    impacte = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'solucio'


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


class TascaTreballador(models.Model):
    id_tasca = models.OneToOneField(Tasca, models.DO_NOTHING, db_column='id_tasca', primary_key=True)  # The composite primary key (id_tasca, id_treballador) found, that is not supported. The first column is selected.
    id_treballador = models.ForeignKey('Usuari', models.DO_NOTHING, db_column='id_treballador')
    comentari = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'tasca_treballador'
        unique_together = (('id_tasca', 'id_treballador'),)



class Verificacio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_usuari = models.ForeignKey(UEmpresa, models.DO_NOTHING, db_column='id_usuari')
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