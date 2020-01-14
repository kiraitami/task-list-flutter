import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoController = TextEditingController();

  List _toDoList = [];
  Map <String, dynamic> _lastRemoved;
  int _lastRemovedIndex;


  @override
  void initState() {
    super.initState();
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addTask() {
    setState(() {
      Map<String, dynamic> newTask = Map();
      newTask["title"] = _todoController.text;
      newTask["done"] = false;
      _toDoList.add(newTask);
      _saveData();
      _todoController.clear();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
            if(a["done"] && !b["done"]) return 1;
            else if(!a["done"] && b["done"]) return -1;
            else return 0;
          });
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task List"),
        backgroundColor: Colors.blueGrey,
      ),

      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
            child: Row(
              children: <Widget>[
               Expanded(
                 child:  TextField(
                   controller: _todoController,
                   decoration: InputDecoration(
                       labelText: "New Task",
                       labelStyle: TextStyle(color: Colors.greenAccent)
                   ),
                 ),
               ),

                RaisedButton(
                  color: Colors.greenAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: _addTask,
                )
              ],
            ),
          ),


          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 8.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildTaskItem
              ),
              onRefresh: _refresh,
            )
          )
        ],
      ),
    );
  }

  Widget buildTaskItem (context, index){

    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //<--- GAMBIARRA. O CERTO SERIA UM ID
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.8, 0.0),
          child: Icon(Icons.delete, color: Colors.white)
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["done"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["done"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool checked) {
          setState(() {
            _toDoList[index]["done"] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {

          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Task \"${_lastRemoved["title"]}\" removed"),
            action: SnackBarAction(
                label: "Undo",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedIndex, _lastRemoved);
                    _saveData();
                  });
                }
            ),
            duration: Duration(seconds: 4),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);

        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory  = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async{
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    }
    catch (e){
      return null;
    }
  }
}