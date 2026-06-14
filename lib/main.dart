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

  String expandBibleAbbreviation(String keyword) {
  final input = normalizeSearchText(keyword);

  final aliases = {
    '창': '창세기',
    '출': '출애굽기',
    '레': '레위기',
    '민': '민수기',
    '신': '신명기',
    '마': '마태복음',
    '막': '마가복음',
    '눅': '누가복음',
    '요': '요한복음',
    '행': '사도행전',
    '롬': '로마서',
    '고전': '고린도전서',
    '고후': '고린도후서',
    '갈': '갈라디아서',
    '엡': '에베소서',
    '빌': '빌립보서',
    '골': '골로새서',
    '살전': '데살로니가전서',
    '살후': '데살로니가후서',
    '딤전': '디모데전서',
    '딤후': '디모데후서',
    '딛': '디도서',
    '몬': '빌레몬서',
    '히': '히브리서',
    '약': '야고보서',
    '벧전': '베드로전서',
    '벧후': '베드로후서',
    '요일': '요한일서',
    '요이': '요한이서',
    '요삼': '요한삼서',
    '유': '유다서',
    '계': '요한계시록',
  };

  for (final entry in aliases.entries) {
    if (input.startsWith(entry.key)) {
      return input.replaceFirst(
        entry.key,
        normalizeSearchText(entry.value),
      );
    }
  }

  return input;
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
              final expandedKeyword = expandBibleAbbreviation(keyword);
              final normalVerseText = normalizeSearchText(verseText);
              final normalBook = normalizeSearchText(book);

              final ref1 = normalizeSearchText('$book $chapter장 $verse절');
              final ref2 = normalizeSearchText('$book $chapter:$verse');
              final ref3 = normalizeSearchText('$book$chapter$verse');

              if (normalVerseText.contains(normalizedKeyword) ||
                  normalVerseText.contains(expandedKeyword) ||

                  normalBook.contains(normalizedKeyword) ||
                  normalBook.contains(expandedKeyword) ||

                  ref1.contains(normalizedKeyword) ||
                  ref1.contains(expandedKeyword) ||

                  ref2.contains(normalizedKeyword) ||
                  ref2.contains(expandedKeyword) ||

                  ref3.contains(normalizedKeyword) ||
                  ref3.contains(expandedKeyword)) {
                
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
  return IconButton(
    icon: const Icon(
      Icons.menu_rounded,
      size: 34,
      color: Color(0xFF333333),
    ),
    onPressed: openMainMenu,
  );
}

void openMainMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (context) {
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Text(
                  'Bible Wheel',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            menuRow(
              title: '구약',
              checked: selectedTestament == '구약',
              onTap: () {
                Navigator.pop(context);
                changeTestament('구약');
              },
            ),
            menuRow(
              title: '신약',
              checked: selectedTestament == '신약',
              onTap: () {
                Navigator.pop(context);
                changeTestament('신약');
              },
            ),

            const Divider(height: 18),

            menuRow(
              icon: Icons.star_border_rounded,
              title: '즐겨찾기',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('즐겨찾기는 다음 버전에서 추가합니다.')),
                );
              },
            ),
            menuRow(
              icon: Icons.history_rounded,
              title: '최근 본 말씀',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('최근 본 말씀은 다음 버전에서 추가합니다.')),
                );
              },
            ),
            menuRow(
              icon: Icons.info_outline_rounded,
              title: '정보',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bible Wheel v0.6')),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget menuRow({
  IconData? icon,
  required String title,
  required VoidCallback onTap,
  bool checked = false,
}) {
  return ListTile(
    dense: true,
    visualDensity: const VisualDensity(vertical: -2),
    contentPadding: EdgeInsets.zero,
    minLeadingWidth: 28,
    leading: icon != null
        ? Icon(
            icon,
            size: 22,
            color: const Color(0xFF555555),
          )
        : Icon(
            checked
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 21,
            color: const Color(0xFF555555),
          ),
    title: Text(
      title,
      style: GoogleFonts.notoSansKr(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF333333),
      ),
    ),
    trailing: checked && icon != null
        ? const Icon(
            Icons.check_rounded,
            size: 20,
            color: Color(0xFF555555),
          )
        : null,
    onTap: onTap,
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