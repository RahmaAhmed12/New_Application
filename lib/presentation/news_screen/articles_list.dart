
import 'package:flutter/material.dart';
import 'package:news_app_c13/data/api/api_manager.dart';
import 'package:news_app_c13/data/models/article_dm.dart';
import 'package:news_app_c13/presentation/news_screen/widgets/article_item_widget.dart';
import 'package:news_app_c13/presentation/resourses/color_manger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
//import 'package:webview_flutter/webview_flutter.dart';

class ArticlesList extends StatefulWidget {
  final String sourceId;
  final String searchQuery;
  const ArticlesList({super.key, required this.sourceId, this.searchQuery = ""});

  @override
  _ArticlesListState createState() => _ArticlesListState();
}

class _ArticlesListState extends State<ArticlesList> {
  int? selectedArticleIndex;
  String? selectedArticleUrl;
  List<ArticleDM> articles = [];


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selectedArticleIndex != null) {
          setState(() {
            selectedArticleIndex = null;
            selectedArticleUrl = null;
          });
        }
      },
      behavior: HitTestBehavior.opaque, // Ensures taps are detected outside children
      child: Stack(
        children: [
          FutureBuilder<List<ArticleDM>>(
            future: ApiManager.getArticles(widget.sourceId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return buildError(snapshot.error.toString());
              } else if (snapshot.hasData) {
                articles = snapshot.data!;
                return buildArticles(context);
              } else {
                return buildLoading();
              }
            },
          ),
          buildBottomContainer(),
        ],
      ),
    );
  }



  Widget buildArticles(BuildContext context) {
    List<ArticleDM> filteredArticles = articles.where((article) {
      final title = article.title?.toLowerCase() ?? '';
      final author = article.author?.toLowerCase() ?? '';
      final search = widget.searchQuery.toLowerCase();
      return title.contains(search) || author.contains(search);
    }).toList();

    return ListView.separated(
      itemBuilder: (context, index) {
        var article = filteredArticles[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedArticleIndex = index;
              selectedArticleUrl = article.url;
            });
          },
          child: ArticleItemWidget(
            image: article.urlToImage ?? '',
            title: article.title ?? '',
            author: article.author ?? '',
            date: article.publishedAt ?? "",
          ),
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemCount: filteredArticles.length,
    );
  }





  Widget buildBottomContainer() {
    if (selectedArticleIndex == null) return SizedBox.shrink();
    var selectedArticle = articles[selectedArticleIndex!];

    return Positioned(
      bottom: 15,
      left: 10,
      right: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: EdgeInsets.all(16.0),
            decoration: buildContainerDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).brightness == Brightness.light
                            ? ColorManger.white
                            : ColorManger.containerBgDark
                    ),
                    onPressed: () {
                      setState(() {
                        selectedArticleIndex = null;
                        selectedArticleUrl = null;
                      });
                    },
                  ),
                ),
                buildArticleImage(selectedArticle.urlToImage, constraints),
                SizedBox(height: 10),
                buildArticleDetails(selectedArticleUrl, context),
                SizedBox(height: 10),
                buildViewFullArticleButton(context, constraints, selectedArticleUrl!)
              ],
            ),
          );
        },
      ),
    );
  }



  BoxDecoration buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? ColorManger.containerBgDark
          : ColorManger.white,
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    );
  }

  Widget buildArticleImage(String? imageUrl, BoxConstraints constraints) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl ?? '',
        height: 200,
        width: constraints.maxWidth - 5,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget buildError(String errorMessage) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(errorMessage),
        ElevatedButton(onPressed: () {}, child: Text("Try again"))
      ],
    ),
  );

  Widget buildLoading() => Center(child: CircularProgressIndicator());

  Widget buildArticleDetails(String? url, BuildContext context) {
    return FutureBuilder<Widget>(
      future: getArticleDetails(url, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading article', style: TextStyle(color: Colors.black));
        } else {
          return snapshot.data ?? Text('No data', style: TextStyle(color: Colors.black));
        }
      },
    );
  }

  Future<Widget> getArticleDetails(String? url, BuildContext context) async {
    if (url == null || !Uri.parse(url).isAbsolute) {
      return Text('Invalid URL', style: TextStyle(color: Colors.red));
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var document = html_parser.parse(response.body);
        String description = document.querySelector("meta[name='description']")?.attributes['content'] ?? 'No Description Found';
        String bodyText = document.body?.text.trim() ?? '';

        int totalWords = bodyText.isNotEmpty ? bodyText.split(RegExp(r'\s+')).length : 0;

        Color textColor = Theme.of(context).brightness == Brightness.light ? ColorManger.white : ColorManger.black;

        return SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$description',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              SizedBox(height: 5,),
              Text(
                '[+$totalWords]',
                style: TextStyle(fontSize: 12, color: textColor),
              ),

            ],
          ),
        );
      } else {
        return Text('Failed to load details', style: TextStyle(color: Colors.red));
      }
    } catch (e) {
      return Text('Error fetching details', style: TextStyle(color: Colors.red));
    }
  }





  Widget buildViewFullArticleButton(BuildContext context, BoxConstraints constraints, String articleUrl) {
    return ElevatedButton(
      onPressed: () async {
        final Uri url = Uri.parse(articleUrl);
        print("Attempting to open: $articleUrl");

        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          print("No app found to handle the URL.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch article")),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(constraints.maxWidth - 5, 50),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        "View Full Article",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }


}
