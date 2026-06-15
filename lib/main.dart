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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9A86A),
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: const BibleWheelPage(),
    );
  }
}

class AppColors {
  static const background = Color(0xFFF7F5EF);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceStrong = Color(0xFFFFFFFF);
  static const text = Color(0xFF3F3A33);
  static const textMuted = Color(0xFF8A8377);
  static const gold = Color(0xFFC9A86A);
  static const goldDark = Color(0xFF8D6B2F);
  static const divider = Color(0xFFE6DED0);
  static const shadow = Color(0x0F4A3720);
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
  bool isProgrammaticMove = false;

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
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('장', '')
        .replaceAll('절', '')
        .toLowerCase()
        .trim();
  }

  String expandBibleAbbreviation(String keyword) {
    final input = normalizeSearchText(keyword);

    final aliases = <String, String>{
      '살전': '데살로니가전서',
      '살후': '데살로니가후서',
      '딤전': '디모데전서',
      '딤후': '디모데후서',
      '벧전': '베드로전서',
      '벧후': '베드로후서',
      '요일': '요한일서',
      '요이': '요한이서',
      '요삼': '요한삼서',
      '고전': '고린도전서',
      '고후': '고린도후서',
      '삼상': '사무엘상',
      '삼하': '사무엘하',
      '왕상': '열왕기상',
      '왕하': '열왕기하',
      '대상': '역대상',
      '대하': '역대하',
      '창': '창세기',
      '출': '출애굽기',
      '레': '레위기',
      '민': '민수기',
      '신': '신명기',
      '수': '여호수아',
      '삿': '사사기',
      '룻': '룻기',
      '스': '에스라',
      '느': '느헤미야',
      '에': '에스더',
      '욥': '욥기',
      '시': '시편',
      '잠': '잠언',
      '전': '전도서',
      '아': '아가',
      '사': '이사야',
      '렘': '예레미야',
      '애': '예레미야애가',
      '겔': '에스겔',
      '단': '다니엘',
      '호': '호세아',
      '욜': '요엘',
      '암': '아모스',
      '옵': '오바댜',
      '욘': '요나',
      '미': '미가',
      '나': '나훔',
      '합': '하박국',
      '습': '스바냐',
      '학': '학개',
      '슥': '스가랴',
      '말': '말라기',
      '마': '마태복음',
      '막': '마가복음',
      '눅': '누가복음',
      '요': '요한복음',
      '행': '사도행전',
      '롬': '로마서',
      '갈': '갈라디아서',
      '엡': '에베소서',
      '빌': '빌립보서',
      '골': '골로새서',
      '딛': '디도서',
      '몬': '빌레몬서',
      '히': '히브리서',
      '약': '야고보서',
      '유': '유다서',
      '계': '요한계시록',
    };

    for (final entry in aliases.entries) {
      if (input.startsWith(entry.key)) {
        return input.replaceFirst(entry.key, normalizeSearchText(entry.value));
      }
    }

    return input;
  }

  String cleanVerseText(String value) {
    var cleaned = value.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^\s*<[^>]+>\s*'), '');
    return cleaned.trim();
  }

  List<SearchResult> directReferenceSearch(String keyword) {
    final raw = keyword.trim();
    if (raw.isEmpty || bible.isEmpty) return [];

    final normalizedRaw = normalizeSearchText(raw);
    final expanded = expandBibleAbbreviation(raw);
    final hasChapterMarker = raw.contains('장');
    final hasVerseMarker = raw.contains('절') || raw.contains(':');

    SearchResult? exactVerseResult(
      String testament,
      String book,
      String chapter,
      String verse,
    ) {
      final chaptersMap = bible[testament][book] as Map<String, dynamic>;
      if (!chaptersMap.containsKey(chapter)) return null;

      final versesMap = chaptersMap[chapter] as Map<String, dynamic>;
      if (!versesMap.containsKey(verse)) return null;

      return SearchResult(
        testament: testament,
        book: book,
        chapter: chapter,
        verse: verse,
        text: cleanVerseText(versesMap[verse].toString()),
      );
    }

    List<SearchResult> chapterResults(
      String testament,
      String book,
      String chapter,
    ) {
      final chaptersMap = bible[testament][book] as Map<String, dynamic>;
      if (!chaptersMap.containsKey(chapter)) return [];

      final versesMap = chaptersMap[chapter] as Map<String, dynamic>;
      return sortedKeys(versesMap)
          .map(
            (verse) => SearchResult(
              testament: testament,
              book: book,
              chapter: chapter,
              verse: verse,
              text: cleanVerseText(versesMap[verse].toString()),
            ),
          )
          .toList();
    }

    for (final testament in bible.keys.cast<String>()) {
      final booksMap = bible[testament] as Map<String, dynamic>;

      for (final book in booksMap.keys.cast<String>()) {
        final normalBook = normalizeSearchText(book);

        String? numberPart;

        if (normalizedRaw.startsWith(normalBook)) {
          numberPart = normalizedRaw.substring(normalBook.length);
        } else if (expanded.startsWith(normalBook)) {
          numberPart = expanded.substring(normalBook.length);
        }

        if (numberPart == null || numberPart.isEmpty) continue;
        if (!RegExp(r'^\d+$').hasMatch(numberPart)) continue;

        final chaptersMap = booksMap[book] as Map<String, dynamic>;

        if (!hasVerseMarker && chaptersMap.containsKey(numberPart)) {
          return chapterResults(testament, book, numberPart).take(10).toList();
        }

        if (hasChapterMarker && !hasVerseMarker) {
          return [];
        }

        final candidates = <SearchResult>[];

        for (var split = 1; split < numberPart.length; split++) {
          final chapter = int.parse(numberPart.substring(0, split)).toString();
          final verse = int.parse(numberPart.substring(split)).toString();

          final found = exactVerseResult(testament, book, chapter, verse);
          if (found != null) {
            candidates.add(found);
          }
        }

        if (candidates.isNotEmpty) {
          candidates.sort((a, b) {
            final chapterCompare =
                int.parse(b.chapter).compareTo(int.parse(a.chapter));
            if (chapterCompare != 0) return chapterCompare;
            return int.parse(b.verse).compareTo(int.parse(a.verse));
          });
          return [candidates.first];
        }
      }
    }

    return [];
  }

  List<SearchResult> searchBible(String keyword) {
    final rawKeyword = keyword.trim();
    final normalizedKeyword = normalizeSearchText(rawKeyword);
    final expandedKeyword = expandBibleAbbreviation(rawKeyword);

    if (normalizedKeyword.length < 2) {
      return [];
    }

    final directResults = directReferenceSearch(rawKeyword);
    if (directResults.isNotEmpty) {
      return directResults.take(10).toList();
    }

    final results = <SearchResult>[];

    bible.forEach((testament, booksMap) {
      (booksMap as Map<String, dynamic>).forEach((book, chaptersMap) {
        final normalBook = normalizeSearchText(book);

        (chaptersMap as Map<String, dynamic>).forEach((chapter, versesMap) {
          (versesMap as Map<String, dynamic>).forEach((verse, text) {
            final verseText = cleanVerseText(text.toString());
            if (verseText.isEmpty) return;
            final normalVerseText = normalizeSearchText(verseText);

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

    results.sort((a, b) {
      final aBook = normalizeSearchText(a.book);
      final bBook = normalizeSearchText(b.book);

      final aScore =
          aBook.contains(normalizedKeyword) || aBook.contains(expandedKeyword)
              ? 0
              : 1;
      final bScore =
          bBook.contains(normalizedKeyword) || bBook.contains(expandedKeyword)
              ? 0
              : 1;

      if (aScore != bScore) {
        return aScore.compareTo(bScore);
      }

      final testamentCompare = a.testament.compareTo(b.testament);
      if (testamentCompare != 0) {
        return testamentCompare;
      }

      final bookIndexA = bible[a.testament].keys.toList().indexOf(a.book);
      final bookIndexB = bible[b.testament].keys.toList().indexOf(b.book);
      if (bookIndexA != bookIndexB) {
        return bookIndexA.compareTo(bookIndexB);
      }

      final chapterCompare = int.parse(a.chapter).compareTo(int.parse(b.chapter));
      if (chapterCompare != 0) {
        return chapterCompare;
      }

      return int.parse(a.verse).compareTo(int.parse(b.verse));
    });

    return results.take(10).toList();
  }

  void moveToVerse(SearchResult result) {
    final bookList = bible[result.testament].keys.cast<String>().toList();
    final chapterList = sortedKeys(bible[result.testament][result.book]);
    final verseList =
        sortedKeys(bible[result.testament][result.book][result.chapter]);

    final bookIndex = bookList.indexOf(result.book);
    final chapterIndex = chapterList.indexOf(result.chapter);
    final verseIndex = verseList.indexOf(result.verse);

    isProgrammaticMove = true;

    setState(() {
      selectedTestament = result.testament;
      selectedBook = result.book;
      selectedChapter = result.chapter;
      selectedVerse = result.verse;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (bookIndex >= 0) bookController.jumpToItem(bookIndex);
      if (chapterIndex >= 0) chapterController.jumpToItem(chapterIndex);
      if (verseIndex >= 0) verseController.jumpToItem(verseIndex);

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) isProgrammaticMove = false;
      });
    });
  }

  Future<void> loadBible() async {
    final jsonString = await rootBundle.loadString('assets/bible_full.json');
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

    final rawText = bible[selectedTestament][selectedBook][selectedChapter]
            [selectedVerse] ??
        '본문 데이터가 없습니다.';

    return cleanVerseText(rawText.toString());
  }

  void changeTestament(String testament) {
    if (testament == selectedTestament || bible.isEmpty) return;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookController.jumpToItem(0);
      chapterController.jumpToItem(0);
      verseController.jumpToItem(0);
    });
  }

  void changeBook(int index) {
    if (isProgrammaticMove || index < 0 || index >= books.length) return;
    final book = books[index];
    final firstChapter = sortedKeys(bible[selectedTestament][book]).first;
    final firstVerse =
        sortedKeys(bible[selectedTestament][book][firstChapter]).first;

    setState(() {
      selectedBook = book;
      selectedChapter = firstChapter;
      selectedVerse = firstVerse;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      chapterController.jumpToItem(0);
      verseController.jumpToItem(0);
    });
  }

  void changeChapter(int index) {
    if (isProgrammaticMove || index < 0 || index >= chapters.length) return;
    final chapter = chapters[index];
    final firstVerse =
        sortedKeys(bible[selectedTestament][selectedBook][chapter]).first;

    setState(() {
      selectedChapter = chapter;
      selectedVerse = firstVerse;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      verseController.jumpToItem(0);
    });
  }

  void changeVerse(int index) {
    if (isProgrammaticMove || index < 0 || index >= verses.length) return;
    setState(() {
      selectedVerse = verses[index];
    });
  }

  Widget iconSurface({
    required IconData icon,
    required VoidCallback onTap,
    double size = 28,
  }) {
    return Material(
      color: AppColors.surfaceStrong,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE7D9)),
            // Top menu/search buttons intentionally have no shadow.
            // Content cards keep subtle shadows instead.
            boxShadow: const [],
          ),
          child: Icon(icon, size: size, color: AppColors.text),
        ),
      ),
    );
  }

  void openMainMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                  color: const Color(0xFFD8CBB7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Bible Wheel',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.text),
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
              const Divider(height: 18, color: AppColors.divider),
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
                    const SnackBar(content: Text('Bible Wheel v1.0 UI Soft')),
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
          ? Icon(icon, size: 22, color: AppColors.goldDark)
          : Icon(
              checked
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 21,
              color: AppColors.goldDark,
            ),
      title: Text(
        title,
        style: GoogleFonts.notoSansKr(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
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
        itemExtent: 58,
        diameterRatio: 0.82,
        magnification: 1.22,
        useMagnifier: true,
        squeeze: 0.92,
        looping: false,
        onSelectedItemChanged: onChanged,
        selectionOverlay: const SizedBox.shrink(),
        children: items.map((item) {
          return Center(
            child: Text(
              labelBuilder(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget verticalCylinderDivider() {
    return Container(
      width: 1.2,
      height: 154,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.divider.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget wheelFrame() {
    return Container(
      height: 245,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF1ECE2)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFECE5),
                    Color(0xFFFFFFFF),
                    Color(0xFFE8E3DA),
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
                border: Border.all(color: const Color(0xFFD9D0C1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withOpacity(0.82),
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.background.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.22, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.surfaceStrong,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEADCC4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x183F2A0C),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: AppColors.gold.withOpacity(0.45),
                    width: 1.1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.goldDark.withOpacity(0.9),
              size: 30,
            ),
          ),
          Positioned(
            bottom: -16,
            left: 0,
            right: 0,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.goldDark.withOpacity(0.9),
              size: 30,
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                wheelPicker(
                  controller: bookController,
                  items: books,
                  labelBuilder: (value) => value,
                  onChanged: changeBook,
                  flex: 2,
                ),
                verticalCylinderDivider(),
                wheelPicker(
                  controller: chapterController,
                  items: chapters,
                  labelBuilder: (value) => '$value장',
                  onChanged: changeChapter,
                ),
                verticalCylinderDivider(),
                wheelPicker(
                  controller: verseController,
                  items: verses,
                  labelBuilder: (value) => '$value절',
                  onChanged: changeVerse,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget hintRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_outlined, size: 22, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '위아래로 스크롤하여 선택하세요',
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget verseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEFE4D5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8D8BC)),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.goldDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$selectedBook $selectedChapter장 $selectedVerse절',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('즐겨찾기는 다음 버전에서 추가합니다.')),
                  );
                },
                icon: const Icon(
                  Icons.star_border_rounded,
                  color: AppColors.goldDark,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.gold.withOpacity(0.45)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                verseText,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 23,
                  height: 1.85,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider.withOpacity(0.65)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              verseAction(Icons.copy_rounded, '복사'),
              verseAction(Icons.share_rounded, '공유'),
              verseAction(Icons.bookmark_add_outlined, '즐겨찾기'),
              verseAction(Icons.volume_up_outlined, '듣기'),
            ],
          ),
        ],
      ),
    );
  }

  Widget verseAction(IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 기능은 다음 버전에서 추가합니다.')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.text, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bible.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBFAF6), AppColors.background],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    iconSurface(
                      icon: Icons.menu_rounded,
                      onTap: openMainMenu,
                      size: 34,
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          'Bible Wheel',
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '말씀의 길을 함께 걷다',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    iconSurface(
                      icon: Icons.search_rounded,
                      size: 32,
                      onTap: () async {
                        final result = await Navigator.push<SearchResult>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchPage(searchBible: searchBible),
                          ),
                        );

                        if (result != null) moveToVerse(result);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                wheelFrame(),
                const SizedBox(height: 14),
                hintRow(),
                const SizedBox(height: 16),
                Expanded(child: verseCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<SearchResult> Function(String keyword) searchBible;

  const SearchPage({
    super.key,
    required this.searchBible,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  List<SearchResult> results = [];
  bool hasTyped = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '성경 검색',
          style: GoogleFonts.notoSansKr(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceStrong,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '예: 태초, 모세, 요316, 롬823',
                  hintStyle: GoogleFonts.notoSansKr(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                ),
                onChanged: (value) {
                  final keyword = value.trim();

                  setState(() {
                    hasTyped = keyword.isNotEmpty;
                    results = keyword.length < 2 ? [] : widget.searchBible(keyword);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        hasTyped ? '검색 결과가 없습니다' : '검색어를 두 글자 이상 입력하세요',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final result = results[index];

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          title: Text(
                            '${result.book} ${result.chapter}장 ${result.verse}절',
                            style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Text(
                            result.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSerifKr(
                              color: AppColors.text,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, result),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
