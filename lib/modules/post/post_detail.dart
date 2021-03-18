import 'package:datcao/modules/authentication/auth_bloc.dart';
import 'package:datcao/modules/authentication/login.dart';
import 'package:datcao/modules/bloc/post_bloc.dart';
import 'package:datcao/modules/model/comment.dart';
import 'package:datcao/modules/model/post.dart';
import 'package:datcao/modules/post/comment_page.dart';
import 'package:datcao/modules/post/post_widget.dart';
import 'package:datcao/share/import.dart';
import 'package:graphql/client.dart';
import 'dart:async';
import 'package:datcao/modules/model/reply.dart';

class PostDetail extends StatefulWidget {
  final PostModel postModel;
  final String postId;

  const PostDetail({Key key, this.postModel, this.postId}) : super(key: key);
  static Future navigate(PostModel postModel, {String postId}) {
    return navigatorKey.currentState.push(pageBuilder(PostDetail(
      postModel: postModel,
      postId: postId,
    )));
  }

  @override
  _PostDetailState createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  List<CommentModel> comments;
  TextEditingController _commentC = TextEditingController();
  PostBloc _postBloc;
  PostModel _post;
  StreamSubscription<FetchResult> _streamSubcription;
  bool isReply = false;
  FocusNode _focusNodeComment = FocusNode();
  CommentModel replyComment;
  List<ReplyModel> localReplies = [];

  @override
  void initState() {
    _focusNodeComment.addListener(() {
      if (!_focusNodeComment.hasFocus) {
        setState(() {
          isReply = false;
          replyComment = null;
        });
      }
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_postBloc == null) {
      _postBloc = Provider.of<PostBloc>(context);
      if (widget.postModel != null) {
        _post = widget.postModel;
        _getComments(_post.id, filter: GraphqlFilter(limit: 20));
      } else {
        _getPost();
        _getComments(widget.postId, filter: GraphqlFilter(limit: 20));
      }

      //setup socket
      // _postBloc.subscriptionCommentByPostId(widget.postModel?.id??widget.postId);

      // Future.delayed(Duration(seconds: 2), () {
      //   _streamSubcription = _postBloc.commentSubcription.listen((event) {
      //     print(event.data);
      //     CommentModel socketComment =
      //         CommentModel.fromJson(event.data['newComment']);
      //     if (socketComment.userId != AuthBloc.instance.userModel?.id)
      //       setState(() {
      //         comments.add(socketComment);
      //       });
      //   });
      // });
    }
    super.didChangeDependencies();
  }

  _reply(String text) async {
    if (replyComment == null) return;
    text = text.trim();
    if (comments == null) await Future.delayed(Duration(seconds: 1));
    _commentC.clear();
    localReplies.add(ReplyModel(
        content: text,
        userId: AuthBloc.instance.userModel.uid,
        commentId: replyComment.id,
        user: AuthBloc.instance.userModel,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String()));
    setState(() {});
    FocusScope.of(context).requestFocus(FocusNode());
    BaseResponse res = await _postBloc.createReply(text, replyComment.id);
    if (!res.isSuccess) {
      showToast(res.errMessage, context);
    } else {
      final index = localReplies
          .indexWhere((element) => element.createdAt == res.data.createdAt);
      if (index >= 0) {
        localReplies[index] = res.data;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubcription?.cancel();
  }

  Future _getPost() async {
    final res = await _postBloc.getOnePost(widget.postId);
    if (res.isSuccess) {
      setState(() {
        _post = res.data;
      });
    } else {
      navigatorKey.currentState.maybePop();
      showToast(res.errMessage, context);
    }
  }

  Future _getComments(String postId, {GraphqlFilter filter}) async {
    BaseResponse res = AuthBloc.instance.userModel != null
        ? await _postBloc.getAllCommentByPostId(postId, filter: filter)
        : await _postBloc.getAllCommentByPostIdGuest(postId, filter: filter);
    if (res == null) return;
    if (res.isSuccess) {
      if (mounted)
        setState(() {
          comments = res.data;
        });
    } else {
      showToast('Có lỗi khi lấy dữ liệu', context);
    }
  }

  _comment(String text) async {
    text = text.trim();
    if (comments == null) await Future.delayed(Duration(seconds: 1));
    _commentC.clear();
    comments.add(CommentModel(
        content: text,
        like: 0,
        user: AuthBloc.instance.userModel,
        updatedAt: DateTime.now().toIso8601String()));
    setState(() {});
    FocusScope.of(context).requestFocus(FocusNode());
    BaseResponse res = await _postBloc.createComment(text, postId: _post?.id);
    if (!res.isSuccess) {
      showToast(res.errMessage, context);
    } else {
      _post.commentIds.add((res.data as CommentModel).id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar1(
        centerTitle: true,
        title: _post != null ? 'Bài viết của ${_post.user.name}' : '',
        automaticallyImplyLeading: true,
        bgColor: ptSecondaryColor(context),
        textColor: ptPrimaryColor(context),
      ),
      body: Stack(
        children: [
          Container(
            height: deviceHeight(context),
            width: deviceWidth(context),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: AuthBloc.instance.userModel == null ? 20 : 100),
              child: Column(
                children: [
                  _post == null
                      ? PostSkeleton(
                          count: 1,
                        )
                      : PostWidget(
                          _post,
                          commentCallBack: () {},
                        ),
                  comments != null
                      ? ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: comments.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return new CommentWidget(
                                comment: comment,
                                userReplyCache: localReplies,
                                shouldExpand:
                                    comments[index].id == replyComment?.id,
                                tapCallBack: () {
                                  setState(() {
                                    isReply = true;
                                    replyComment = comments[index];
                                  });
                                  _focusNodeComment.requestFocus();
                                });
                          },
                          separatorBuilder: (context, index) =>
                              SizedBox.shrink(),
                        )
                      : ListSkeleton(),
                ],
              ),
            ),
          ),
          if (AuthBloc.instance.userModel != null)
            Positioned(
              bottom: 0,
              child: Container(
                width: deviceWidth(context),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                color: Colors.white70,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          AuthBloc.instance.userModel?.avatar != null
                              ? CachedNetworkImageProvider(
                                  AuthBloc.instance.userModel?.avatar)
                              : AssetImage('assets/image/default_avatar.png'),
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentC,
                        maxLines: null,
                        onTap: () {
                          if (AuthBloc.instance.userModel == null) {
                            LoginPage.navigatePush();
                            return;
                          }
                        },
                        // maxLength: 200,
                        onSubmitted: _comment,
                        focusNode: _focusNodeComment,
                        decoration: InputDecoration(
                          suffixIcon: GestureDetector(
                              onTap: () {
                                (isReply)
                                    ? _reply(_commentC.text)
                                    : _comment(_commentC.text);
                              },
                              child: Icon(Icons.send)),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                          isDense: true,
                          hintText: isReply
                              ? 'Trả lời ${replyComment?.user?.name ?? ''}'
                              : 'Viết bình luận.',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          fillColor: ptSecondaryColor(context),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
