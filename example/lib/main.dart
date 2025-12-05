import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter_xmpp_example/constants.dart';
import 'package:flutter_xmpp_example/homepage.dart';
import 'package:flutter_xmpp_example/native_log_helper.dart';
import 'package:flutter_xmpp_example/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xmpp_plugin/custom_element.dart';
import 'package:xmpp_plugin/ennums/xmpp_connection_state.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/models/chat_state_model.dart';
import 'package:xmpp_plugin/models/connection_event.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/models/present_mode.dart';
import 'package:xmpp_plugin/success_response_event.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';

import 'mamExamples.dart';

const myTask = "syncWithTheBackEnd";

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver
    implements DataChangeEvents {
  static late XmppConnection flutterXmpp;
  List<MessageChat> events = [];
  List<PresentModel> presentMo = [];
  String connectionStatus = "Disconnected";
  String connectionStatusMessage = "";

  @override
  void initState() {
    checkStoragePermission();
    XmppConnection.addListener(this);
    super.initState();
    log('didChangeAppLifecycleState() initState');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    XmppConnection.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    log('didChangeAppLifecycleState() dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('didChangeAppLifecycleState()');
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        log('detachedCallBack()');
        break;
      case AppLifecycleState.resumed:
        log('resumed detachedCallBack()');
        break;
    }
  }

  Future<void> connect() async {
    final auth = {
      "user_jid":
          "${_userNameController.text}@${_hostController.text}/${Platform.isAndroid ? "Android" : "iOS"}",
      "password": "11111111",
      "host": "192.168.56.1",
      "port": '5222',
      "nativeLogFilePath": NativeLogHelper.logFilePath,
      "requireSSLConnection": false,
      "autoDeliveryReceipt": false,
      "useStreamManagement": false,
      "automaticReconnection": true,
    };

    flutterXmpp = XmppConnection(auth);
    await flutterXmpp.start(_onError);
    await flutterXmpp.login();
  }

  void checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      final PermissionStatus _permissionStatus =
          await Permission.storage.request();
      if (_permissionStatus.isGranted) {
        String filePath = await NativeLogHelper().getDefaultLogFilePath();
        print('logFilePath: $filePath');
      } else {
        print('logFilePath: please allow permission');
      }
    } else {
      String filePath = await NativeLogHelper().getDefaultLogFilePath();
      print('logFilePath: $filePath');
    }
  }

  void _onError(Object error) {
    // TODO : Handle the Error event
    print("Error: ${error.toString()}");
  }

  @override
  void onXmppError(ErrorResponseEvent errorResponseEvent) {
    print(
        'receiveEvent onXmppError: ${errorResponseEvent.toErrorResponseData().toString()}');
  }

  @override
  void onSuccessEvent(SuccessResponseEvent successResponseEvent) {
    print(
        'receiveEvent successEventReceive: ${successResponseEvent.toSuccessResponseData().toString()}');
  }

  @override
  void onChatMessage(MessageChat messageChat) {
    events.add(messageChat);
    print('onChatMessage: ${messageChat.toEventData()}');
  }

  @override
  void onGroupMessage(MessageChat messageChat) {
    events.add(messageChat);
    print('onGroupMessage: ${messageChat.toEventData()}');
  }

  @override
  void onNormalMessage(MessageChat messageChat) {
    if (messageChat.type == 'Read-Ack') {
      print('✅ Read receipt reçu pour le message: ${messageChat.id} de ${messageChat.from}');
      log('✅ Read receipt reçu: ${messageChat.toEventData()}');
    } else if (messageChat.type == 'Delivery-Ack') {
      print('📨 Delivery receipt reçu pour le message: ${messageChat.id} de ${messageChat.from}');
      log('📨 Delivery receipt reçu: ${messageChat.toEventData()}');
    } else {
      events.add(messageChat);
      print('onNormalMessage: ${messageChat.toEventData()}');
    }
  }

  @override
  void onPresenceChange(PresentModel presentModel) {
    presentMo.add(presentModel);
    log('onPresenceChange ~~>>${presentModel.toJson()}');
  }

  @override
  void onChatStateChange(ChatState chatState) {
    log('onChatStateChange ~~>>$chatState');
  }

  @override
  void onConnectionEvents(ConnectionEvent connectionEvent) {
    log('onConnectionEvents ~~>>${connectionEvent.toJson()}');
    connectionStatus = connectionEvent.type!.toConnectionName();
    connectionStatusMessage = connectionEvent.error ?? '';
    setState(() {});
  }

  Future<void> disconnectXMPP() async => await flutterXmpp.logout();

  Future<String> joinMucGroups(List<String> allGroupsId) async {
    return await flutterXmpp.joinMucGroups(allGroupsId);
  }

  Future<bool> joinMucGroup(String groupId) async {
    return await flutterXmpp.joinMucGroup(groupId);
  }

  Future<void> addMembersInGroup(String groupName, List<String> members) async {
    await flutterXmpp.addMembersInGroup(groupName, members);
  }

  Future<void> addAdminsInGroup(
      String groupName, List<String> adminMembers) async {
    await flutterXmpp.addAdminsInGroup(groupName, adminMembers);
  }

  Future<void> getMembers(String groupName) async {
    await flutterXmpp.getMembers(groupName);
  }

  Future<void> getOwners(String groupName) async {
    await flutterXmpp.getOwners(groupName);
  }

  Future<void> getOnlineMemberCount(String groupName) async {
    await flutterXmpp.getOnlineMemberCount(groupName);
  }

  Future<void> removeMember(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeMember(groupName, membersJid);
  }

  Future<void> removeAdmin(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeAdmin(groupName, membersJid);
  }

  Future<void> addOwner(String groupName, List<String> membersJid) async {
    await flutterXmpp.addOwner(groupName, membersJid);
  }

  Future<void> removeOwner(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeOwner(groupName, membersJid);
  }

  Future<void> getAdmins(String groupName) async {
    await flutterXmpp.getAdmins(groupName);
  }

  Future<void> changePresenceType(presenceType, presenceMode) async {
    await flutterXmpp.changePresenceType(presenceType, presenceMode);
  }

  String dropDownValue = 'Chat';
  var items = ['Chat', 'Group Chat'];

  ///
  String presenceType = 'available';
  var presenceTypeItems = [
    'available',
    'unavailable',
  ];

  ///
  String presenceMode = 'available';
  var presenceModeitems = [
    'chat',
    'available',
    'away',
    'xa',
    'dnd',
  ];

  TextEditingController _userNameController =
      TextEditingController(text: "tes1");
  TextEditingController _passwordController =
      TextEditingController(text: "tes1");
  TextEditingController _hostController =
      TextEditingController(text: "xm.jtisrv.com");
  TextEditingController _createMUCNamecontroller = TextEditingController();

  TextEditingController _toReceiptController = TextEditingController();
  TextEditingController _msgIdController = TextEditingController();
  TextEditingController _userJidController = TextEditingController();
  TextEditingController _createRostersController = TextEditingController();
  TextEditingController _deleteRosterController = TextEditingController();
  TextEditingController _presenceStatusController = TextEditingController();
  TextEditingController _createRostersListController = TextEditingController();
  TextEditingController _createRostersNameController = TextEditingController();
  TextEditingController _receiptIdController = TextEditingController();
  TextEditingController _sendSubscriptionController = TextEditingController();
  TextEditingController _acceptSubscriptionController = TextEditingController();
  TextEditingController _rejectSubscriptionController = TextEditingController();
  TextEditingController _presenceProbeController = TextEditingController();
  TextEditingController _joinMUCTextController = TextEditingController();
  TextEditingController _joinTimeController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _custommessageController = TextEditingController();
  TextEditingController _toNameController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<CustomElement> customElements = [
    CustomElement(
        childBody: "test",
        childElement: "elem",
        elementName: "Name",
        elementNameSpace: "space")
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('XMPP Plugin'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: () async {
                await disconnectXMPP();
              },
              icon: Icon(Icons.power_settings_new),
            ),
            IconButton(
              onPressed: () async {
                if (await NativeLogHelper().isFileExist()) {
                  Share.shareXFiles([XFile(NativeLogHelper.logFilePath)]);
                } else {
                  if (_scaffoldKey.currentContext != null) {
                    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                        SnackBar(content: Text("File not found!")));
                  }
                }
              },
              icon: Icon(Icons.share),
            ),
            IconButton(
              onPressed: () async {
                if (await NativeLogHelper().isFileExist()) {
                  NativeLogHelper().deleteLogFile();
                } else {
                  if (_scaffoldKey.currentContext != null) {
                    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                        SnackBar(content: Text("File not found!")));
                  }
                }
              },
              icon: Icon(Icons.delete),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Username',
                  textEditController: _userNameController,
                  addKey: true,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Password',
                  textEditController: _passwordController,
                  addKey: true,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Host',
                  textEditController: _hostController,
                  addKey: true,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (connectionStatus == 'Authenticated') {
                          await disconnectXMPP();
                        } else {
                          await connect();
                        }
                      },
                      child: Text(connectionStatus == 'Authenticated'
                          ? "Disconnect"
                          : "Connect"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      key: Key('ConnectButton'),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text('$connectionStatus'),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Builder(
                  builder: (context) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MamExamples(flutterXmpp)),
                            );
                          },
                          child: Text("MAM Modules"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showConnectionStatus,
                          child: Text("Connection Status"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Presence Type: "),
                    DropdownButton(
                      value: presenceType,
                      icon: Icon(Icons.keyboard_arrow_down),
                      items: presenceTypeItems.map(
                        (String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(items),
                          );
                        },
                      ).toList(),
                      onChanged: (val) {
                        setState(
                          () {
                            presenceType = val.toString();
                            changePresenceType(presenceType, presenceMode);
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Presence Mode: "),
                    DropdownButton(
                      value: presenceMode,
                      icon: Icon(Icons.keyboard_arrow_down),
                      items: presenceModeitems.map(
                        (String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(items),
                          );
                        },
                      ).toList(),
                      onChanged: (val) {
                        setState(
                          () {
                            presenceMode = val.toString();
                            changePresenceType(presenceType, presenceMode);
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Group',
                  textEditController: _createMUCNamecontroller,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          await createMUC(
                              "${_createMUCNamecontroller.text}", true);
                        },
                        child: Text('Create Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 45,
                    ),
                    Builder(
                      builder: (context) {
                        return Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
                              await createMUC(
                                  "${_createMUCNamecontroller.text}", true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(
                                    groupName: _createMUCNamecontroller.text,
                                    addMembersInGroup: addMembersInGroup,
                                    addAdminsInGroup: addAdminsInGroup,
                                    removeMember: removeMember,
                                    removeAdmin: removeAdmin,
                                    addOwner: addOwner,
                                    removeOwner: removeOwner,
                                    getAdmins: getAdmins,
                                    getMembers: getMembers,
                                    getOwners: getOwners,
                                    getOnlineMemberCount: getOnlineMemberCount,
                                  ),
                                ),
                              );
                            },
                            child: Text('Create Group & Manage'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Group',
                  textEditController: _joinMUCTextController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Last Message Timestamp',
                  textEditController: _joinTimeController,
                ),
                SizedBox(
                  height: 10,
                ),
                Builder(
                  builder: (context) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            _joinGroup(
                                context,
                                "${_joinMUCTextController.text}",
                                "${_joinTimeController.text}");
                          },
                          child: Text('Join Group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            _joinGroup(
                                context,
                                "${_joinMUCTextController.text}",
                                "${_joinTimeController.text}",
                                isManageGroup: true);
                          },
                          child: Text('Join Group & Manage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "To...",
                  textEditController: _toNameController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Message",
                  textEditController: _messageController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Custom Message",
                  textEditController: _custommessageController,
                ),
                SizedBox(
                  height: 10,
                ),
                DropdownButton(
                  value: dropDownValue,
                  icon: Icon(Icons.keyboard_arrow_down),
                  items: items.map(
                    (String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    },
                  ).toList(),
                  onChanged: (val) {
                    setState(
                      () {
                        dropDownValue = val.toString();
                      },
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        int id = DateTime.now().millisecondsSinceEpoch;
                        (dropDownValue == "Chat")
                            ? await flutterXmpp.sendMessageWithType(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                DateTime.now().millisecondsSinceEpoch)
                            : await flutterXmpp.sendGroupMessageWithType(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                DateTime.now().millisecondsSinceEpoch);
                      },
                      child: Text(" Send "),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (dropDownValue == "Chat")
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        int id = DateTime.now().millisecondsSinceEpoch;
                        (dropDownValue == "Chat")
                            ? await flutterXmpp.sendCustomMessage(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                "${_custommessageController.text}",
                                DateTime.now().millisecondsSinceEpoch)
                            : await flutterXmpp.sendCustomGroupMessage(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                "${_custommessageController.text}",
                                DateTime.now().millisecondsSinceEpoch);
                      },
                      child: Text(" Send Custom Message "),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (dropDownValue == "Chat")
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "To",
                  textEditController: _toReceiptController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Message Id",
                  textEditController: _msgIdController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Receipt Id",
                  textEditController: _receiptIdController,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await flutterXmpp.sendDelieveryReceipt(
                          "${_toReceiptController.text}",
                          "${_msgIdController.text}",
                          "${_receiptIdController.text}",
                        );
                      },
                      child: Text(" Send Delivery Receipt "),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await flutterXmpp.sendReadReceipt(
                          "${_toReceiptController.text}",
                          "${_msgIdController.text}",
                          "${_receiptIdController.text}",
                        );
                      },
                      child: Text(" Send Read Receipt "),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "User Jid",
                  textEditController: _userJidController,
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    String lastSeenTime =
                        await flutterXmpp.getLastSeen(_userJidController.text);
                    print('lastSeen lastSeenTime: $lastSeenTime');
                    if (lastSeenTime.isNotEmpty) {
                      int last = int.parse(lastSeenTime);

                      if (last < Constants.RESULT_EMPTY) {
                        // online
                      } else if (last > Constants.RESULT_EMPTY) {
                        // not online but need to pass time
                        //DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(last);
                      } else {
                        // away
                      }
                    } else {
                      // away
                    }
                  },
                  child: Text("Get Last activity"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var rosters = await flutterXmpp.getMyRosters();
                    print('MyRosters: $rosters');
                    if (_scaffoldKey.currentContext != null) {
                      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                        SnackBar(
                          content: Text('Rosters retrieved. Check logs for details.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(" Get MyRosters "),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Create Single Roster:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "User JID (for single roster)",
                  textEditController: _createRostersController,
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_createRostersController.text.isNotEmpty) {
                      await flutterXmpp.createRoster(
                          _createRostersController.text, 
                          _userNameController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Single roster created: ${_createRostersController.text}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Create Single Roster"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Create Multiple Rosters:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "JIDs (comma separated) e.g. user1@host,user2@host",
                  textEditController: _createRostersListController,
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "Names (comma separated) e.g. User1,User2",
                  textEditController: _createRostersNameController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_createRostersListController.text.isNotEmpty &&
                        _createRostersNameController.text.isNotEmpty) {
                      List<String> jids = _createRostersListController.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                      List<String> names = _createRostersNameController.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                      
                      if (jids.length == names.length) {
                        List<Map<String, String>> rosters = [];
                        for (int i = 0; i < jids.length; i++) {
                          rosters.add({
                            "user_jid": jids[i],
                            "name": names[i],
                          });
                        }
                        await flutterXmpp.createRosters(rosters);
                        if (_scaffoldKey.currentContext != null) {
                          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                            SnackBar(
                              content: Text('${rosters.length} rosters created'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        if (_scaffoldKey.currentContext != null) {
                          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                            SnackBar(
                              content: Text('Number of JIDs and Names must match'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text("Create Multiple Rosters"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Delete Roster:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "User JID to delete",
                  textEditController: _deleteRosterController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_deleteRosterController.text.isNotEmpty) {
                      await flutterXmpp.deleteRoster(_deleteRosterController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Roster deleted: ${_deleteRosterController.text}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Delete Roster"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Get Presence Status:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "User JID for presence status",
                  textEditController: _presenceStatusController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_presenceStatusController.text.isNotEmpty) {
                      Map<String, String>? presenceStatus = 
                          await flutterXmpp.getPresenceStatus(_presenceStatusController.text);
                      if (_scaffoldKey.currentContext != null) {
                        if (presenceStatus != null) {
                          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Presence: Type=${presenceStatus['presenceType']}, '
                                'Mode=${presenceStatus['presenceMode']}',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                            SnackBar(
                              content: Text('Presence status not available'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text("Get Presence Status"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Subscription Requests:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "User JID to send subscription request",
                  textEditController: _sendSubscriptionController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_sendSubscriptionController.text.isNotEmpty) {
                      await flutterXmpp.sendSubscriptionRequest(_sendSubscriptionController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Subscription request sent to: ${_sendSubscriptionController.text}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Send Subscription Request"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                ),
                SizedBox(
                  height: 15,
                ),
                customTextField(
                  hintText: "User JID to accept subscription request",
                  textEditController: _acceptSubscriptionController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_acceptSubscriptionController.text.isNotEmpty) {
                      await flutterXmpp.acceptSubscriptionRequest(_acceptSubscriptionController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Subscription request accepted from: ${_acceptSubscriptionController.text}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Accept Subscription Request"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal),
                ),
                SizedBox(
                  height: 15,
                ),
                customTextField(
                  hintText: "User JID to reject subscription request",
                  textEditController: _rejectSubscriptionController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_rejectSubscriptionController.text.isNotEmpty) {
                      await flutterXmpp.rejectSubscriptionRequest(_rejectSubscriptionController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Subscription request rejected from: ${_rejectSubscriptionController.text}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Reject Subscription Request"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Request Presence Probe:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                customTextField(
                  hintText: "User JID to probe presence",
                  textEditController: _presenceProbeController,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_presenceProbeController.text.isNotEmpty) {
                      await flutterXmpp.requestPresenceProbe(_presenceProbeController.text);
                      if (_scaffoldKey.currentContext != null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                          SnackBar(
                            content: Text('Presence probe sent to: ${_presenceProbeController.text}. Check onPresenceChange for response.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("Request Presence Probe"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple),
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await flutterXmpp.currentState();
                  },
                  child: Text("Current State"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black),
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  height: 500,
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) => _buildMessage(index),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildMessage(int index) {
    MessageChat event = events[index];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "from: ${event.from}",
          ),
          Text(
            "id: ${event.id}",
          ),
          Text(
            "Type: ${event.type}",
          ),
          Text(
            "message: ${event.body}",
          ),
          Text(
            "msgtype: ${event.msgtype}",
          ),
          Text(
            "customText: ${event.customText}",
          ),
          // Text(
          //   "PresenceMode: ${event.presenceMode}",
          // ),
          // Text(
          //   "PresenceType: ${event.presenceType}",
          // ),
          Divider(
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  createMUC(String groupName, bool persistent) async {
    bool groupResponse = await flutterXmpp.createMUC(groupName, persistent);
    print('responseTest groupResponse $groupResponse');
  }

  void _joinGroup(BuildContext context, String grouname, String time,
      {bool isManageGroup = false}) async {
    bool response = await joinMucGroup("$grouname,$time");
    print("responseTest joinResponse $response");
    if (response && isManageGroup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            groupName: grouname,
            addMembersInGroup: addMembersInGroup,
            addAdminsInGroup: addAdminsInGroup,
            removeMember: removeMember,
            removeAdmin: removeAdmin,
            addOwner: addOwner,
            removeOwner: removeOwner,
            getAdmins: getAdmins,
            getMembers: getMembers,
            getOwners: getOwners,
            getOnlineMemberCount: getOnlineMemberCount,
          ),
        ),
      );
    }
  }

  void _showConnectionStatus() async {
    try {
      XmppConnectionState connectionStatus =
          await flutterXmpp.getConnectionStatus();
      if (_scaffoldKey.currentContext != null) {
        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(new SnackBar(
          content: new Text('${connectionStatus.toString()}'),
          duration: Duration(milliseconds: 700),
        ));
      }
    } catch (e) {
      print(e);
    }
  }
}

Widget customTextField({
  TextEditingController? textEditController,
  String? hintText,
  bool addKey = false,
}) {
  return TextField(
    key: addKey ? Key(hintText!) : null,
    autocorrect: false,
    controller: textEditController,
    cursorColor: Colors.black,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 16,
        color: Colors.grey.withOpacity(0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(5.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      ),
    ),
    style: TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    ),
  );
}
