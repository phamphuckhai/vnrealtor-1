import 'package:datcao/modules/authentication/auth_bloc.dart';
import 'package:datcao/modules/bloc/post_bloc.dart';
import 'package:datcao/modules/bloc/user_bloc.dart';
import 'package:datcao/modules/inbox/inbox_bloc.dart';
import 'package:datcao/modules/model/post.dart';
import 'package:datcao/modules/model/user.dart';
import 'package:datcao/modules/post/post_widget.dart';
import 'package:datcao/modules/profile/follow_page.dart';
import 'package:datcao/modules/profile/profile_page.dart';
import 'package:datcao/modules/repo/user_repo.dart';
import 'package:datcao/share/import.dart';
import 'package:datcao/share/widget/custom_tooltip.dart';
import 'package:datcao/share/widget/empty_widget.dart';
import 'package:datcao/share/widget/verified_icon.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileOtherPage extends StatefulWidget {
  final UserModel user;
  final String userId;

  const ProfileOtherPage(this.user, {this.userId});
  static Future navigate(UserModel user, {String userId}) {
    if (AuthBloc.instance.userModel == null) {
      return navigatorKey.currentState
          .push(pageBuilder(ProfileOtherPage(user, userId: userId)));
    }
    if (user?.id == AuthBloc.instance.userModel?.id) {
      return navigatorKey.currentState.push(pageBuilder(ProfilePage()));
    }
    return navigatorKey.currentState
        .push(pageBuilder(ProfileOtherPage(user, userId: userId)));
  }

  @override
  _ProfileOtherPageState createState() => _ProfileOtherPageState();
}

class _ProfileOtherPageState extends State<ProfileOtherPage> {
  PostBloc _postBloc;
  List<PostModel> _posts;
  UserModel _user;

  @override
  void initState() {
    _user = widget.user;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_postBloc == null) {
      _postBloc = Provider.of<PostBloc>(context);
      if (_user == null) {
        _loadUser();
      }
      _loadPost();
    }
    super.didChangeDependencies();
  }

  _loadUser() async {
    final res = await UserBloc.instance.getListUserIn([widget.userId]);
    if (res.isSuccess) {
      setState(() {
        _user = res.data[0];
      });
    } else {
      showToast('Có lỗi khi load dữ liệu', context);
    }
  }

  Future _loadPost() async {
    final res = AuthBloc.instance.userModel != null
        ? await _postBloc.getUserPost(_user?.id ?? widget.userId)
        : await _postBloc.getUserPostGuest(_user?.id ?? widget.userId);
    if (!res.isSuccess)
      showToast(res.errMessage, context);
    else {
      setState(() {
        _posts = res.data;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ptBackgroundColor(context),
      appBar: AppBar1(
        title: _user?.name ?? '',
        automaticallyImplyLeading: true,
        actions: [
          if ([
            UserRole.admin,
            UserRole.admin_user,
            UserRole.manager,
            UserRole.mod
          ].contains(UserBloc.getRole(AuthBloc.instance.userModel)))
            PopupMenuButton(
              itemBuilder: (_) => <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.black,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Khoá người dùng',
                          style: ptBody().copyWith(color: Colors.black),
                        ),
                      ],
                    ),
                    value: 'lock'),
              ],
              onSelected: (val) async {
                if (val == 'lock') {
                  final res =
                      await UserBloc.instance.blockUserByAdmin(_user?.id);
                  if (res.isSuccess)
                    showToast('Đã khoá tài khoản người dùng này', context,
                        isSuccess: true);
                  else
                    showToast(res.errMessage, context);
                }
              },
              child: SizedBox(
                width: 25,
                height: 25,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.black.withOpacity(0.8),
                  size: 25,
                ),
              ),
            ),
          SizedBox(
            width: 18,
          )
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, value) {
          return [
            SliverToBoxAdapter(
              child: _user != null
                  ? ProfileCard(
                      user: _user,
                    )
                  : Container(),
            ),
          ];
        },
        body: Container(
          child: _posts == null
              ? SingleChildScrollView(child: PostSkeleton())
              : (_posts.length != 0
                  ? ListView.separated(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return PostWidget(post);
                      },
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 15),
                    )
                  : EmptyWidget(
                      assetImg: 'assets/image/no_post.png',
                      content: _user?.name ?? '' + ' chưa có bài đăng nào.',
                    )),
        ),
      ),
    );
  }
}

