import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:vnrealtor/modules/bloc/post_bloc.dart';
import 'package:vnrealtor/modules/model/media_post.dart';
import 'package:vnrealtor/modules/model/post.dart';
import 'package:vnrealtor/modules/post/comment_page.dart';
import 'package:vnrealtor/share/function/share_to.dart';
import 'package:vnrealtor/share/import.dart';
import 'package:vnrealtor/share/widget/spin_loader.dart';
import 'package:vnrealtor/utils/constants.dart';
import 'package:vnrealtor/utils/file_util.dart';
import 'package:video_player/video_player.dart';

class MediaPostWidget extends StatelessWidget {
  final MediaPost post;
  final String tag;
  final double borderRadius;
  MediaPostWidget({@required this.post, this.tag, this.borderRadius = 0});
  @override
  Widget build(BuildContext context) {
    String genTag = tag ?? post.url + Random().nextInt(10000000).toString();
    final type = FileUtil.getFbUrlFileType(post.url);
    return GestureDetector(
      onTap: () {
        if (type == FileType.image || type == FileType.gif)
          Navigator.push(context, MaterialPageRoute(builder: (_) {
            return DetailImagePost(
              post,
              tag: genTag,
            );
          }));
        if (type == FileType.video)
          Navigator.push(context, MaterialPageRoute(builder: (_) {
            return DetailVideoPost(
              post,
              tag: genTag,
            );
          }));
      },
      child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _getWidget(type)),
    );
  }

  Widget _getWidget(FileType type) {
    if (type == FileType.image || type == FileType.gif)
      return Image.network(
        post.url,
        fit: BoxFit.cover,
        errorBuilder: imageNetworkErrorBuilder,
        loadingBuilder: kLoadingBuilder,
      );
    else if (type == FileType.video)
      return Image.asset(
        'assets/image/video_holder.png',
        fit: BoxFit.cover,
        errorBuilder: imageNetworkErrorBuilder,
      );
    return SizedBox.shrink();
  }
}

class DetailImagePost extends StatefulWidget {
  final MediaPost post;
  final String tag;
  DetailImagePost(this.post, {this.tag});

  @override
  _DetailImagePostState createState() => _DetailImagePostState();
}

class _DetailImagePostState extends State<DetailImagePost> {
  bool _isLike = false;
  PostBloc _postBloc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_postBloc == null) {
      _postBloc = Provider.of<PostBloc>(context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(fit: StackFit.expand, children: [
          Center(
            child: PhotoView(
              backgroundDecoration: BoxDecoration(color: Colors.black87),
              imageProvider: NetworkImage(
                widget.post.url,
              ),
              errorBuilder: (_, __, ___) => SizedBox.shrink(),
              loadingBuilder: (context, event) => PhotoView(
                backgroundDecoration: BoxDecoration(color: Colors.black87),
                imageProvider: NetworkImage(
                  widget.post.url,
                ),
                loadingBuilder: (context, event) => Center(
                  child: kLoadingSpinner,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 10,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20)),
                width: 40,
                height: 40,
                child: Icon(Icons.close),
              ),
            ),
          ),
          Positioned(
            width: deviceWidth(context),
            bottom: 0,
            child: Container(
              height: 48,
              color: Colors.black38,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _isLike = !_isLike;
                        if (_isLike) {
                          widget.post.like++;
                          _postBloc.likeMediaPost(widget.post.id);
                        } else {
                          if (widget.post.like > 0) widget.post.like--;
                          _postBloc.unlikeMediaPost(widget.post.id);
                        }
                        setState(() {});
                      },
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.thumbUpOutline,
                              size: 19,
                              color: _isLike
                                  ? ptPrimaryColor(context)
                                  : Colors.white,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Like',
                              style: TextStyle(
                                  color: _isLike
                                      ? ptPrimaryColor(context)
                                      : Colors.white),
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.commentOutline,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              showComment(widget.post, context);
                            },
                            child: Text(
                              'Comment',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ]),
                  ),
                  Expanded(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.shareOutline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          GestureDetector(
                            onTap: () => shareTo(context),
                            child: Text(
                              'Share',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ]),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            width: deviceWidth(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ptPrimaryColor(context),
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      MdiIcons.thumbUp,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    widget.post?.like?.toString() ?? '0',
                    style: ptSmall().copyWith(color: Colors.white),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      showComment(widget.post, context);
                    },
                    child: Text(
                      '${widget.post?.commentIds?.length.toString() ?? '0'} comments',
                      style: ptSmall().copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}

class DetailVideoPost extends StatefulWidget {
  final MediaPost post;
  final String tag;
  final int scaleW, scaleH;
  DetailVideoPost(this.post, {this.tag, this.scaleW, this.scaleH});

  @override
  _DetailVideoPostState createState() => _DetailVideoPostState();
}

class _DetailVideoPostState extends State<DetailVideoPost> {
  VideoPlayerController _controller;
  bool videoEnded = false;
  bool _isLike = false;
  PostBloc _postBloc;

  @override
  void didChangeDependencies() {
    if (_postBloc == null) {
      _postBloc = Provider.of<PostBloc>(context);
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.post.url)
      ..initialize().then(
        (_) {
          if (mounted)
            setState(() {
              _controller.play();
            });
        },
      );
    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        setState(() {
          videoEnded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(fit: StackFit.expand, children: [
          Positioned(
            width: MediaQuery.of(context).size.width,
            top: kToolbarHeight,
            bottom: 0,
            child: Container(
              child: Center(
                child: _controller.value.initialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : kLoadingSpinner,
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight,
            right: 10,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20)),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            width: deviceWidth(context),
            bottom: 0,
            child: Container(
              height: 48,
              color: Colors.black38,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _isLike = !_isLike;
                        if (_isLike) {
                          widget.post.like++;
                          _postBloc.likeMediaPost(widget.post.id);
                        } else {
                          if (widget.post.like > 0) widget.post.like--;
                          _postBloc.unlikeMediaPost(widget.post.id);
                        }
                        setState(() {});
                      },
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.thumbUpOutline,
                              size: 19,
                              color: _isLike
                                  ? ptPrimaryColor(context)
                                  : Colors.white,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Like',
                              style: TextStyle(
                                  color: _isLike
                                      ? ptPrimaryColor(context)
                                      : Colors.white),
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.commentOutline,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              showComment(widget.post, context);
                            },
                            child: Text(
                              'Comment',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ]),
                  ),
                  Expanded(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.shareOutline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          GestureDetector(
                            onTap: () => shareTo(context),
                            child: Text(
                              'Share',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ]),
                  )
                ],
              ),
            ),
          ),
        ]),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     if (videoEnded) {
      //       await _controller.seekTo(Duration.zero);
      //       _controller.play();
      //       setState(() {
      //         videoEnded = false;
      //       });
      //       return;
      //     }
      //     setState(() {
      //       _controller.value.isPlaying
      //           ? _controller.pause()
      //           : _controller.play();
      //     });
      //   },
      //   child: Icon(
      //     videoEnded
      //         ? Icons.replay
      //         : (_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      //   ),
      // ),
    );
  }
}

showComment(MediaPost postModel, BuildContext context) {
  showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
            height: deviceHeight(context) - kToolbarHeight - 15,
            child: Column(
              children: [
                Container(
                  height: 10,
                  width: deviceWidth(context),
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 4,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: CommentPage(
                  mediaPost: postModel,
                )),
              ],
            ));
      });
}