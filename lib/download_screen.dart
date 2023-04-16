import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_test/VideoInfo.dart';
import 'package:youtube_test/list_item.dart';
import 'package:flutter/services.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  static const platform =MethodChannel("com.flutter.epic/mp3");
  List<VideoInfo> videosInfo=[];
  List<ListItem> listItems=[];
  final TextEditingController urlTextController = TextEditingController();
  double? progress = 0.0;
  bool stop=false;
  String currentlyDownloading="";

  String format = ".mp4";
  String currentButtonFormat=".mp4";



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex:2,
                  child: Padding(
                    padding: const EdgeInsets.only(right:8.0),
                    child: TextFormField(
                      controller: urlTextController,
                      decoration:  const InputDecoration(
                        label: Text("Paste Youtube URL here"),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    value: currentButtonFormat,
                    items: <String>['.mp4', '.mp3'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newFormat) {
                      setState(() {
                        if (kDebugMode) {
                          print("my new format $newFormat");
                        }
                        currentButtonFormat=newFormat!;
                      });

                    },
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Container(
                    decoration:  BoxDecoration(
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: TextButton(
                      onPressed: () {
                        getInfo(urlTextController.text);
                      },
                      child: const Text("Add",style: TextStyle(color: Colors.blueAccent),),
                    ),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const ScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: listItems,
              ),
            ),
          ),


          Expanded(
            flex: 1,
            child: videosInfo.isNotEmpty ? TextButton.icon(
                    onPressed: () {
                      downloadVideos();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("download All"),
                  )
                : Container(),
          ),
          Expanded(
            flex: 1,
            child:  Text("$currentlyDownloading \nprogress: ${(progress! >= 1) ? "100.0" : (progress! * 100).toStringAsFixed(2)}%"),
          ),
          Expanded(
            flex: 1,
            child:  TextButton.icon(
              onPressed: () {
                openDownloadFolder();
              },
              icon: const Icon(Icons.download),
              label: const Text("Open Download Folder"),
            ),
          ),
        ],
      ),
    );
  }

  /*
  1- info
  2- create directory
  3- make list
  4- download
   */

  //1-info
  Future<void> getInfo(String url) async {
    String currentFormat=currentButtonFormat;
    if (url.contains("list")) {
      var yt = YoutubeExplode();
      // Get playlist metadata.
      var playlist = await yt.playlists.get(url);
      var vv=yt.playlists.getVideos(playlist.id);
      await for (Video v in vv) {
        var aa=VideoInfo();
        aa.video=v;
        aa.format=currentFormat;
        var rr=await yt.videos.streamsClient.getManifest(v.id);
        aa.size=rr.muxed.withHighestBitrate().size.totalMegaBytes;
        if(aa.format==".mp3"){
          aa.size=rr.audioOnly.withHighestBitrate().size.totalMegaBytes;
        }
        //give it a special id (to be needed )
        for(int i=0;i<10000;i++){
          bool ok=true;
          for(var information in videosInfo){
            if(information.id==i){
              ok=false;
              break;
            }
          }
          if(ok){
            aa.id=i;
            break;
          }
        }
        setState(() {

          videosInfo.add(aa);
          createListOfVideos("playlist nigga");
        });
      }
      return;
    }else{
      var youtubeInfo = YoutubeExplode();
      Video video = await youtubeInfo.videos.get(url);
      var aa=VideoInfo();
      aa.video=video;
      aa.format=currentFormat;
      var rr=await youtubeInfo.videos.streamsClient.getManifest(video.id);
      aa.size=rr.muxed.withHighestBitrate().size.totalMegaBytes;
      if(aa.format==".mp3"){
        aa.size=rr.audioOnly.withHighestBitrate().size.totalMegaBytes;
      }
      //give it a special id
      for(int i=0;i<10000;i++){
        bool ok=true;
        for(var information in videosInfo){
          if(information.id==i){
            ok=false;
            break;
          }
        }
        if(ok){
          aa.id=i;
          break;
        }
      }
      setState(() {

        videosInfo.add(aa);
        if (kDebugMode) {
          print(aa.video.title);
        }
        createListOfVideos("video nigga");

      });
    }


  }

  //2- folder
  Future<String> createFolderInAppDocDir() async {
    //Get this App Document Directory
    //App Document Directory + folder name
    final Directory? appDocDirFolder =
        await getExternalStorageDirectory();

    return appDocDirFolder!.path;
  }

  //3- add to list
  void createListOfVideos(String whoAmI) async{
    setState(() {
      listItems.clear();
    });
    List<ListItem> list=[];
    var yt =YoutubeExplode().videos.streamsClient;
    for(var info in videosInfo){
      var item=ListItem(info,(){videosInfo.removeWhere((element) => element.id==info.id);createListOfVideos("item number ${info.id} nigga");return;},info.id,info.size);
      if(stop){
        break;
      }
      list.add(item);
    }
    setState(() {
      listItems= list;
    });

  }





  //4- download
  Future<void> downloadVideos() async {
    setState(() {
      progress = 0;
    });

    var permisson = await Permission.storage.request();
    while(permisson.isDenied){
      permisson = await Permission.storage.request();
    }

    if (permisson.isGranted) {
      String path = await createFolderInAppDocDir();
      while(videosInfo.isNotEmpty){
        setState(() => progress = 0);
        var youtubeExplode = YoutubeExplode();
        //get video metadata
        var video = await youtubeExplode.videos.get(videosInfo.first.video.id);
        String newformat=videosInfo.first.format;
        // String format=videosInfo.first.format;
        if(videosInfo.first.format==".mp3"){
          setState(() {
            videosInfo.removeAt(0);
            currentlyDownloading=video.title;
            createListOfVideos("download function");
          });
          if (kDebugMode) {
            print(video.title);
          }
          var manifest = await youtubeExplode.videos.streamsClient.getManifest(video.id);
          var audio = manifest.audioOnly.withHighestBitrate();
          var audioStream = youtubeExplode.videos.streamsClient.get(audio);

          //time to create file
          File file;
          int copyNumber=0;
          String fileNameAndDirectory;
          while(true){
            fileNameAndDirectory='$path/${video.title}${copyNumber==0?"":copyNumber}$newformat';
            file= File(fileNameAndDirectory);
            copyNumber++;
            //delete file if exists
            if (file.existsSync()) {
              continue;
            }
            break;
          }
          if (kDebugMode) {
            print(file.path);
          }

          await file.create(recursive: true);
          var output = file.openWrite(mode: FileMode.writeOnlyAppend);
          var size = audio.size.totalBytes;
          var count = 0;
          await for (final data in audioStream) {
            // Keep track of the current downloaded data.
            count += data.length;
            // Calculate the current progress.
            double val=0;
            val=((count/size));
            var msg = ' Downloaded to\n $fileNameAndDirectory';
            for (val; val == 1.0; val++) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }
            setState(() => progress = val);
            // Write to file.
            output.add(data);


          }
          if (kDebugMode) {
            print("the end \n hold down your breath and couuuuuuuuunnnnnnt to ten \n feel the earth mooooove and then \n here my heart buuuuuurns \n agaaaaaaaain \n for this is the end");
          }
          output.close();
          youtubeExplode.close();
        }else{
          String newformat=videosInfo.first.format;
          setState(() {
            videosInfo.removeAt(0);
            currentlyDownloading=video.title;
            createListOfVideos("download function");
          });
          if (kDebugMode) {
            print(video.title);
          }
          var manifest = await youtubeExplode.videos.streamsClient.getManifest(video.id);
          var audio = manifest.muxed.withHighestBitrate();
          var audioStream = youtubeExplode.videos.streamsClient.get(audio);

          //time to create file
          File file;
          int copyNumber=0;
          String fileNameAndDirectory;
          while(true){
            fileNameAndDirectory='$path/${video.title}${copyNumber==0?"":copyNumber}$newformat';
            file= File(fileNameAndDirectory);
            copyNumber++;
            //delete file if exists
            if (file.existsSync()) {
              continue;
            }
            break;
          }
          if (kDebugMode) {
            print(file.path);
          }

          await file.create(recursive: true);
          var output = file.openWrite(mode: FileMode.writeOnlyAppend);
          var size = audio.size.totalBytes;
          var count = 0;
          await for (final data in audioStream) {
            // Keep track of the current downloaded data.
            count += data.length;
            // Calculate the current progress.
            double val=0;
            val=((count/size));
            var msg = ' Downloaded to\n $fileNameAndDirectory';
            for (val; val == 1.0; val++) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }
            setState(() => progress = val);
            // Write to file.
            output.add(data);


          }
          if (kDebugMode) {
            print("the end \n hold down your breath and couuuuuuuuunnnnnnt to ten \n feel the earth mooooove and then \n here my heart buuuuuurns \n agaaaaaaaain \n for this is the end");
          }
          //todo: download video as mp3 and save mp3
          await ImageGallerySaver.saveFile(fileNameAndDirectory, isReturnPathOfIOS: false);
          // output.flush();

          output.close();
          youtubeExplode.close();
        }



      }

      }
    } //download function
    void openDownloadFolder()async{
      var permisson = await Permission.storage.request();
      while(permisson.isDenied){
        permisson = await Permission.storage.request();
      }

      if (permisson.isGranted) {

        String path = await createFolderInAppDocDir();
        if (kDebugMode) {
          print(path);
        }
        try{
          String value = await platform.invokeMethod("open",{
            "path":path,
          });
        }catch(e){
          if (kDebugMode) {
            print(e);
          }
        }

      }
    }


  }

