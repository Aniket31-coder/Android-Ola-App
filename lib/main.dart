import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/qa.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final CollectionReference collection = firestore.collection('QA');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ola App',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [];
  String answer = "";
  List<String> result = [];
  List<QuestionAnswer> _snapshotInfo(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      return QuestionAnswer(
        question: e.get("question") ?? '',
        botAnswer: e.get("botAnswer") ?? '',
      );
    }).toList();
  }

  Stream<List<QuestionAnswer>> get info {
    return collection.snapshots().map(_snapshotInfo);
  }

  @override
  void initState() {
    super.initState();
    // DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
  }

  @override
  Widget build(BuildContext context) {
    var themeValue = MediaQuery.of(context).platformBrightness;
    return StreamBuilder<List<QuestionAnswer>>(
      stream: info,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          List<QuestionAnswer> qanda = snapshot.data!;
          return Scaffold(
            backgroundColor: themeValue == Brightness.dark
                ? HexColor('#262626')
                : HexColor('#E5E5E5'),
            appBar: AppBar(
              backgroundColor: themeValue == Brightness.dark
                  ? HexColor('#A7AF13')
                  : HexColor('#D7DF23'),
              title: Text(
                'Ola App',
                style: TextStyle(
                    color:
                    themeValue == Brightness.dark ? Colors.white54 : Colors.black),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: Body(messages: messages)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: messageController,
                            style: TextStyle(
                                color: themeValue == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontFamily: 'Poppins'),
                            decoration: new InputDecoration(
                              enabledBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: themeValue == Brightness.dark
                                          ? Colors.white
                                          : Colors.black),
                                  borderRadius: BorderRadius.circular(15)),
                              hintStyle: TextStyle(
                                color: themeValue == Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                              ),
                              labelStyle: TextStyle(
                                  color: themeValue == Brightness.dark
                                      ? Colors.white
                                      : Colors.black),
                              hintText: 'Send a message',
                            ),
                          ),
                        ),
                        IconButton(
                          color: themeValue == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          icon: Icon(Icons.send),
                          onPressed: () {
                            sendMessage(messageController.text, qanda);
                            messageController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        else return CircularProgressIndicator();
      }
    );
  }

  void sendMessage(String text, List<QuestionAnswer> ans) async {

    String response = "";
    if (text.isEmpty) return;

    setState(() {
      addMessage(
        Message(text: DialogText(text: [text])),
        true
      );
    });

    for(QuestionAnswer typedtext in ans){
      if(messageController.text == typedtext.question) {
        response = typedtext.botAnswer;
      }
    }

    // DetectIntentResponse response = await dialogFlowtter.detectIntent(
    //   queryInput: QueryInput(text: TextInput(text: text)),
    // );

    if (response == null) return;

    setState(() {
      addMessage(Message(text: DialogText(text: [response])));
    });
  }

  // void getMessage(String text) {
  //   firestore.collection('QA')
  //       .where('question', isEqualTo: text )
  //       .get()
  //       .then((QuerySnapshot doc) =>
  //   {
  //     doc.docs.forEach((doc) {
  //       setState(() {
  //         answer = doc['botAnswer'];
  //       });
  //       //print(answer);
  //       result.add(answer);
  //     })
  //     // for(doc in doc.docs) {
  //     //   ans = doc['botAnswer']
  //     // }
  //   }
  //   );
  //   print(answer);
  // }

  void addMessage(Message message, [bool isUserMessage = false]) {
    messages.add({
      'message': message,
      'isUserMessage': isUserMessage,
    });
  }

  @override
  void dispose() {
    //dialogFlowtter.dispose();
    super.dispose();
  }
}

class Body extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const Body({
    Key? key,
    this.messages = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, i) {
        var obj = messages[messages.length - 1 - i];
        Message message = obj['message'];
        bool isUserMessage = obj['isUserMessage'] ?? false;
        return Row(
          mainAxisAlignment:
          isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MessageContainer(
              message: message,
              isUserMessage: isUserMessage,
            ),
          ],
        );
      },
      separatorBuilder: (_, i) => Container(height: 10),
      itemCount: messages.length,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 20,
      ),
    );
  }
}

class _MessageContainer extends StatelessWidget {
  final Message message;
  final bool isUserMessage;

  const _MessageContainer({
    Key? key,
    required this.message,
    this.isUserMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250),
      child: LayoutBuilder(
        builder: (context, constrains) {
          return Container(
            decoration: BoxDecoration(
              color: isUserMessage ? HexColor('#D7DF23') : Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(10),
            child: Text(
              message.text?.text?[0] ?? '',
              style: TextStyle(
                color: isUserMessage ? Colors.black : Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}