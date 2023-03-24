import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //是否建立起连接
  bool isConnected = false;

  //是否可以发送信息
  bool isCanSend = true;

  //socket
  late Socket socket;

  //接收到的信息
  String receivedData = '无响应';
  static const defaultSendData = '你好，世界';

  //要发送的信息
  String sendData = defaultSendData;

  //主机地址和端口
  static const defaultHost = '192.168.0.205';
  static const defaultPort = 1134;
  String host = defaultHost;
  int port = defaultPort;

  //图表数据列表
  List<Map<String, dynamic>> drDataList = [];
  List<Map<String, dynamic>> spDataList = [];
  List<Map<String, dynamic>> hrDataList = [];
  List<FlSpot> drSpotList = [
    const FlSpot(1, 75),
    const FlSpot(2, 78),
    const FlSpot(3, 76),
    const FlSpot(4, 75),
    const FlSpot(5, 78),
  ];

  List<FlSpot> spSpotList = [
    const FlSpot(1, 65),
    const FlSpot(2, 68),
    const FlSpot(3, 66),
    const FlSpot(4, 65),
    const FlSpot(5, 68),
  ];

  List<FlSpot> hrSpotList = [
    const FlSpot(1, 65),
    const FlSpot(2, 68),
    const FlSpot(3, 66),
    const FlSpot(4, 65),
    const FlSpot(5, 68),
  ];

  //发送的数据
  double sendDp = 0;
  double sendSp = 0;
  double sendHr = 0;

  //数据范围选择
  int preNum = 1;
  int afterNum = 6;

  //发送信息到服务端
  Future<void> sendToPeer(String data) async {
    isCanSend = false;
    socket.write(data);
    await socket.flush().onError((error, stackTrace) => {debugPrint(error.toString())});
    isCanSend = true;
  }

  //监听数据流
  Future<void> dataListener() async {
    socket.listen((event) {
      String data = utf8.decode(event);
      setState(() {
        //处理数据
        receivedData = data;
        DateTime now = DateTime.now();
        List<String> values = receivedData.split(',');
        for (String value in values) {
          String key = value.split(':')[0];
          double data = double.parse(value.split(':')[1]);
          if (key == 's') {
            Map<String, dynamic> newData = {'data': data, 'time': now.toString()};
            spDataList.add(newData);
          } else if (key == 'h') {
            Map<String, dynamic> newData = {'data': data, 'time': now.toString()};
            hrDataList.add(newData);
          } else if (key == 'd') {
            Map<String, dynamic> newData = {'data': data, 'time': now.toString()};
            drDataList.add(newData);
          }
        }

        print(drDataList.toString());
        print(spDataList.toString());
        print(hrDataList.toString());

        if (receivedData != '无响应') {}
      });
    });
  }

  //建立tcp链接
  void tcpConnect() async {
    socket = await Socket.connect(host, port);
    setState(() {
      isConnected = true;
    });
    dataListener();
  }

  //关闭tcp链接
  void tcpCloseConnect() async {
    await socket.close();
    setState(() {
      isConnected = false;
    });
  }

  //数据序列化
  void saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //抽象
    void _saveDataList(String key, List<Map<String, dynamic>> dataList) async {
      if (dataList.isNotEmpty) {
        List<String> jsonStringList = dataList.map((e) => json.encode(e)).toList();
        await prefs.setStringList(key, jsonStringList);
      }
    }

    // 调用
    _saveDataList("drDataJsonList", drDataList);
    _saveDataList("spDataJsonList", spDataList);
    _saveDataList("hrDataJsonList", hrDataList);
  }

  //数据反序列化
  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //抽象
    List<Map<String, dynamic>> getDataListFromPrefs(String key) {
      if (prefs.containsKey(key)) {
        List<String> jsonList = prefs.getStringList(key) ?? [];
        return jsonList.map((e) => json.decode(e)).toList().cast<Map<String, dynamic>>();
      }
      return [];
    }

    // 调用
    drDataList = getDataListFromPrefs('drDataJsonList');
    spDataList = getDataListFromPrefs('spDataJsonList');
    hrDataList = getDataListFromPrefs('hrDataJsonList');
    setState(() {});
  }

  //清空数据
  void clearData() async {
    setState(() {
      drDataList = [];
      spDataList = [];
      hrDataList = [];

      drSpotList = [
        const FlSpot(1, 0),
        const FlSpot(2, 0),
        const FlSpot(3, 0),
        const FlSpot(4, 0),
        const FlSpot(5, 0),
      ];

      spSpotList = [
        const FlSpot(1, 0),
        const FlSpot(2, 0),
        const FlSpot(3, 0),
        const FlSpot(4, 0),
        const FlSpot(5, 0),
      ];

      hrSpotList = [
        const FlSpot(1, 0),
        const FlSpot(2, 0),
        const FlSpot(3, 0),
        const FlSpot(4, 0),
        const FlSpot(5, 0),
      ];
    });
  }

  //ui绘制
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("TCP控制器"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLinkedArea(),
            Row(),
            _buildCheckArea(),
            const SizedBox(height: 20),
            _buildDropDownButton(),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              ElevatedButton(onPressed: saveData, child: Text('保存数据')),
              SizedBox(width: 10),
              ElevatedButton(onPressed: loadData, child: Text('读取数据')),
              SizedBox(width: 10),
              ElevatedButton(onPressed: clearData, child: Text('清空数据')),
            ]),
            const SizedBox(height: 20),
            _buildLineChartOne(),
            const SizedBox(height: 20),
            _buildLineChartTwo(),
          ],
        ),
      ),
    );
  }

  //下拉菜单
  Widget _buildDropDownButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "数据选择",
          style: TextStyle(fontSize: 20),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          width: 200,
          height: 30,
          child: DropdownButton(
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('最近5条数据'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('最近第5-第10条数据'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('最近第10-第15条数据'),
                ),
              ],
              onChanged: (value) {
                if (value == 1 && drDataList.length >= 5) {
                  preNum = 1;
                  afterNum = 6;
                } else if (value == 2 && drDataList.length >= 10) {
                  preNum = 6;
                  afterNum = 10;
                } else if (value == 3 && drDataList.length >= 15) {
                  preNum = 10;
                  afterNum = 14;
                }
                setState(() {});
              }),
        ),
      ],
    );
  }

  //连接模块ui
  Widget _buildLinkedArea() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: Column(
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "主机地址",
                  hintText: "默认：$defaultHost",
                ),
                onChanged: (e) => {
                  setState(() {
                    host = e;
                  })
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "端口", hintText: "默认：$defaultPort"),
                onChanged: (e) => {
                  setState(() {
                    port = int.parse(e);
                  })
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
            onPressed: !isConnected ? tcpConnect : tcpCloseConnect,
            child: !isConnected ? const Text('建立连接') : const Text('断开连接')),
      ],
    );
  }

  //生成折线图数据
  List<FlSpot>? generateSpotList(List<Map<String, dynamic>> dataList) {
    if (dataList.length >= 5) {
      List temp = dataList.sublist(dataList.length - afterNum, dataList.length - preNum);
      return temp.mapIndexed((index, element) {
        return FlSpot(index.toDouble(), element['data'].toDouble());
      }).toList();
    }
    return null;
  }

  //生成折线图底下标题
  Widget myBottomTitle(double value, TitleMeta meta) {
    String getBottomLineTitle(List temp, int i) {
      return temp[i]['time'].split(' ')[1].split('.')[0] + '\n' + temp[i]['time'].split(' ')[0];
    }

    const style = TextStyle(
      fontSize: 12,
    );
    List temp = [];
    String text = '00';
    if (drDataList.length >= 5) {
      temp = drDataList.sublist(drDataList.length - afterNum, drDataList.length - preNum);


      switch (value.toInt()) {
        case 0:
          text = getBottomLineTitle(temp, 0);
          break;
        case 1:
          text = getBottomLineTitle(temp, 1);
          break;
        case 2:
          text = getBottomLineTitle(temp, 2);
          break;
        case 3:
          text = getBottomLineTitle(temp, 3);
          break;
        case 4:
          text = getBottomLineTitle(temp, 4);
          break;
        default:
          text = '000';
      }
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  //折线图1 ui
  Widget _buildLineChartOne() {
    drSpotList = generateSpotList(drDataList) ?? drSpotList;
    spSpotList = generateSpotList(spDataList) ?? spSpotList;
    return Column(
      children: [
        const Text(
          "高压&低压图",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 200,
          width: 400,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, interval: 1, reservedSize: 64, getTitlesWidget: myBottomTitle)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, interval: 0.5, reservedSize: 44))),
              lineBarsData: [
                LineChartBarData(
                  isCurved: false,
                  color: Colors.red,
                  barWidth: 4,
                  spots: drSpotList,
                ),
                LineChartBarData(isCurved: false, barWidth: 4, spots: spSpotList),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //折线图2 ui
  Widget _buildLineChartTwo() {
    hrSpotList = generateSpotList(hrDataList) ?? hrSpotList;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "心率图",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
            height: 200,
            width: 400,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 44,
                    )),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true, interval: 1, reservedSize: 64, getTitlesWidget: myBottomTitle))),
                lineBarsData: [
                  LineChartBarData(isCurved: false, color: Colors.red, barWidth: 4, spots: hrSpotList),
                ],
              ),
            )),
      ],
    );
  }

  //测量与校验区域ui
  Widget _buildCheckArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "低压"),
                    onChanged: (e) {
                      setState(() {
                        sendDp = e as double;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "高压"),
                    onChanged: (e) {
                      setState(() {
                        sendSp = e as double;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "心率"),
                    onChanged: (e) {
                      setState(() {
                        sendHr = e as double;
                      });
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                sendToPeer("s:$sendSp,d:$sendDp,h:$sendHr\r\n");
              },
              label: const Text("校验"),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
          width: 200,
          height: 100,
          child: ElevatedButton.icon(
            onPressed: () {
              sendToPeer("m\r\n");
            },
            label: const Text("测量"),
            icon: const Icon(Icons.change_circle),
          ),
        ),
      ],
    );
  }
}
