import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController urlTextController = TextEditingController();
  String videoTitle = '';
  String videoPublishDate = "";
  String videoID = "";
  bool downloading=false;
  bool submitted=false;
  double? progress=0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: urlTextController,
                onChanged: (text) {
                  getVideoInfo(text);
                },
                decoration: const InputDecoration(
                  label: Text("Paste Youtube URL here"),
                ),
              ),
            ),
            Text(videoTitle),
            Text(videoPublishDate),
            submitted?Image.network(
              "https://img.youtube.com/vi/$videoID/0.jpg",
              height: 250,
            ):Container(),
            // TextButton.icon(
            //   onPressed: () async {
            //     await createFolderInAppDocDir();
            //     await OpenFile.open("/storage/emulated/0/youtube test download/");
            //   },
            //   icon: const Icon(Icons.folder),
            //   label: const Text("open download Folder"),
            // ),
            urlTextController.text.isNotEmpty?TextButton.icon(
              onPressed: () {
                downloadVideo(urlTextController.text);
              },
              icon: const Icon(Icons.download),
              label: const Text("download video"),
            ):Container(),
            downloading ?  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blueAccent,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> getVideoInfo(url) async {
    var youtubeInfo = YoutubeExplode();
    Video video = await youtubeInfo.videos.get(url);

    setState(() {
      submitted=true;
      videoTitle = video.title;
      videoPublishDate = video.uploadDate.toString();
      videoID = video.id.toString();
      if (kDebugMode) {
        print(videoTitle);
      }
    });
  }
  Future<String> createFolderInAppDocDir() async {
    //Get this App Document Directory

    // final Directory? _appDocDir = await getExternalStorageDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
    Directory('/storage/emulated/0/youtube test download/');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
      await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }





  Future<void> downloadVideo(id) async {
    String path= await createFolderInAppDocDir();

    var permisson = await Permission.storage.request();
    if (permisson.isGranted) {
      //download video
      if (urlTextController.text != '') {
        setState(() => downloading = true);

        //download video
        setState(() => progress = 0);
        var youtubeExplode = YoutubeExplode();
        //get video metadata
        var video = await youtubeExplode.videos.get(id);
        var manifest = await youtubeExplode.videos.streamsClient.getManifest(id);
        var audio = manifest.muxed.withHighestBitrate();
        var audioStream = youtubeExplode.videos.streamsClient.get(audio);
        //create a directory
        Directory? appDocDir = await getExternalStorageDirectory();
        String? appDocPath = appDocDir?.path;
        var file = File('$path${video.title}.mp4');
        //delete file if exists
        if (file.existsSync()) {
          file.deleteSync();
        }
        var output = file.openWrite(mode: FileMode.writeOnlyAppend);
        var size = audio.size.totalBytes;
        var count = 0;

        await for (final data in audioStream) {
          // Keep track of the current downloaded data.
          count += data.length;
          // Calculate the current progress.
          double val = ((count / size));
          var msg = ' Downloaded to\n $path${video.title}.mp4';
          for (val; val == 1.0; val++) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
          setState(() => progress = val);

          // Write to file.
          output.add(data);
        }
        ImageGallerySaver.saveFile("$path${video.title}.mp4",isReturnPathOfIOS: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('add youtube video url first!')));
        setState(() => downloading = false);
      }
    } else {
      await Permission.storage.request();
    }
  }
}
