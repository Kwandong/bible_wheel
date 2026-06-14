import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BibleWheelApp());
}

class BibleWheelApp extends StatelessWidget {
  const BibleWheelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Wheel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BibleWheelPage(),
    );
  }
}

class BibleWheelPage extends StatefulWidget {
  const BibleWheelPage({super.key});

  @override
  State<BibleWheelPage> createState() => _BibleWheelPageState();
}

class _BibleWheelPageState extends State<BibleWheelPage> {
  Map<String, dynamic> bible = {};

  String selectedTestament = '구약';
  String selectedBook = '';
  String selectedChapter = '';
  String selectedVerse = '';

  late FixedExtentScrollController bookController;
  late FixedExtentScrollController chapterController;
  late FixedExtentScrollController verseController;

  @override
  void initState() {
    super.initState();
    bookController = FixedExtentScrollController();
    chapterController = FixedExtentScrollController();
    verseController = FixedExtentScrollController();
    loadBible();
  }

  Future<void> loadBible() async {
    final jsonString = await rootBundle.loadString('assets/bible.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final firstBook = data[selectedTestament].keys.first;
    final firstChapter = data[selectedTestament][firstBook].keys.first;
    final firstVerse = data[selectedTestament][firstBook][firstChapter].keys.first;

    setState(() {
      bible = data;
      selectedBook = firstBook;
      selectedChapter = firstChapter;
      selectedVerse = firstVerse;
    });
  }

  @override
  void dispose() {
    bookController.dispose();
    chapterController.dispose();
    verseController.dispose();
    super.dispose();
  }

  List<String> get books {
    if (bible.isEmpty) return [];
    return bible[selectedTestament].keys.cast<String>().toList();
  }

  List<String> get chapters {
    if (bible.isEmpty || selectedBook.isEmpty) return [];
    final list = bible[selectedTestament][selectedBook].keys.cast<String>().toList();
    list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  List<String> get verses {
    if (bible.isEmpty || selectedBook.isEmpty || selectedChapter.isEmpty) return [];
    final list = bible[selectedTestament][selectedBook][selectedChapter]
        .keys
        .cast<String>()
        .toList();
    list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  String get verseText {
    if (bible.isEmpty ||
        selectedBook.isEmpty ||
        selectedChapter.isEmpty ||
        selectedVerse.isEmpty) {
      return '';
    }

    return bible[selectedTestament][selectedBook][selectedChapter][selectedVerse] ??
        '본문 데이터가 없습니다.';
  }

  void changeTestament(String testament) {
    final firstBook = bible[testament].keys.first;
    final firstChapter = bible[testament][firstBook].keys.first;
    final firstVerse = bible[testament][firstBook][firstChapter].keys.first;

    setState(() {
      selectedTestament = testament;
      selectedBook = firstBook;
      selectedChapter = firstChapter;
      selectedVerse = firstVerse;
    });

    bookController.jumpToItem(0);
    chapterController.jumpToItem(0);
    verseController.jumpToItem(0);
  }

  void changeBook(int index) {
    final book = books[index];
    final firstChapter = bible[selectedTestament][book].keys.first;
    final firstVerse = bible[selectedTestament][book][firstChapter].keys.first;

    setState(() {
      selectedBook = book;
      selectedChapter = firstChapter;
      selectedVerse = firstVerse;
    });

    chapterController.jumpToItem(0);
    verseController.jumpToItem(0);
  }

  void changeChapter(int index) {
    final chapter = chapters[index];
    final firstVerse = bible[selectedTestament][selectedBook][chapter].keys.first;

    setState(() {
      selectedChapter = chapter;
      selectedVerse = firstVerse;
    });

    verseController.jumpToItem(0);
  }

  void changeVerse(int index) {
    setState(() {
      selectedVerse = verses[index];
    });
  }

  Widget wheelPicker({
    required FixedExtentScrollController controller,
    required List<String> items,
    required String Function(String value) labelBuilder,
    required void Function(int index) onChanged,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 44,
        diameterRatio: 1.15,
        magnification: 1.2,
        useMagnifier: true,
        squeeze: 0.9,
        onSelectedItemChanged: onChanged,
        children: items.map((item) {
          return Center(
            child: Text(
              labelBuilder(item),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bible.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f3ee),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '구약', label: Text('구약')),
                  ButtonSegment(value: '신약', label: Text('신약')),
                ],
                selected: {selectedTestament},
                onSelectionChanged: (value) {
                  changeTestament(value.first);
                },
              ),

              const SizedBox(height: 18),

              Container(
                height: 170,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 46,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xffeeeeee),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        wheelPicker(
                          controller: bookController,
                          items: books,
                          labelBuilder: (value) => value,
                          onChanged: changeBook,
                          flex: 2,
                        ),
                        wheelPicker(
                          controller: chapterController,
                          items: chapters,
                          labelBuilder: (value) => '$value장',
                          onChanged: changeChapter,
                        ),
                        wheelPicker(
                          controller: verseController,
                          items: verses,
                          labelBuilder: (value) => '$value절',
                          onChanged: changeVerse,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedBook $selectedChapter장 $selectedVerse절',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 34),
                      Text(
                        verseText,
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}