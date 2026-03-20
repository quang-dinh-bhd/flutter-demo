class PlaylistModel {
  final String id;
  final String name;

  List<dynamic> movies;
  int page;
  bool hasMore;
  bool isLoadingMovies;
  bool infiniteLoop;

  PlaylistModel({
    required this.id,
    required this.name,
    this.movies = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMovies = false,
    this.infiniteLoop = false,
  });
}
