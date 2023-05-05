import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';


void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? id;
  String screenId ="";
  //1e21124 a80124 5dfa124
  Map player_money = {'1e21124':10000, 'a80124':10000,'5dfa124':10000};

  final _inputMoneyEditController = TextEditingController();


  //NFC 카드의 id 가져오는 함수
  void _handleTag(NfcTag tag){
    try{
      final List<int> tempIntList;
      tempIntList = List<int>.from(Ndef.from(tag)?.additionalData["identifier"]);
      String tempId = "";
      tempIntList.forEach((element) {
        tempId = tempId + element.toRadixString(16);
      });
      id = tempId;
      print("id: $id tempId : $tempId");
    }catch(e){
      throw "NFC 데이터를 가져올 수 없습니다.";
    }
  }

  //NFC 기능체크
  void _nfcCheck(BuildContext context ) async {
    if(!(await NfcManager.instance.isAvailable())){
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("오류"),
            content: Text("NFC를 지원하지 않는 기기이거나 비활성화 되어 있습니다.",
                       style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            actions: <Widget>[
              TextButton(
              onPressed: ()=>Navigator.of(context).pop(),
              child: Text("확인"),
            )],
          )
      );
    }
/*
    showDialog(context: context,
        builder: (BuildContext context){
          return AlertDialog(
            content: Text("NFC가 사용가능합니다."),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("확인"))
            ],
          );
        });

 */
    return;
  }

  //스캔팝업
  void scanId(BuildContext context) async {
    await showDialog(
      context: context
      , builder: (context) => _AndroidSessionDialog("카드를 스캔하세요!", _handleTag),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputMoneyEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
        appBar: AppBar(title: Text('모노폴리 계산기')),
        body:
            Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        _nfcCheck(context);
                        scanId(context);
                        setState(() {
                          screenId = id ?? "";
                        });
                      },
                      child: Text("스캔"),
                    ),
                    Text("ScanID : $screenId"),
                    Text("잔액 : ${player_money[id] ?? 0} "),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(labelText: '금액',),
                  controller: _inputMoneyEditController,
                ),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: (){
                          setState(() {
                            player_money[id] = player_money[id] + int.parse(_inputMoneyEditController.text.toString());
                          });
                        },
                        child: Text("입금")
                    ),
                    ElevatedButton(
                        onPressed: (){
                          setState(() {
                            player_money[id] = player_money[id] - int.parse(_inputMoneyEditController.text.toString());
                          });
                        },
                        child: Text("지급")
                    ),
                  ],
                )
              ],
            )

        );
  }
}

class _AndroidSessionDialog extends StatefulWidget {
  final String alertMessage;
  final void Function(NfcTag tag) handleTag;
  const _AndroidSessionDialog(this.alertMessage, this.handleTag);


  @override
  State<StatefulWidget> createState() => _AndroidSessionDialogState();

}

class _AndroidSessionDialogState extends State<_AndroidSessionDialog>{
  String? _alertMessage;
  String? _errorMessage;
  String? _result;

  @override
  void initState() {
    super.initState();
    
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
          widget.handleTag(tag);
        await NfcManager.instance.stopSession();
        setState(() {
          _alertMessage = "NFC 태그를 인식하였습니다.";
        });
      }catch(e){
        await NfcManager.instance.stopSession();
        setState(() {
          _errorMessage = "$e";
        });
      }
    }).catchError((e) => setState(() => _errorMessage = "$e"));
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _errorMessage?.isNotEmpty == true ? "오류"
            : _alertMessage?.isNotEmpty == true ? "성공"
            : "준비",
      ),
      content: Text(
        _errorMessage?.isNotEmpty == true ? _errorMessage!
            : _alertMessage?.isNotEmpty == true ? _alertMessage!
            : widget.alertMessage,
        ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _errorMessage?.isNotEmpty == true ? "확인"
                  : _alertMessage?.isNotEmpty == true ? "완료"
                  : "취소",
            )
        )
      ],
      );
  }
}