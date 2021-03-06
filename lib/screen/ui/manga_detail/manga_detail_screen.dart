import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:readmore/readmore.dart';

import '../../../core/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/model/bookmark/bookmark_model.dart';
import '../../../core/model/history/history_model.dart';
import '../../../core/model/manga_detail/manga_detail_model.dart';
import '../../../core/util/route_generator.dart';
import '../../widget/circular_progress.dart';
import '../../widget/genre_item.dart';
import '../../widget/rating.dart';
import '../../widget/refresh_snackbar.dart';
import '../../widget/round_button.dart';
import '../bookmark/bloc/bookmark_screen_bloc.dart';
import '../chapter/bloc/chapter_screen_bloc.dart';
import '../chapter/chapter_screen.dart';
import '../error/error_screen.dart';
import '../paginated/bloc/paginated_screen_bloc.dart';
import '../paginated/paginated_screen.dart';
import 'bloc/manga_detail_screen_bloc.dart';
import 'chapter_item.dart';
import 'manga_detail_bottom_navbar.dart';
import 'manga_detail_placeholder.dart';

class MangaDetailPageArguments {
  final String mangaEndpoint;
  final String title;

  MangaDetailPageArguments(
      {@required this.mangaEndpoint, @required this.title});
}

class MangaDetailPage extends StatefulWidget {
  final String mangaEndpoint;
  final String title;

  MangaDetailPage({@required this.mangaEndpoint, @required this.title});

  @override
  _MangaDetailPageState createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  bool isBookmarked = false;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _bookmarkFunction(BookmarkModel bookmarkModel, {MangaDetail mangaDetail}) {
    var tempData = BookmarkModel(
        title: mangaDetail.title,
        author: mangaDetail.author,
        description: mangaDetail.description,
        image: mangaDetail.image,
        mangaEndpoint: mangaDetail.mangaEndpoint,
        rating: mangaDetail.rating,
        type: mangaDetail.type,
        totalChapter: mangaDetail.chapterList.length,
        isNew: false);

    if (isBookmarked == true) {
      BlocProvider.of<BookmarkBloc>(context).add(DeleteBookmark(
          bookmarkModel: bookmarkModel != null ? bookmarkModel : tempData));
    } else {
      BlocProvider.of<BookmarkBloc>(context).add(InsertBookmark(
          bookmarkModel: bookmarkModel != null ? bookmarkModel : tempData));
    }

    BlocProvider.of<BookmarkScreenBloc>(context)
        .add(ResetBookmarkScreenBlocToInitialState());
    BlocProvider.of<BookmarkScreenBloc>(context).add(GetBookmarkScreenData());

    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  _refresh() {
    BlocProvider.of<MangaDetailScreenBloc>(context).add(
        GetMangaDetailScreenData(
            mangaEndpoint: widget.mangaEndpoint, title: widget.title));
  }

  _navigateBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: null,
        extendBodyBehindAppBar: true,
        bottomNavigationBar:
            BlocBuilder<MangaDetailScreenBloc, MangaDetailScreenState>(
          builder: (context, state) {
            if (state is MangaDetailScreenLoaded) {
              return MangaDetailNavbar(
                  historyModel: state.historyModel,
                  mangaDetail: state.mangaDetail);
            } else {
              return buildBottomNavigationPlaceholder();
            }
          },
        ),
        body: SafeArea(
            child: BlocConsumer<MangaDetailScreenBloc, MangaDetailScreenState>(
          listener: (context, state) {
            if (state is MangaDetailScreenError) {
              Scaffold.of(context).showSnackBar(refreshSnackBar(() {
                _refresh();
              }));
            } else if (state is MangaDetailScreenLoaded) {
              setState(() {
                isBookmarked = state.isBookmarked;
              });
            }
          },
          builder: (context, state) {
            if (state is MangaDetailScreenLoaded) {
              return RefreshIndicator(
                color: Theme.of(context).primaryColor,
                onRefresh: () async {
                  BlocProvider.of<MangaDetailScreenBloc>(context).add(
                      GetMangaDetailScreenData(
                          mangaEndpoint: state.mangaDetail.mangaEndpoint,
                          title: state.mangaDetail.title));
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ScreenUtil().setWidth(30),
                        vertical: ScreenUtil().setWidth(30)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RoundButton(
                                iconColor: Colors.white,
                                backgroundColor: Theme.of(context).primaryColor,
                                enableShadow: true,
                                icons: Icons.arrow_back,
                                onTap: () {
                                  _navigateBack();
                                }),
                            IconButton(
                              tooltip: 'addToBookmarkTooltip'.tr(),
                              icon: Icon(
                                isBookmarked == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Theme.of(context).primaryColor,
                                size: ScreenUtil().setHeight(100),
                              ),
                              onPressed: () {
                                setState(() {
                                  _bookmarkFunction(state.bookmarkModel,
                                      mangaDetail: state.mangaDetail);
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: ScreenUtil().setHeight(20),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          ScreenUtil().setWidth(20))),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: Offset(0, 0))
                                  ]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(ScreenUtil().setWidth(20))),
                                child: CachedNetworkImage(
                                  imageUrl: state.mangaDetail.image,
                                  width: ScreenUtil().setWidth(320),
                                  height: ScreenUtil().setWidth(460),
                                  placeholder: (context, url) => Container(
                                    child: Center(
                                      child: SizedBox(
                                          height: ScreenUtil().setWidth(80),
                                          width: ScreenUtil().setWidth(80),
                                          child:
                                              CustomCircularProgressIndicator()),
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: ScreenUtil().setHeight(10),
                            ),
                            Text(
                              state.mangaDetail.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: "Poppins-Bold",
                                  fontSize: 15,
                                  color: Colors.black),
                            ),
                            Text(
                              state.mangaDetail.author,
                              style: TextStyle(
                                  fontFamily: "Poppins-Medium",
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),
                            SizedBox(
                              height: ScreenUtil().setHeight(5),
                            ),
                            Container(
                              child: Rating(
                                rating: state.mangaDetail.rating,
                              ),
                            ),
                            SizedBox(
                              height: ScreenUtil().setHeight(20),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: ScreenUtil().setWidth(30)),
                              child: ReadMoreText(state.mangaDetail.description,
                                  trimLines: 3,
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  colorClickableText:
                                      Theme.of(context).primaryColor,
                                  trimMode: TrimMode.Line,
                                  trimCollapsedText: "trimCollapsedText".tr(),
                                  trimExpandedText: "trimExpandedText".tr()),
                            ),
                            buildInfo(
                                state.mangaDetail.status,
                                state.mangaDetail.released,
                                state.mangaDetail.type,
                                state.mangaDetail.lastUpdated),
                            buildGenre(state.mangaDetail.genreList),
                            SizedBox(
                              height: ScreenUtil().setWidth(30),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: ScreenUtil().setWidth(30)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "chapterList".tr(),
                                    style: TextStyle(
                                        fontFamily: "Poppins-Bold",
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  Text(
                                    "updatedOn".tr(),
                                    style: TextStyle(
                                        fontFamily: "Poppins-Bold",
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                            buildChapter(state.historyModel, state.mangaDetail)
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            } else if (state is MangaDetailScreenError) {
              return RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    _refresh();
                  },
                  child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                          height: MediaQuery.of(context).size.height,
                          child: ErrorPage())));
            } else {
              return buildMangaDetailPagePlaceholder(context);
            }
          },
        )),
      ),
    );
  }

