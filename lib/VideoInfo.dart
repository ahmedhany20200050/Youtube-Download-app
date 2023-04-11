import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfo{
  late Video _video;

  Video get video => _video;

  set video(Video value) {
    _video = value;
  }
  String _format=".mp4";

  String get format => _format;

  set format(String value) {
    _format = value;
  }
  late int _id;

  int get id => _id;

  set id(int value) {
    _id = value;
  }
  late double _size;

  double get size => _size;

  set size(double value) {
    _size = value;
  }
}