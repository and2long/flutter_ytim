import 'package:flutter/material.dart';
import 'package:flutter_ytim/flutter_ytim.dart';
import 'package:flutter_ytim/src/bean/im_msg_list.dart';
import 'package:flutter_ytim/src/other/yt_sp_utils.dart';
import 'package:flutter_ytim/src/other/yt_utils.dart';
import 'package:provider/provider.dart';

class IMUserListPage extends StatefulWidget {
  final bool showAppBar;

  const IMUserListPage({Key key, this.showAppBar = false}) : super(key: key);

  @override
  _IMUserListPageState createState() => _IMUserListPageState();
}

class _IMUserListPageState extends State<IMUserListPage> {
  List<IMUser> _items = [];

  // 当前正在与之聊天的用户id。
  String _currentChatUserId = '';

  @override
  void initState() {
    super.initState();
    YTIM().on<IMMsgList>().listen((event) {
      Map<String, dynamic> messageList = event.messageList;
      for (String imId in messageList.keys) {
        List msgs = messageList[imId] as List;
        Map<String, IMLastInfo> map = context.read<IMStore>().lastInfos;
        if (map[imId] == null) {
          map[imId] = IMLastInfo(
              msg: IMMessage.fromJson(msgs.last), unreadCount: msgs.length);
        } else {
          map[imId].msg = IMMessage.fromJson(msgs.last);
          map[imId].unreadCount = msgs.length;
        }
        context.read<IMStore>().update(map);
        _updateUnreadCount(map);
      }
    });

    YTIM().on<IMMessage>().listen((event) {
      Map<String, IMLastInfo> map = context.read<IMStore>().lastInfos;
      if (map.keys.contains(event.from)) {
        if (_currentChatUserId != event.from) {
          map[event.from].unreadCount += 1;
        }
        map[event.from].msg = event;
      } else {
        if (event.from != YTIM().mUser.userId.toString()) {
          map[event.from] = IMLastInfo(
              msg: event,
              unreadCount: _currentChatUserId != event.from ? 1 : 0);
        }
      }
      YTSPUtils.saveLastMsg(event.from, event);
      context.read<IMStore>().update(map);
      _updateUnreadCount(map);
    });

    YTIM().on<IMUserList>().listen((event) {
      if (mounted) {
        YTIM().getUnreadMessage();
        setState(() {
          _items = event.userList;
        });
      }
    });
  }

  /// 通知更新未读消息
  void _updateUnreadCount(Map<String, IMLastInfo> map) {
    YTUtils.updateUnreadCount(map);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: _buildTitle()) : null,
      body: ListView.builder(
        itemBuilder: (c, i) {
          Map<String, IMLastInfo> map = context.read<IMStore>().lastInfos;
          return _buildItem(
              _items[i], map[_items[i].userId.toString()]?.unreadCount ?? 0);
        },
        itemCount: _items.length,
      ),
    );
  }

  StreamBuilder<IMConnectState> _buildTitle() {
    return StreamBuilder<IMConnectState>(
      builder: (BuildContext context, AsyncSnapshot<IMConnectState> snapshot) {
        if (snapshot.hasData) {
          String state;
          switch (snapshot.data) {
            case IMConnectState.IDLE:
              state = '离线';
              break;
            case IMConnectState.Connecting:
              state = '连接中...';
              break;
            case IMConnectState.Connected:
              state = '在线';
              break;
            default:
              state = '离线';
          }
          return Text('YTIM - $state');
        } else {
          return Text('YTIM');
        }
      },
      stream: YTIM().on<IMConnectState>(),
    );
  }

  Widget _buildItem(IMUser item, int count) {
    return InkWell(
      onTap: () {
        // 重置对方的未读消息个数。
        Map<String, IMLastInfo> map = context.read<IMStore>().lastInfos;
        if (map.keys.contains(item.userId.toString())) {
          map[item.userId.toString()].unreadCount = 0;
          context.read<IMStore>().update(map);
        }
        YTUtils.updateUnreadCount(map);
        _currentChatUserId = item.userId.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(tid: item.userId.toString()),
          ),
        ).then((value) {
          _currentChatUserId = '';
          _setLastMsg();
        });
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border(bottom: Divider.createBorderSide(context)),
        ),
        child: Row(
          children: [
            IMUserAvatar(imUser: item),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 名字
                    Text(item.username),
                    SizedBox(height: 3),
                    // 最后一条消息
                    Text(
                      context
                              .read<IMStore>()
                              .lastInfos[item.userId.toString()]
                              ?.msg
                              ?.content ??
                          '',
                      style: Theme.of(context).textTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 时间
                Text(
                    YTUtils.millisecondsToString(context
                            .read<IMStore>()
                            .lastInfos[item.userId.toString()]
                            ?.msg
                            ?.timestamp ??
                        ''),
                    style: Theme.of(context).textTheme.caption),
                SizedBox(height: 3),
                // 未读个数
                UnreadCountView(count: count),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _setLastMsg() {
    setState(() {
      for (IMUser user in _items) {
        IMMessage msg = YTSPUtils.getLastMsg(user.userId.toString());
        if (msg != null) {
          Map<String, IMLastInfo> map = context.read<IMStore>().lastInfos;
          if (map[user.userId.toString()] == null) {
            map[user.userId.toString()] = IMLastInfo(msg: msg);
          } else {
            map[user.userId.toString()].msg = msg;
          }
        }
      }
    });
  }
}