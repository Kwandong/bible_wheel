import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BibleWheelPage(),
    );
  }
}

class BibleBook {
  final String name;
  final String testament;
  final Map<int, Map<int, String>> chapters;

  const BibleBook({
    required this.name,
    required this.testament,
    required this.chapters,
  });
}

class BibleWheelPage extends StatefulWidget {
  const BibleWheelPage({super.key});

  @override
  State<BibleWheelPage> createState() => _BibleWheelPageState();
}

class _BibleWheelPageState extends State<BibleWheelPage> {
  String selectedTestament = '구약';
  int selectedBookIndex = 0;
  int selectedChapter = 1;
  int selectedVerse = 1;

  late FixedExtentScrollController bookController;
  late FixedExtentScrollController chapterController;
  late FixedExtentScrollController verseController;

  final List<BibleBook> books = [
    BibleBook(
      name: '창세기',
      testament: '구약',
      chapters: {
        1: {
          1: '태초에 하나님이 천지를 창조하시니라',
          2: '땅이 혼돈하고 공허하며 흑암이 깊음 위에 있고 하나님의 신은 수면에 운행하시니라',
          3: '하나님이 가라사대 빛이 있으라 하시매 빛이 있었고',
        },
        2: {
          1: '천지와 만물이 다 이루니라',
          2: '하나님의 지으시던 일이 일곱째 날이 이를 때에 마치니',
        },
      },
    ),
    BibleBook(
      name: '출애굽기',
      testament: '구약',
      chapters: {
        1: {
          1: '야곱과 함께 각기 권속을 데리고 애굽에 이른 이스라엘 아들들의 이름은 이러하니',
          2: '르우벤과 시므온과 레위와 유다와',
        },
        2: {
          1: '레위 족속 중 한 사람이 가서 레위 여자에게 장가들었더니',
        },
      },
    ),
    BibleBook(
      name: '마태복음',
      testament: '신약',
      chapters: {
        1: {
          1: '아브라함과 다윗의 자손 예수 그리스도의 세계라',
          2: '아브라함이 이삭을 낳고 이삭은 야곱을 낳고',
        },
      },
    ),
    BibleBook(
      name: '요한복음',
      testament: '신약',
      chapters: {
        3: {
          16: '하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니',
        },
      },
    ),
  ];

  List<BibleBook> get filteredBooks =>
      books.where((book) => book.testament == selectedTestament).toList();

  BibleBook get selectedBook => filteredBooks[selectedBookIndex];

  List<int> get chapterNumbers => selectedBook.chapters.keys.toList()..sort();

  List<int> get verseNumbers =>
      selectedBook.chapters[selectedChapter]!.keys.toList()..sort();

  String get selectedText {
    return selectedBook.chapters[selectedChapter]?[selectedVerse] ??
        '본문 데이터가 없습니다.';
  }

  @override
  void initState() {
    super.initState();
    bookController = FixedExtentScrollController();
    chapterController = FixedExtentScrollController();
    verseController = FixedExtentScrollController();
  }

  @override
  void dispose() {
    bookController.dispose();
    chapterController.dispose();
    verseController.dispose();
    super.dispose();
  }

  void changeTestament(String testament) {
    setState(() {
      selectedTestament = testament;
      selectedBookIndex = 0;
      selectedChapter = filteredBooks.first.chapters.keys.first;
      selectedVerse = filteredBooks.first.chapters[selectedChapter]!.keys.first;
    });

    bookController.jumpToItem(0);
    chapterController.jumpToItem(0);
    verseController.jumpToItem(0);
  }

  void updateBook(int index) {
    setState(() {
      selectedBookIndex = index;
      selectedChapter = chapterNumbers.first;
      selectedVerse = verseNumbers.first;
    });

    chapterController.jumpToItem(0);
    verseController.jumpToItem(0);
  }

  void updateChapter(int index) {
    setState(() {
      selectedChapter = chapterNumbers[index];
      selectedVerse = verseNumbers.first;
    });

    verseController.jumpToItem(0);
  }

  void updateVerse(int index) {
    setState(() {
      selectedVerse = verseNumbers[index];
    });
  }

  Widget wheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) labelBuilder,
    required void Function(int index) onSelectedItemChanged,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 42,
      magnification: 1.12,
      useMagnifier: true,
      squeeze: 1.1,
      onSelectedItemChanged: onSelectedItemChanged,
      children: List.generate(
        itemCount,
        (index) => Center(
          child: Text(
            labelBuilder(index),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapters = chapterNumbers;
    final verses = verseNumbers;

    return Scaffold(
      backgroundColor: const Color(0xfff5f3ee),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Bible Wheel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),

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

              const SizedBox(height: 20),

              Container(
                height: 180,
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: wheelPicker(
                        controller: bookController,
                        itemCount: filteredBooks.length,
                        labelBuilder: (index) => filteredBooks[index].name,
                        onSelectedItemChanged: updateBook,
                      ),
                    ),
                    Expanded(
                      child: wheelPicker(
                        controller: chapterController,
                        itemCount: chapters.length,
                        labelBuilder: (index) => '${chapters[index]}장',
                        onSelectedItemChanged: updateChapter,
                      ),
                    ),
                    Expanded(
                      child: wheelPicker(
                        controller: verseController,
                        itemCount: verses.length,
                        labelBuilder: (index) => '${verses[index]}절',
                        onSelectedItemChanged: updateVerse,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'ENTER',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedBook.name} $selectedChapter:$selectedVerse',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 32),
                      Text(
                        selectedText,
                        style: const TextStyle(
                          fontSize: 26,
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