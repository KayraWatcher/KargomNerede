import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create a 512x512 image
  final image = Image(width: 512, height: 512);
  
  // Fill with dark navy background
  for (int y = 0; y < 512; y++) {
    for (int x = 0; x < 512; x++) {
      image.setPixel(x, y, ColorRgb8(0x0D, 0x1B, 0x2A));
    }
  }
  
  // Draw box - bottom
  for (int y = 220; y < 380; y++) {
    for (int x = 120; x < 392; x++) {
      image.setPixel(x, y, ColorRgb8(0x1E, 0x3A, 0x5F));
    }
  }
  
  // Box top flap (trapezoid)
  for (int y = 180; y < 220; y++) {
    double ratio = (220 - y) / 40.0;
    int left = 120 + (20 * (1 - ratio)).round();
    int right = 392 - (20 * (1 - ratio)).round();
    for (int x = left; x < right; x++) {
      image.setPixel(x, y, ColorRgb8(0x1E, 0x3A, 0x5F));
    }
  }
  
  // Draw location pin
  // Pin circle
  for (int y = 104; y < 176; y++) {
    for (int x = 220; x < 292; x++) {
      int dx = x - 256;
      int dy = y - 140;
      if (dx * dx + dy * dy <= 36 * 36) {
        double t = (y - 104) / 72.0;
        int r = (0x00 + (0x00 - 0x00) * t).round();
        int g = (0xB4 + (0x96 - 0xB4) * t).round();
        int b = (0xD8 + (0xC7 - 0xD8) * t).round();
        image.setPixel(x, y, ColorRgb8(r, g, b));
      }
    }
    
    // Pin hole
    for (int y = 126; y < 154; y++) {
      for (int x = 242; x < 270; x++) {
        int dx = x - 256;
        int dy = y - 140;
        if (dx * dx + dy * dy <= 14 * 14) {
          image.setPixel(x, y, ColorRgb8(0x0D, 0x1B, 0x2A));
        }
      }
    }
    
    // Pin stem
    for (int y = 176; y < 228; y++) {
      for (int x = 252; x < 260; x++) {
        double t = (y - 176) / 52.0;
        int r = (0x00 + (0x00 - 0x00) * t).round();
        int g = (0xB4 + (0x96 - 0xB4) * t).round();
        int b = (0xD8 + (0xC7 - 0xD8) * t).round();
        image.setPixel(x, y, ColorRgb8(r, g, b));
      }
    }
    
    // Pin tip
    for (int y = 228; y < 240; y++) {
      for (int x = 244; x < 268; x++) {
        int dx = x - 256;
        int dy = y - 234;
        if (dx * dx / 144 + dy * dy / 36 <= 1) {
          image.setPixel(x, y, ColorRgb8(0x0D, 0x1B, 0x2A));
        }
      }
    }
    
    // Subtle tracking lines
    for (int i = 0; i < 3; i++) {
      int y = 400 + i * 20;
      for (int x = 100 + i * 20; x < 412 - i * 20; x++) {
        double dx = x - 256;
        double dy = y - (350 + i * 30);
        double curve = 1.0 - (dx * dx) / (200 * 200);
        int py = (350 + i * 30 - (curve * 50)).round();
        if (y == py) {
          image.setPixel(x, y, ColorRgb8(0x00, 0xB4, 0xD8));
        }
      }
    }
    
    // Save
    final file = File('assets/icons/app_icon.png');
    file.writeAsBytesSync(encodePng(image));
    print('Icon created: ${file.path}');
  }
}