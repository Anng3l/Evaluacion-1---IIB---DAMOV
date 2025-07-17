import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  
  String? _estadoSeleccionado;
  String? _tipoTarea;

  final List<Uint8List> fotosBytes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final uuid = const Uuid();

  Future<void> _pickImages(StateSetter setModalState) async {
    final picker = ImagePicker();

    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    if (origen == ImageSource.camera) {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (fotosBytes.length < 6) {
          setModalState(() {
            fotosBytes.add(bytes);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Máximo 6 imágenes permitidas.'),
              backgroundColor: Color(0xFF16243e), // Azul institucional
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (origen == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if ((pickedFiles.length + fotosBytes.length) <= 6) {
        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          setModalState(() {
            fotosBytes.add(bytes);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puedes subir entre 1 y 6 imágenes.'),
            backgroundColor: Color(0xFF16243e), // Azul institucional
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<String>> _subirImagenesASupabase() async {
    final storage = Supabase.instance.client.storage.from('evaluacion');
    final List<String> urls = [];

    for (var i = 0; i < fotosBytes.length; i++) {
      final String fileName = 'img_${uuid.v4()}.jpg';

      final String path = await storage.uploadBinary(
        fileName,
        fotosBytes[i],
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      if (path.isNotEmpty) {
        final publicUrl = storage.getPublicUrl(fileName);
        urls.add(publicUrl);
      } else {
        throw Exception(
          'Error al subir imagen: No se pudo obtener la ruta del archivo subido.',
        );
      }
    }

    return urls;
  }













  Future<void> _guardarTarea(BuildContext context) async {
    final campos = [
      nombreController.text,
      descripcionController.text
    ];

    final camposVacios = campos.any((campo) => campo.trim().isEmpty);

    if (camposVacios) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Por favor completa todos los campos obligatorios.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    if (camposVacios) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Por favor completa todos los campos obligatorios.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo institucional
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    if (fotosBytes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Faltan imágenes',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Debes agregar al menos una fotografía.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmado = await _confirmarGuardarLugar();
    if (!confirmado) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
        ),
      ),
    );

    try {
      final urls = await _subirImagenesASupabase();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('name, lastname')
          .eq('id', user.id)
          .single();

      final String autorNombre = '${data['name']} ${data['lastname']}';

      await FirebaseFirestore.instance.collection('evaluacion').add({
        'autor': autorNombre,
        'userID': user.id,
        'nombre': nombreController.text,
        'descripcion': descripcionController.text,
        'estado': _estadoSeleccionado,
        'tipo': _tipoTarea,
        'fotografias': urls,
        
        'fecha': Timestamp.now(),
      });

      Navigator.pop(context); // Cierra el spinner
      Navigator.pop(context); // Cierra el modal

      // Limpiar campos y fotos
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea guardada exitosamente.'),
          backgroundColor: Color(0xFF16243e), // Azul institucional
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cierra el spinner
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Ocurrió un error al guardar: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

















  

  void _clearForm() {
    nombreController.clear();
    descripcionController.clear();
    estadoController.clear();
    fotosBytes.clear();
  }




  Future<bool> _confirmarGuardarLugar() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '¿Estás seguro?',
              style: TextStyle(
                color: Color(0xFF16243e), // Azul institucional
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: const Text(
              '¿Deseas guardar este lugar turístico?',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ) ??
        false;
  }



































  void _confirmarEliminarLugar(String id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Estás seguro?',
          style: TextStyle(
            color: Color(0xFFE72F2B), // Rojo de alerta
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFE72F2B), // Rojo de alerta
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await FirebaseFirestore.instance.collection('evaluacion').doc(id).delete();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea eliminada exitosamente.'),
          backgroundColor: Color(0xFF16243e), // Azul institucional
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }




  void _editarTarea(String id, Map<String, dynamic> data) {
    final nombreCtrl = TextEditingController(text: data['nombre']);
    final descripcionCtrl = TextEditingController(text: data['descripcion']);
    final estadoCtrl = TextEditingController(text: data['estado']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Lugar',
          style: TextStyle(
            color: Color(0xFF16243e),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 500, // <-- Aquí defines el ancho deseado
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _styledField(nombreCtrl, 'Nombre de la tarea'),
                  const SizedBox(height: 10),
                  _styledField(descripcionCtrl, 'Descripción', maxLines: 2),
                  
                  
                  
                  
                  
                  
                  const SizedBox(height: 10),
                  Text("Estado de la tarea"),
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Seleccione una opción",
                        border: OutlineInputBorder()
                      ),
                      value: _estadoSeleccionado,
                      items: ["Hecho", "Pendiente"].map((String valor) {
                      return DropdownMenuItem<String>(
                        value: valor,
                        child: Text(valor),
                      );
                    }).toList(), 
                    onChanged: (String? newValue) {
                      setState(() {
                        _estadoSeleccionado = newValue;  
                      });
                    },
                      validator: (value) => value == null ? 'Este campo es requerido': null,
                  ),
                  
                  
                  
                  
                  const SizedBox(height: 10),
                  Text("Tipo de tarea"),
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Seleccione una opción",
                        border: OutlineInputBorder()
                      ),
                      value: _tipoTarea,
                      items: ["Publico", "Privado"].map((String valor) {
                      return DropdownMenuItem<String>(
                        value: valor,
                        child: Text(valor),
                      );
                    }).toList(), 
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoTarea = newValue;  
                      });
                    },
                      validator: (value) => value == null ? 'Este campo es requerido': null,
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFE72F2B), // Rojo de alerta
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.edit,
            ), // Ícono más representativo para editar
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16243e), // Azul institucional
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final campos = [
                nombreCtrl.text,
                descripcionCtrl.text,
                estadoCtrl.text
              ];

              final camposVacios = campos.any((campo) => campo.trim().isEmpty);

              if (camposVacios) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Campos incompletos',
                      style: TextStyle(
                        color: Color(0xFFE72F2B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'Por favor completa todos los campos.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(
                            color: Color(0xFF16243e),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return;
              }

              final confirmado = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    '¿Confirmar actualización?',
                    style: TextStyle(
                      color: Color(0xFF16243e), // Azul institucional
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  content: const Text(
                    '¿Estás seguro de actualizar esta tarea?',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFE72F2B), // Rojo de alerta
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sí, actualizar',
                        style: TextStyle(
                          color: Color(0xFF16243e), // Azul institucional
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmado != true) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFF8AD25),
                    ),
                  ),
                ),
              );

              try {
                await FirebaseFirestore.instance
                    .collection('evaluacion')
                    .doc(id)
                    .update({
                      'nombre': nombreCtrl.text,
                      'descripcion': descripcionCtrl.text,
                      'estado': estadoCtrl.text,
                    });

                Navigator.pop(context); // spinner
                Navigator.pop(context); // modal

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarea actualizada exitosamente.'),
                    backgroundColor: Color(0xFF16243e), // Azul institucional
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  





  Widget _styledField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
              : null,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFF98B7DF), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoText(String label, String value, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16, // más grande
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }































  void _mostrarFormularioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 30,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _styledField(nombreController, 'Titulo de la tarea'),
                    const SizedBox(height: 12),
                    _styledField(
                      descripcionController,
                      'Descripción',
                      maxLines: 2,
                    ),
                    
                    
                    const SizedBox(height: 12),
                    Text("Estado de la tarea"),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Seleccione una opción",
                        border: OutlineInputBorder()
                      ),
                      value: _estadoSeleccionado,
                      items: ["Hecho", "Pendiente"].map((String valor) {
                      return DropdownMenuItem<String>(
                        value: valor,
                        child: Text(valor),
                      );
                    }).toList(), 
                    onChanged: (String? newValue) {
                      setState(() {
                        _estadoSeleccionado = newValue;  
                      });
                    },
                      validator: (value) => value == null ? 'Este campo es requerido': null,
                    ),

                    
                    
                    
                    
                    
                    
                    const SizedBox(height: 10),
                    Text("Tipo de tarea"),  
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Seleccione una opción",
                        border: OutlineInputBorder()
                      ),
                      value: _tipoTarea,
                      items: ["Publico", "Privado"].map((String valor) {
                      return DropdownMenuItem<String>(
                        value: valor,
                        child: Text(valor),
                      );
                    }).toList(), 
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoTarea = newValue;  
                      });
                    },
                      validator: (value) => value == null ? 'Este campo es requerido': null,
                    ),



                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _pickImages(setModalState),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Seleccionar Fotografías'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8AD25),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: fotosBytes.map((bytes) {
                        return Image.memory(
                          bytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _guardarTarea(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Añadir Tarea'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16243e),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _clearForm(); // Limpia aunque el modal se cierre por fuera (por ejemplo deslizando)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 22, 36, 62),
        foregroundColor: Colors.white,
        title: const Text('Tareas compartidas'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tareas compartidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('evaluacion')
                    .where('tipo', isEqualTo: 'Publico')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFF8AD25),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text(
                      'Aún no hay lugares turísticos registrados.',
                    );
                  }

                  final user = Supabase.instance.client.auth.currentUser;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;

                      final nombre = data['nombre'] ?? '';
                      final descripcion = data['descripcion'] ?? '';
                      final autor = data['autor'] ?? 'Desconocido';
                      final userID =
                          data['userID']; // Asegúrate de guardar esto en Firestore
                      final fotos = List<String>.from(
                        data['fotografias'] ?? [],
                      );
                      final estado = data['estado'] ?? '';
                      Timestamp fecha = data['fecha'] ?? '';
                      DateTime dateTime = fecha.toDate();
                      String formattedDate = DateFormat('dd/MM/yyyy . hh:mm a').format(dateTime);

                      final esCreador = userID == user?.id;



                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE72F2B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descripcion,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              _infoText("Estado", estado),
                              
                              _infoText("Publicado por", autor, italic: true),
                              
                              _infoText("Fecha de publicación", formattedDate, italic: true),
                              const SizedBox(height: 12),

                              SizedBox(
                                height:
                                    (fotos.length / 3).ceil() *
                                    110, // 3 por fila, 100 alto + 10 spacing
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: fotos.map((url) {
                                    return GestureDetector(
                                      onTap: () =>(),
                                      child: 
                                      
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.red,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 8),
                              /*
                              if (esCreador && fotos.length < 6)
                                TextButton.icon(
                                  onPressed: () =>
                                      _agregarMasImagenes(docId, fotos.length),
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Agregar imagen'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF16243e),
                                  ),
                                ),
                              */
                              if (esCreador) const Divider(height: 24),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (esCreador)
                                    IconButton(
                                      onPressed: () =>
                                          _editarTarea(docId, data),
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar',
                                      color: Colors.white,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                              Color(0xFF16243e),
                                            ),
                                      ),
                                    ),
                                  if (esCreador)
                                    IconButton(
                                      onPressed: () =>
                                          _confirmarEliminarLugar(docId),
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Eliminar',
                                      color: Colors.white,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                              Color(0xFFE72F2B),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16243e),
        foregroundColor: Colors.white, // Ícono blanco
        tooltip: 'Añadir tarea',
        onPressed: () => _mostrarFormularioModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
    );
  }
}
