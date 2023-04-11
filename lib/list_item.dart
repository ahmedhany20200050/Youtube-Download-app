import 'package:flutter/material.dart';
import 'package:youtube_test/VideoInfo.dart';

class ListItem extends StatelessWidget {
  int id;
  VideoInfo currentVideoInfo;
  void Function()? delete;
  double progress=0;
  double size;
  ListItem(this.currentVideoInfo,this.delete,this.id, this.size,{super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(
          "https://img.youtube.com/vi/${currentVideoInfo.video.id}/0.jpg",
          height: 100,
          width: 100,
        ),
        Text(currentVideoInfo.video.title.substring(0,15)),
        Text(currentVideoInfo.format),
        const SizedBox(width: 4),
        Text("${size.toStringAsFixed(2)} MP", style: TextStyle(
          fontSize: 8,

        ),),
        TextButton(onPressed: delete, child: const Icon(Icons.delete)),
        const SizedBox(height: 20,),
      ],
    );
  }
}
