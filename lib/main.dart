import 'dart:async'; //Pacote de funções assíncronas
import 'dart:convert'; //Pacote para converter Strings em JSON e vice versa
import 'dart:io'; //para requisições web
import 'package:flutter/material.dart'; //Pacote de widgets material
//Pacote para encontrar o melhor caminho de armazenamento para cada tipo de aparelho
import 'package:path_provider/path_provider.dart'; 

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = []; //Lista de mapas com as tarefas a serem feitas

  //Mapa e int para identificar a posição do card excluído 
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //Lê e transforma o arquivo JSON em uma String
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //Adiciona novas tarefas quando o botão ADD é pressionado
  void addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map(); //Map para a nova tarefa adicionada
      //Adiciona o que está escrito no campo de texto ao "title" do mapa
      newToDo["title"] = _textFieldController.text;
      _textFieldController.text = ""; //Apaga o que está escrito no campo de texto
      newToDo["ok"] = false; //Coloca o campo automaticamente em false, como a tarefa acabou de ser criada
      _toDoList.add(newToDo); //Adiciona o mapa a lista de mapas
      _saveData(); //Chama a função de salvar no arquivo
    });
  }

  //Retorna uma cor diferente se o card foi marcado como feito
  Color _setTextColor(bool ok){
    if(ok) return Colors.grey;  //se foi feito, retorna cinza
    else return Colors.black; //se não foi feito, retorna preto
  }

  //Recarrega e ordena os cards quando a página é rolada para baixo
  Future<Null> _refresh() async {
    //Acrescenta um delay, não é necessário mas da uma estética melhor
    await Future.delayed(Duration(milliseconds: 400)); 
    setState(() {
      //Reordena a lista de cards colocando os que já foram feitos na parte inferior
      _toDoList.sort((card1, card2) {
        if (card1["ok"] && !card2["ok"])
          return 1;
        else if (!card1["ok"] && card2["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  //Text Controller para pegar e alterar os dados do campo de texto
  final _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //App bar
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      //Corpo do app
      body: Column( //Coluna, contendo o campo de texto e add e a lista de cards abaixo
        children: <Widget>[
          Container( //Container para adicionar padding ao campo de texto e add
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 17.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded( //Widget que faz com que os widgets dentro dele ocupem todo o espaço disponível
                  child: TextField( //Campo de texto na parte esquerda
                    controller: _textFieldController, //referindo o controlador 
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                //Botão que adiciona a nova tarefa 
                RaisedButton(
                  textColor: Colors.white,
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  onPressed: () {
                    addToDo();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator( //Widget que adiciona o carregamento quando a tela é puxada para baixo
              onRefresh: _refresh, //Quando puxada para baixo, chama a função asíncrona _refresh()
              child: ListView.builder( //Cria um listview com todos os mapas dentro da lista
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,  //Usa o tamanho da lista como o tanto de cards que serão criados
                  itemBuilder: buildItem), //Cria a lista usando o widget buildItem
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) { //Widget usado para gerar a lista de cards
    return Dismissible( //Widget usado para excluir cards quando arrastados para o lado
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //Gera um key baseada no tempo
      background: Container(  
        color: Colors.red, //Fundo do card quando arrastado para o lado
        child: Align( //Alinha o icone de delete dentro do Dismissible
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd, //Direção em que o card pode ser deslizado
      child: CheckboxListTile( //Cria a lista com checkboxes em cada card
        title: Text(
          _toDoList[index]["title"], //Define o título do card como o valor da chave "title" do mapa
          //Define a cor do texto dependendo se a checkbox está marcada ou não chamando a função _setTextColor();
          //e dando como valor o booleano "ok" do mapa
          style: TextStyle(color: _setTextColor(_toDoList[index]["ok"])), 
        ),
        //Usa como valor booleano para mostrar se a checkbox está marcada ou não o valor da chave "ok" do mapa
        value: _toDoList[index]["ok"],
        //Se a caixa de seleção for marcada, muda o estado de "ok" para true, salva no arquivo e atualiza a página
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      //Quando o card for arrastado para o lado remove da lista de mapas _toDoList, adiciona a outro mapa,
      //que contem os dados do ultimo card excluido, salva a última posição do card
      onDismissed: (direction) { 
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(_lastRemovedPos);
          _saveData();
          //Quando o card é excluído mostra um snack bar especificando qual foi excluido e dando a opção de desfazer
          final snack = SnackBar(
            content: Text("Tarefa '${_lastRemoved["title"]}' removida!"), //Texto da lateral esquerda
            action: SnackBarAction( //Botão que desfaz o deletar
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    //Quando o botão é apertado, o card é inserido na mesma posição em que estava antes
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2), //tempo em que a snackbar fica ativa
          );
          //Se dois cards forem excluidos rapidamente, antes de mostrar a nova snackbar, remove a antiga
          Scaffold.of(context).removeCurrentSnackBar();  
          //Mostra a nova snackbar definida acima
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  //Funcao asincrona que retorna o diretorio de salvamento dos dados
  //usando a biblioteca path provider
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //Função que transforma o conteúdo da sring em um json e salva no dispositivo
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  //função usada para ler o arquivo do dispositivo e lê como uma string
  Future<String> _readData() async {
    //O app tenta ler o arquivo, mas se houver algum erro, retorna null
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
