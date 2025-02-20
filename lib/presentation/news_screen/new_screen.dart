
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_c13/data/models/source_dm.dart';
//import 'package:news_app_c13/presentation/common/widgets/custom_scaffold.dart';
import 'package:news_app_c13/presentation/news_screen/articles_list.dart';
import 'package:news_app_c13/presentation/news_screen/news_screen_viewmodel.dart';
import 'package:news_app_c13/presentation/resourses/color_manger.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class NewsScreen extends StatefulWidget {
  static const String routeName = '/newsScreen';
  String categoryId = "";

  NewsScreen({super.key, this.categoryId = ""});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late ThemeProvider themeProvider;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  NewsScreenViewModel viewModel = NewsScreenViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.getSources(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return BlocProvider(
      create: (_) => viewModel,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: _isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search by Author or Title...",
              border: InputBorder.none,
            ),
            onChanged: (query) {
              setState(() {});
            },
          )
              : Text(
            widget.categoryId.isEmpty ? "General" : widget.categoryId,

          ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<NewsScreenViewModel, NewsViewModelState>(
                builder: (context, state) {
                  var sourceApi = state.sourceApi;
                  if (sourceApi.hasError) {
                    return buildError(sourceApi.error);
                  } else if (sourceApi.hasData) {
                    return buildTabs(
                        sourceApi.getData<List<SourceDM>>(), _searchController.text);
                  } else {
                    return buildLoading();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabs(List<SourceDM> sources, String searchQuery) => DefaultTabController(
    length: sources.length,
    child: Column(
      children: [
        TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: themeProvider.isDarkTheme
                ? ColorManger.white
                : ColorManger.black,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: sources
                .map(
                  (source) => Tab(
                text: source.name,
              ),
            )
                .toList()),
        Expanded(
          child: TabBarView(
            children: sources
                .map(
                  (source) => ArticlesList(
                  sourceId: source.id!, searchQuery: searchQuery),
            )
                .toList(),
          ),
        ),
      ],
    ),
  );

  Widget buildError(String errorMessage) => Column(
    children: [
      Text(errorMessage),
      ElevatedButton(
          onPressed: () {
            viewModel.getSources(widget.categoryId);
          },
          child: Text("Try again"))
    ],
  );

  Widget buildLoading() => Center(child: CircularProgressIndicator());
}
