import 'package:datcao/share/import.dart';

enum DialogAction {
  cancel,
  discard,
  disagree,
  agree,
}

typedef TapButtonListener(DialogAction action);
typedef TapConfirm();

void showWaitingDialog(BuildContext context) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
            elevation: 0,
            contentPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            content: Center(
                child: Material(
              borderRadius: BorderRadius.circular(25),
              elevation: 3,
              child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: kLoadingSpinner),
            )));
      });
}

Future<bool> showConfirmDialog(BuildContext context, String errorMessage,
    {@required TapConfirm confirmTap,
    @required GlobalKey<NavigatorState> navigatorKey}) async {
  final val = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: new Text(errorMessage, style: TextStyle(fontSize: 15.0)),
          actions: <Widget>[
            FlatButton(
                child: Text('Huỷ',
                    style: TextStyle(color: Theme.of(context).primaryColor)),
                onPressed: () {
                  navigatorKey.currentState.pop(false);
                  return false;
                }),
            FlatButton(
              child: Text('Ok',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                confirmTap();
                navigatorKey.currentState.pop(true);
                return true;
              },
            ),
            SizedBox(
              width: 5,
            ),
          ],
        );
      });
  return val as bool;
}

Future<bool> showAlertDialog(BuildContext context, String errorMessage,
    {TapConfirm confirmTap,
    String confirmLabel,
    bool showClose = false,
    @required GlobalKey<NavigatorState> navigatorKey}) async {
  Color primaryColor = Theme.of(context).primaryColor;
  return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          content: Text(errorMessage ?? '', style: TextStyle(fontSize: 15.0)),
          actions: <Widget>[
            if (showClose)
              FlatButton(
                  child: Text('Close', style: TextStyle(color: primaryColor)),
                  onPressed: () => navigatorKey.currentState.pop()),
            FlatButton(
                child: Text(confirmLabel != null ? confirmLabel : 'Ok',
                    style: TextStyle(color: primaryColor)),
                onPressed: confirmTap != null
                    ? confirmTap
                    : () => navigatorKey.currentState.pop(true)),
          ],
        );
      });
}

Future<bool> showPasswordDialog(BuildContext context,
    {TapConfirm confirmTap,
    String content,
    TextEditingController passController,
    @required GlobalKey<NavigatorState> navigatorKey}) async {
  return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (content != null) ...[
                Text(content),
                SizedBox(height: 5),
              ],
              TextField(
                controller: passController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Enter password'),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: Text('Close',
                    style: TextStyle(color: Theme.of(context).primaryColor)),
                onPressed: () => navigatorKey.currentState.pop(false)),
            FlatButton(
              child: Text('Ok',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                navigatorKey.currentState.pop(true);
                if (confirmTap != null) confirmTap();
              },
            ),
          ],
        );
      });
}

Future showAlertWithTitleDialog(
    BuildContext context, String title, String content,
    {String firstAction,
    TapConfirm firstTap,
    String secondAction,
    TapConfirm secondTap,
    String thirdAction,
    TapConfirm thirdTap,
    @required GlobalKey<NavigatorState> navigatorKey}) {
  List<Widget> actions = new List<Widget>();
  Color primaryColor = Theme.of(context).primaryColor;

  if (thirdAction != null && thirdAction.isNotEmpty) {
    actions.add(new FlatButton(
      child: Text(thirdAction, style: TextStyle(color: primaryColor)),
      onPressed:
          thirdTap != null ? thirdTap : () => navigatorKey.currentState.pop(),
    ));
  }

  if (secondAction != null && secondAction.isNotEmpty) {
    actions.add(new FlatButton(
      child: Text(secondAction, style: TextStyle(color: primaryColor)),
      onPressed:
          secondTap != null ? secondTap : () => navigatorKey.currentState.pop(),
    ));
  }

  actions.add(new FlatButton(
    child: Text(firstAction ?? 'Ok', style: TextStyle(color: primaryColor)),
    onPressed:
        firstTap != null ? firstTap : () => navigatorKey.currentState.pop(),
  ));

  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content, style: TextStyle(fontSize: 15.0)),
          actions: actions,
        );
      });
}

showUndoneFeature(BuildContext context, List<String> features) {
  showAlertDialog(context,
      'Tính năng:\n${features.map<String>((e) => " - " + e.toString() + "\n").toList().join()} chưa được phát triển',
      navigatorKey: navigatorKey);
}

showSimpleLoadingDialog(BuildContext context, {bool canDismiss = true}) {
  return showDialog(
      barrierDismissible: canDismiss,
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            child: Container(
              width: deviceWidth(context) / 1.4,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  kLoadingSpinner,
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Vui lòng chờ giây lát',
                    style: ptBigBody(),
                  ),
                ],
              ),
            ),
          ),
        );
      });
}
