import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/search_service.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'search_results_screen.dart';
import 'item_detail_sheet.dart';

class SearchScreen extends StatefulWidget { const SearchScreen({super.key}); @override State<SearchScreen> createState()=>_SearchScreenState(); }
class _SearchScreenState extends State<SearchScreen> {
  final _controller=TextEditingController(); List<String> _recent=[]; List<Category> _categories=[]; List<MenuItem> _suggestions=[]; bool _loading=true;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { final recent=await SearchService.recentSearches(); try { final home=await CustomerService.home(); if(mounted)setState((){_recent=recent;_categories=home.categories;_suggestions=home.popularItems.take(6).toList();_loading=false;}); } catch(_){if(mounted)setState((){_recent=recent;_loading=false;});} }
  @override void dispose(){_controller.dispose();super.dispose();}
  Future<void> _runSearch(String q) async {final s=q.trim();if(s.isEmpty)return;await SearchService.addRecentSearch(s);if(!mounted)return;await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>SearchResultsScreen(initialQuery:s)));_load();}
  Future<void> _clear() async {await SearchService.clearRecentSearches();if(mounted)setState(()=>_recent=[]);}
  Future<void> _remove(String q) async {await SearchService.removeRecentSearch(q);if(mounted)setState(()=>_recent.remove(q));}
  @override Widget build(BuildContext context){final t=AppLocalizations.of(context)!;return Scaffold(backgroundColor:AppTheme.scaffoldBg(context),body:SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,10,18,12),child:Row(children:[
      Material(color:AppTheme.surface(context),shape:const CircleBorder(),child:InkWell(onTap:()=>Navigator.pop(context),customBorder:const CircleBorder(),child:const SizedBox(width:44,height:44,child:Icon(Icons.arrow_back_rounded)))),
      const SizedBox(width:12),Expanded(child:Container(height:48,decoration:BoxDecoration(color:AppTheme.surface(context),borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.05),blurRadius:16,offset:const Offset(0,6))]),child:TextField(controller:_controller,autofocus:true,textInputAction:TextInputAction.search,onSubmitted:_runSearch,decoration:InputDecoration(hintText:t.searchHint,prefixIcon:const Icon(Icons.search_rounded),suffixIcon:_controller.text.isEmpty?null:IconButton(icon:const Icon(Icons.close_rounded),onPressed:(){_controller.clear();setState((){});}),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(vertical:14))))),
    ])),
    Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.fromLTRB(18,8,18,28),children:[
      if(_recent.isNotEmpty)_Section(title:t.yourLastSearch,action:t.clearAll,onAction:_clear,child:Wrap(spacing:8,runSpacing:8,children:_recent.map((q)=>_Pill(label:q,onTap:()=>_runSearch(q),onRemove:()=>_remove(q))).toList())),
      if(_suggestions.isNotEmpty)_Section(title:t.suggestions,child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.55),itemCount:_suggestions.length,itemBuilder:(c,i){final item=_suggestions[i];return _FoodSuggestion(item:item,onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>ItemDetailSheet(item:item)));})),
      if(_categories.isNotEmpty)_Section(title:t.popularCategories,child:Wrap(spacing:10,runSpacing:10,children:_categories.map((c)=>GestureDetector(onTap:()=>_runSearch(c.displayName(context)),child:Container(padding:const EdgeInsets.symmetric(horizontal:15,vertical:11),decoration:BoxDecoration(color:AppTheme.surface(context),borderRadius:BorderRadius.circular(14),border:Border.all(color:AppTheme.borderColor(context))),child:Text(c.displayName(context),style:const TextStyle(fontWeight:FontWeight.w700))))).toList()))
    ]))
  ])));}
}
class _Section extends StatelessWidget{final String title;final String? action;final VoidCallback? onAction;final Widget child;const _Section({required this.title,required this.child,this.action,this.onAction});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(top:12,bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),if(action!=null)TextButton(onPressed:onAction,child:Text(action!,style:const TextStyle(fontWeight:FontWeight.w800)))]),const SizedBox(height:12),child]));}
class _Pill extends StatelessWidget{final String label;final VoidCallback onTap;final VoidCallback onRemove;const _Pill({required this.label,required this.onTap,required this.onRemove});@override Widget build(BuildContext c)=>Material(color:AppTheme.surface(c),borderRadius:BorderRadius.circular(14),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(14),child:Padding(padding:const EdgeInsets.fromLTRB(14,10,8,10),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.history_rounded,size:16),const SizedBox(width:7),Text(label,style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(width:5),GestureDetector(onTap:onRemove,child:const Icon(Icons.close_rounded,size:16))]))));}
class _FoodSuggestion extends StatelessWidget{final MenuItem item;final VoidCallback onTap;const _FoodSuggestion({required this.item,required this.onTap});@override Widget build(BuildContext c){final image=item.image;return Material(color:AppTheme.surface(c),borderRadius:BorderRadius.circular(18),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Padding(padding:const EdgeInsets.all(9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(14),child:image!=null&&image.isNotEmpty?Image.network(image,fit:BoxFit.cover,width:double.infinity,errorBuilder:(_,__,___)=>_FoodIcon()):_FoodIcon())),const SizedBox(height:8),Row(children:[Expanded(child:Text(item.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13))),const SizedBox(width:4),Text('₹${item.price.toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:12,color:AppTheme.primary))])]))));}}
class _FoodIcon extends StatelessWidget{const _FoodIcon();@override Widget build(BuildContext c)=>Container(color:AppTheme.primary.withOpacity(.08),child:const Center(child:Icon(Icons.restaurant_rounded,size:30,color:AppTheme.primary)));}