// class ProfileOtherPageAppBar extends StatelessWidget
//     implements PreferredSizeWidget {
//   Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);
//   ProfileOtherPageAppBar();
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
//       child: Padding(
//         padding:
//             const EdgeInsets.only(left: 20, top: 12, bottom: 10, right: 12),
//         child: Row(
//           children: [
//             Image.asset('assets/image/logo_full.png'),
//             Spacer(),
//             GestureDetector(
//               onTap: () {
//                 showAlertDialog(context, 'Đang phát triển',
//                     navigatorKey: navigatorKey);
//               },
//               child: SizedBox(
//                 width: 42,
//                 height: 42,
//                 child: Icon(
//                   MdiIcons.menu,
//                   size: 26,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       color: ptSecondaryColor(context),
//     );
//   }
// }

class ProfileCard extends StatefulWidget {
  final UserModel user;

  const ProfileCard({Key key, this.user}) : super(key: key);

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  UserBloc _userBloc;
  AuthBloc _authBloc;
  bool initFetchStatus = false;
  Uri _emailLaunchUri;

  @override
  void initState() {
    super.initState();
    _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: widget.user.email,
    );
  }

  @override
  void didChangeDependencies() {
    if (_userBloc == null) {
      _userBloc = Provider.of<UserBloc>(context);
      _authBloc = Provider.of<AuthBloc>(context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8).copyWith(top: 0, bottom: 0),
      child: Material(
          borderRadius: BorderRadius.circular(5),
          // elevation: 3,
          child: Container(
            width: deviceWidth(context),
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14)
                .copyWith(bottom: 0, right: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // border: Border.all(
                          //     width: 2.5, color: ptPrimaryColor(context)),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 37.5,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.user.avatar != null
                                ? CachedNetworkImageProvider(widget.user.avatar)
                                : AssetImage('assets/image/default_avatar.png'),
                            child: VerifiedIcon(widget.user.role, 14),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6),
                            Row(
                              children: [
                                SizedBox(width: 15),
                                Icon(
                                  Icons.star_outline,
                                  color: Colors.deepOrange,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  widget.user.name ?? '',
                                  style: ptBigTitle(),
                                ),
                                SizedBox(width: 8),
                                if (UserBloc.isVerified(widget.user))
                                  CustomTooltip(
                                    margin: EdgeInsets.only(top: 0),
                                    message: 'Tài khoản xác thực',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue[600],
                                      ),
                                      padding: EdgeInsets.all(1.3),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.user.totalPost.toString(),
                                        style: ptBigTitle(),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Thích',
                                        style: ptSmall(),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (AuthBloc.instance.userModel == null) {
                                        showToast('Vui lòng đăng nhập để xem',
                                            context,
                                            isSuccess: true);
                                        return;
                                      }
                                      FollowPage.navigate(widget.user, 0);
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.user.followerIds.length
                                              .toString(),
                                          style: ptBigTitle(),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Follower',
                                          style: ptSmall(),
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (AuthBloc.instance.userModel == null) {
                                        showToast('Vui lòng đăng nhập để xem',
                                            context,
                                            isSuccess: true);
                                        return;
                                      }
                                      FollowPage.navigate(widget.user, 1);
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.user.followingIds.length
                                              .toString(),
                                          style: ptBigTitle(),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Đang Follow',
                                          style: ptSmall(),
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  // Text(
                  //   widget.user.role.toLowerCase() == 'agency'
                  //       ? 'Nhà môi giới'
                  //       : 'Người dùng cơ bản',
                  //   style: ptSmall().copyWith(color: Colors.blue),
                  // ),
                  if (widget.user.description != null)
                    Text(widget.user.description),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Điểm tương tác: ${widget.user.reputationScore.toString()}',
                                style: ptBody().copyWith(color: Colors.black54),
                              ),
                              SizedBox(width: 5),
                              SizedBox(
                                  height: 13,
                                  width: 13,
                                  child: Image.asset('assets/image/ip.png')),
                            ],
                          ),
                          // if (_authBloc.userModel.followingIds
                          //     .contains(widget.user.id))
                          //   Row(
                          //     children: [
                          //       Text('Đang theo dõi'),
                          //       SizedBox(
                          //         width: 5,
                          //       ),
                          //       Icon(
                          //         Icons.check,
                          //         color: ptPrimaryColor(context),
                          //         size: 15,
                          //       )
                          //     ],
                          //   ),
                        ],
                      ),
                      Spacer(),
                      SizedBox(
                          width: 23,
                          height: 23,
                          child: Image.asset('assets/image/facebook_icon.png')),
                      SizedBox(width: 15),
                      if (widget.user.email != null)
                        GestureDetector(
                          onTap: () {
                            launch(_emailLaunchUri.toString());
                          },
                          child: SizedBox(
                              width: 26,
                              height: 26,
                              child:
                                  Image.asset('assets/image/gmail_icon.png')),
                        ),
                      SizedBox(width: 12),
                      if (widget.user.dynamicLink != null)
                        GestureDetector(
                          onTap: () {
                            showToast('Đã copy đường dẫn tài khoản', context,
                                isSuccess: true);
                            Clipboard.setData(ClipboardData(
                                text: widget.user.dynamicLink.shortLink));
                          },
                          child: SizedBox(
                              width: 23,
                              height: 23,
                              child: Image.asset('assets/image/logo.png')),
                        ),
                    ],
                  ),
                  SizedBox(height: 15),
                  (_authBloc.userModel != null)
                      ? Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                BaseResponse res;
                                if (_authBloc.userModel.followingIds
                                    .contains(widget.user.id)) {
                                  widget.user.followerIds
                                      .remove(_authBloc.userModel.id);
                                  _authBloc.userModel.followingIds
                                      .remove(widget.user.id);
                                  setState(() {});
                                  res = await _userBloc
                                      .unfollowUser(widget.user.id);
                                  if (res.isSuccess) {
                                  } else {
                                    showToast(res.errMessage, context);
                                    widget.user.followerIds
                                        .add(_authBloc.userModel.id);
                                    _authBloc.userModel.followingIds
                                        .add(widget.user.id);
                                    setState(() {});
                                  }
                                } else {
                                  _authBloc.userModel.followingIds
                                      .add(widget.user.id);
                                  widget.user.followerIds
                                      .add(_authBloc.userModel.id);
                                  setState(() {});
                                  res = await _userBloc
                                      .followUser(widget.user.id);
                                  if (res.isSuccess) {
                                  } else {
                                    showToast(res.errMessage, context);
                                    _authBloc.userModel.followingIds
                                        .remove(widget.user.id);
                                    widget.user.followerIds
                                        .remove(_authBloc.userModel.id);
                                    setState(() {});
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: ptPrimaryColor(context),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _authBloc.userModel.followingIds
                                            .contains(widget.user.id)
                                        ? (_authBloc.userModel.followerIds
                                                .contains(widget.user.id)
                                            ? 'Bạn bè'
                                            : 'Bỏ theo dõi')
                                        : (_authBloc.userModel.followerIds
                                                .contains(widget.user.id)
                                            ? 'Follow lại'
                                            : 'Follow'),
                                    style: ptTitle(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_authBloc.userModel != null &&
                              _authBloc.userModel.followingIds
                                  .contains(widget.user.id))
                            SizedBox(
                              width: 12,
                            ),
                          if (_authBloc.userModel != null &&
                              _authBloc.userModel.followingIds
                                  .contains(widget.user.id))
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  showWaitingDialog(context);
                                  await InboxBloc.instance.navigateToChatWith(
                                      widget.user.name,
                                      widget.user.avatar,
                                      DateTime.now(),
                                      widget.user.avatar, [
                                    AuthBloc.instance.userModel.id,
                                    widget.user.id,
                                  ], [
                                    AuthBloc.instance.userModel.avatar,
                                    widget.user.avatar,
                                  ]);
                                  navigatorKey.currentState.maybePop();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: ptPrimaryColor(context))),
                                  child: Center(
                                    child: Text(
                                      'Nhắn tin',
                                      style: ptTitle(),
                                    ),
                                  ),
                                ),
                              ),
                            )
                        ])
                      : SizedBox.shrink(),
                  SizedBox(height: 10),
                ]),
          )),
    );
  }
}