  Widget buildChapter(HistoryModel historyModel, MangaDetail mangaDetail) {
    return ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(100),
            vertical: ScreenUtil().setHeight(20)),
        physics: NeverScrollableScrollPhysics(),
        itemCount: mangaDetail.chapterList.length,
        itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: ScreenUtil().setHeight(10)),
              child: InkWell(
                onTap: () {
                  BlocProvider.of<ChapterScreenBloc>(context).add(
                      GetChapterScreenData(
                          chapterEndpoint:
                              mangaDetail.chapterList[index].chapterEndpoint,
                          selectedIndex: index,
                          mangaDetail: mangaDetail,
                          historyModel: historyModel,
                          fromHome: false));
                  Navigator.pushNamed(context, chapterRoute,
                      arguments: ChapterPageArguments(
                          chapterEndpoint:
                              mangaDetail.chapterList[index].chapterEndpoint,
                          selectedIndex: index,
                          mangaDetail: mangaDetail,
                          historyModel: historyModel,
                          fromHome: false));
                },
                child: ChapterItem(
                  chapterListData: mangaDetail.chapterList[index],
                ),
              ),
            ));
  }

  Widget buildGenre(List<GenreList> genreList) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(60)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ScreenUtil().setWidth(20),
        direction: Axis.horizontal,
        children: genreList
            .map(
              (e) => InkWell(
                onTap: () {
                  BlocProvider.of<PaginatedScreenBloc>(context).add(
                      GetPaginatedScreenScreenData(
                          name: e.genreName,
                          endpoint: e.genreEndpoint,
                          pageNumber: 1,
                          isGenre: true,
                          isManga: false,
                          isManhua: false,
                          isManhwa: false));
                  Navigator.pushNamed(context, paginatedRoute,
                      arguments: PaginatedPageArguments(
                          name: e.genreName,
                          endpoint: e.genreEndpoint,
                          pageNumber: 1,
                          isGenre: true,
                          isManga: false,
                          isManhua: false,
                          isManhwa: false,
                          drawerSelectedIndex: 1));
                },
                child: GenreItem(
                    text: e.genreName,
                    textColor: Colors.white,
                    backgroundColor: Theme.of(context).primaryColor),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget buildInfo(
      String status, String released, String type, String lastUpdated) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(40)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: ScreenUtil().setHeight(30),
                    width: ScreenUtil().setHeight(30),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle),
                  ),
                  SizedBox(
                    width: ScreenUtil().setWidth(15),
                  ),
                  Text(
                    "Status: $status",
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
              SizedBox(
                width: ScreenUtil().setWidth(60),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: ScreenUtil().setHeight(30),
                        width: ScreenUtil().setHeight(30),
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                      ),
                      SizedBox(
                        width: ScreenUtil().setWidth(15),
                      ),
                      Text(
                        "${'infoReleased'.tr()}:",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: ScreenUtil().setWidth(45)),
                    child: Text(
                      "$released",
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                ],
              )
            ],
          ),
          SizedBox(
            width: ScreenUtil().setWidth(60),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: ScreenUtil().setHeight(30),
                    width: ScreenUtil().setHeight(30),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle),
                  ),
                  SizedBox(
                    width: ScreenUtil().setWidth(15),
                  ),
                  Text(
                    "${'infoType'.tr()}: $type",
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
              SizedBox(
                width: ScreenUtil().setWidth(60),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: ScreenUtil().setHeight(30),
                        width: ScreenUtil().setHeight(30),
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                      ),
                      SizedBox(
                        width: ScreenUtil().setWidth(15),
                      ),
                      Text(
                        "${'infoLatestUpdate'.tr()}:",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: ScreenUtil().setWidth(45)),
                    child: Text(
                      "$lastUpdated",
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
