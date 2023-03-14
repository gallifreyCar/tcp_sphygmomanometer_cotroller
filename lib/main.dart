import 'dart:convert';
import 'dart:io';

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
  static const defaultHost = '192.168.0.251';
  static const defaultPort = 1234;
  String host = defaultHost;
  int port = defaultPort;
  //图表数据列表
  List<String>? drDataList;
  List<String>? spDataList;
  List<String>? hrDataList;
  //发送的数据
  double sendDp = 0;
  double sendSp = 0;
  double sendHr = 0;

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
      // print(event);
      String data = utf8.decode(event);

      setState(() {
        receivedData = data;
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
    if (drDataList != null) {
      prefs.setStringList("drDataList", drDataList!);
    }
    if (spDataList != null) {
      prefs.setStringList("spDataList", spDataList!);
    }
    if (hrDataList != null) {
      prefs.setStringList("hrDataList ", hrDataList!);
    }
  }

  //数据反序列化
  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("drDataList") && prefs.containsKey("spDataList") && prefs.containsKey("hrDataList")) {
      drDataList = prefs.getStringList("drDataList");
      spDataList = prefs.getStringList("spDataList");
      hrDataList = prefs.getStringList("hrDataList");
    }
  }

  //ui绘制
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("TCP控制器"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLinkedArea(),
            Row(),
            _buildCheckArea(),
            _buildDropDownButton(),
            _buildLineChartOne(),
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
        const Text("数据选择"),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          width: 200,
          height: 30,
          child: DropdownButton(
              items: const [
                DropdownMenuItem(
                  child: Text('最近5条数据'),
                  value: 1,
                ),
                DropdownMenuItem(
                  child: Text('最近第5-第10条数据'),
                  value: 2,
                ),
                DropdownMenuItem(
                  child: Text('最近第10-第15条数据'),
                  value: 3,
                ),
              ],
              onChanged: (value) {
                print(value);
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
                  hintText: "例：192.168.0.251",
                ),
                onChanged: (e) => {
                  setState(() {
                    host = e;
                  })
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "端口", hintText: "例：1234"),
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

  //折线图1 ui
  Widget _buildLineChartOne() {
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
          height: 180,
          width: 400,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, interval: 0.5, reservedSize: 44))),
              lineBarsData: [
                LineChartBarData(
                  isCurved: false,
                  color: Colors.red,
                  barWidth: 4,
                  spots: [
                    const FlSpot(1, 105),
                    const FlSpot(2, 102),
                    const FlSpot(3, 109),
                    const FlSpot(4, 102),
                    const FlSpot(5, 104)
                  ],
                ),
                LineChartBarData(
                  isCurved: false,
                  barWidth: 4,
                  spots: [
                    const FlSpot(1, 75),
                    const FlSpot(2, 78),
                    const FlSpot(3, 76),
                    const FlSpot(4, 75),
                    const FlSpot(5, 78),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //折线图2 ui
  Widget _buildLineChartTwo() {
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
            height: 140,
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
                      showTitles: true,
                      reservedSize: 44,
                    ))),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 4,
                    spots: [
                      const FlSpot(1, 75),
                      const FlSpot(2, 72),
                      const FlSpot(3, 79),
                      const FlSpot(4, 76),
                      const FlSpot(5, 73)
                    ],
                  ),
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
                sendToPeer("s:$sendSp,d:$sendDp,h:$sendHr");
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
              sendToPeer("m");
            },
            label: const Text("测量"),
            icon: const Icon(Icons.change_circle),
          ),
        ),
      ],
    );
  }
}
