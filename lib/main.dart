import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
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

class SearchResult {
  final String testament;
  final String book;
  final String chapter;
  final String verse;
  final String text;

  SearchResult({
    required this.testament,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });
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

  @override
  void dispose() {
    bookController.dispose();
    chapterController.dispose();
    verseController.dispose();
    super.dispose();
  }
  String normalizeSearchText(String value) {
    return value
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .replaceAll('장', '')
        .replaceAll('절', '')
        .toLowerCase()
        .trim();
  }


  List<SearchResult> searchBible(String keyword) {
    final results = <SearchResult>[];

    if (keyword.trim().isEmpty) return results;

    bible.forEach((testament, booksMap) {
      (booksMap as Map<String, dynamic>).forEach((book, chaptersMap) {
        (chaptersMap as Map<String, dynamic>).forEach((chapter, versesMap) {
          (versesMap as Map<String, dynamic>).forEach((verse, text) {
            (versesMap as Map<String, dynamic>).forEach((verse, text) {
              final verseText = text.toString();

              final normalizedKeyword = normalizeSearchText(keyword);
              final normalVerseText = normalizeSearchText(verseText);
              final normalBook = normalizeSearchText(book);

              final ref1 = normalizeSearchText('$book $chapter장 $verse절');
              final ref2 = normalizeSearchText('$book $chapter:$verse');
              final ref3 = normalizeSearchText('$book$chapter$verse');

              if (normalVerseText.contains(normalizedKeyword) ||
                  normalBook.contains(normalizedKeyword) ||
                  ref1.contains(normalizedKeyword) ||
                  ref2.contains(normalizedKeyword) ||
                  ref3.contains(normalizedKeyword)) {
                results.add(
                  SearchResult(
                    testament: testament,
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    text: verseText,
                  ),
                );
              }
            });
          });
        });
      });
    });

    return results;
  }

void moveToVerse(SearchResult result) {
  final bookList = bible[result.testament].keys.cast<String>().toList();
  final chapterList = sortedKeys(bible[result.testament][result.book]);
  final verseList =
      sortedKeys(bible[result.testament][result.book][result.chapter]);

  final bookIndex = bookList.indexOf(result.book);
  final chapterIndex = chapterList.indexOf(result.chapter);
  final verseIndex = verseList.indexOf(result.verse);

  setState(() {
    selectedTestament = result.testament;
    selectedBook = result.book;
    selectedChapter = result.chapter;
    selectedVerse = result.verse;
  });

  if (bookIndex >= 0) bookController.jumpToItem(bookIndex);
  if (chapterIndex >= 0) chapterController.jumpToItem(chapterIndex);
  if (verseIndex >= 0) verseController.jumpToItem(verseIndex);
}

void openSearchDialog() {
  final searchController = TextEditingController();
  List<SearchResult> results = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('성경 검색'),
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '예: 태초, 사랑, 요한복음 3:16',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        results = searchBible(value.trim());
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: results.isEmpty
                        ? const Center(child: Text('검색어를 입력하세요.'))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final result = results[index];

                              return ListTile(
                                title: Text(
                                  '${result.book} ${result.chapter}장 ${result.verse}절',
                                  style: GoogleFonts.notoSansKr(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  result.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSerifKr(),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  moveToVerse(result);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  Future<void> loadBible() async {
    final jsonString = await rootBundle.loadString('assets/bible.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final firstBook = data[selectedTestament].keys.first;
    final firstChapter = sortedKeys(data[selectedTestament][firstBook]).first;
    final firstVerse =
        sortedKeys(data[selectedTestament][firstBook][firstChapter]).first;

    setState(() {
      bible = data;
      selectedBook = firstBook;
      selectedChapter = firstChapter;
      selectedVerse = firstVerse;
    });
  }

  List<String> sortedKeys(dynamic map) {
    final list = (map as Map<String, dynamic>).keys.cast<String>().toList();
    list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  List<String> get books {
    if (bible.isEmpty) return [];
    return bible[selectedTestament].keys.cast<String>().toList();
  }

  List<String> get chapters {
    if (bible.isEmpty || selectedBook.isEmpty) return [];
    return sortedKeys(bible[selectedTestament][selectedBook]);
  }

  List<String> get verses {
    if (bible.isEmpty || selectedBook.isEmpty || selectedChapter.isEmpty) {
      return [];
    }
    return sortedKeys(bible[selectedTestament][selectedBook][selectedChapter]);
  }

  String get verseText {
    if (bible.isEmpty ||
        selectedBook.isEmpty ||
        selectedChapter.isEmpty ||
        selectedVerse.isEmpty) {
      return '';
    }

    return bible[selectedTestament][selectedBook][selectedChapter]
            [selectedVerse] ??
        '본문 데이터가 없습니다.';
  }

  void changeTestament(String testament) {
    if (testament == selectedTestament) return;

    final firstBook = bible[testament].keys.first;
    final firstChapter = sortedKeys(bible[testament][firstBook]).first;
    final firstVerse =
        sortedKeys(bible[testament][firstBook][firstChapter]).first;

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
    final firstChapter = sortedKeys(bible[selectedTestament][book]).first;
    final firstVerse =
        sortedKeys(bible[selectedTestament][book][firstChapter]).first;

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
    final firstVerse =
        sortedKeys(bible[selectedTestament][selectedBook][chapter]).first;

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

  Widget testamentMenu() {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.menu_rounded, size: 32),
    onSelected: changeTestament,
    itemBuilder: (context) => [
      PopupMenuItem(
        value: '구약',
        child: Row(
          children: [
            if (selectedTestament == '구약')
              const Icon(Icons.check_rounded, size: 20),
            if (selectedTestament != '구약')
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            const Text('구약'),
          ],
        ),
      ),
      PopupMenuItem(
        value: '신약',
        child: Row(
          children: [
            if (selectedTestament == '신약')
              const Icon(Icons.check_rounded, size: 20),
            if (selectedTestament != '신약')
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            const Text('신약'),
          ],
        ),
      ),
    ],
  );
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
        itemExtent: 50,
        diameterRatio: 1.4,
        magnification: 1.12,
        useMagnifier: true,
        squeeze: 1.0,
        looping: items.length > 3,
        onSelectedItemChanged: onChanged,
        selectionOverlay: const SizedBox.shrink(),
        children: items.map((item) {
          return Center(
            child: Text(
              labelBuilder(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansKr(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF444444),                
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget verticalDivider() {
    return Container(
      width: 1,
      height: 120,
      color: Colors.black.withOpacity(0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bible.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  testamentMenu(),
                  const Spacer(),
                  IconButton(
                    onPressed: openSearchDialog,
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 185,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        height: 46,
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Colors.black.withOpacity(0.14),
                              width: 1.2,
                            ),
                          ),
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
                        verticalDivider(),
                        wheelPicker(
                          controller: chapterController,
                          items: chapters,
                          labelBuilder: (value) => '$value장',
                          onChanged: changeChapter,
                          flex: 1,
                        ),
                        verticalDivider(),
                        wheelPicker(
                          controller: verseController,
                          items: verses,
                          labelBuilder: (value) => '$value절',
                          onChanged: changeVerse,
                          flex: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedBook $selectedChapter장 $selectedVerse절',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF444444),
                        ),
                      ),
                      const Divider(height: 34),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            verseText,
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 21,
                              height: 1.9,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF444444),
                              letterSpacing: -0.1,
                            ),
                          ),
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