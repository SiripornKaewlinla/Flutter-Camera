import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Camera & Gallery App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // ฟังก์ชันสำหรับเปลี่ยนหน้า
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CameraPage(), // หน้า Camera
      GalleryPage(), // หน้า Gallery
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Camera ')),
      body: pages[_selectedIndex], // เลือกหน้าแสดงตาม index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: ' Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: ' Gallery',
          ),
        ],
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  bool isFrontCamera = true;

  Future<void> _requestPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
  }

  void _toggleCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  Future<void> _takePhoto() async {
    await _requestPermission();

    // เลือกแหล่งที่มาของกล้องที่ถูกต้อง
    final camera = isFrontCamera ? ImageSource.camera : ImageSource.camera;

    final XFile? image = await _picker.pickImage(
      source: camera,
      preferredCameraDevice: isFrontCamera
          ? CameraDevice.front
          : CameraDevice.rear, // แก้ไขตรงนี้เพื่อใช้กล้องหน้าและกล้องหลัง
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image != null
              ? Image.file(_image!)
              : const Text('ยังไม่ได้ถ่ายรูป'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _takePhoto,
            child: Text(isFrontCamera
                ? 'ถ่ายรูปด้วยกล้องหน้า'
                : 'ถ่ายรูปด้วยกล้องหลัง'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleCamera,
            child: const Text('🔄 สลับกล้อง'),
          ),
        ],
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<File> _galleryImages = [];

  Future<void> _loadImagesFromGallery() async {
    final List<XFile>? images = await ImagePicker().pickMultiImage();
    if (images != null) {
      setState(() {
        _galleryImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImagesFromGallery();
  }

  void _viewFullScreenImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _galleryImages.isNotEmpty
              ? GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _galleryImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _viewFullScreenImage(_galleryImages[index]),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              color: Colors.white,
                              height: 5,
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                color: Colors.white,
                                child: Image.file(
                                  _galleryImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.white,
                              height: 40,
                              child: const Center(
                                child: Text(
                                  'Polaroid',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const Center(child: Text('ไม่มีรูปภาพ')),
        ),
      ],
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final File image;

  const FullScreenImagePage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ดูรูปภาพ', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.file(
            image,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
