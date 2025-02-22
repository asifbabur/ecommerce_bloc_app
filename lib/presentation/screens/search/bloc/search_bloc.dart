import 'package:ecommerce_bloc_app/data/models/models.dart';
import 'package:ecommerce_bloc_app/data/local/pref.dart';
import 'package:ecommerce_bloc_app/data/repository/repository.dart';
import 'package:ecommerce_bloc_app/presentation/screens/search/bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductRepository _productRepository = AppRepository.productRepository;

  SearchBloc() : super(Searching()) {
    on<OpenScreen>(_onOpenScreen);
    on<KeywordChanged>(_onKeywordChanged, transformer: _debounce());
  }

  EventTransformer<KeywordChanged> _debounce<KeywordChanged>() {
    return (events, mapper) => events.debounceTime(Duration(milliseconds: 500)).flatMap(mapper);
  }

  Future<void> _onOpenScreen(OpenScreen event, Emitter<SearchState> emit) async {
    try {
      List<String> recentKeywords = await _getRecentKeywords();
      emit(SuggestionLoaded(
        recentKeywords: recentKeywords,
        hotKeywords: hotKeywords,
      ));
    } catch (e) {
      emit(SearchFailure(e.toString()));
    }
  }

  Future<void> _onKeywordChanged(KeywordChanged event, Emitter<SearchState> emit) async {
    emit(Searching());
    try {
      List<String> recentKeywords = await _getRecentKeywords();
      if (event.keyword.isEmpty) {
        emit(SuggestionLoaded(
          recentKeywords: recentKeywords,
          hotKeywords: hotKeywords,
        ));
      } else {
        List<Product> products = await _productRepository.fetchProducts();
        List<Product> results = products
            .where((p) => p.name.toLowerCase().contains(event.keyword.toLowerCase()))
            .toList();
        emit(ResultsLoaded(results));

        if (!recentKeywords.contains(event.keyword.toLowerCase())) {
          if (recentKeywords.length > 9) {
            recentKeywords.removeAt(0);
          }
          recentKeywords.add(event.keyword.toLowerCase());
          await LocalPref.setStringList("recentKeywords", recentKeywords);
        }
      }
    } catch (e) {
      emit(SearchFailure(e.toString()));
    }
  }

  Future<List<String>> _getRecentKeywords() async {
    return LocalPref.getStringList("recentKeywords") ?? [];
  }
}

const List<String> hotKeywords = [
  "Akko",
  "Zarer",
  "Dragon ball",
  "keyboard",
];
