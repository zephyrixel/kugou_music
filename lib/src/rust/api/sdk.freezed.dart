// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sdk.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LyricFetchDto {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricFetchDto);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LyricFetchDto()';
}


}

/// @nodoc
class $LyricFetchDtoCopyWith<$Res>  {
$LyricFetchDtoCopyWith(LyricFetchDto _, $Res Function(LyricFetchDto) __);
}


/// Adds pattern-matching-related methods to [LyricFetchDto].
extension LyricFetchDtoPatterns on LyricFetchDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LyricFetchDto_Found value)?  found,TResult Function( LyricFetchDto_NotFound value)?  notFound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LyricFetchDto_Found() when found != null:
return found(_that);case LyricFetchDto_NotFound() when notFound != null:
return notFound(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LyricFetchDto_Found value)  found,required TResult Function( LyricFetchDto_NotFound value)  notFound,}){
final _that = this;
switch (_that) {
case LyricFetchDto_Found():
return found(_that);case LyricFetchDto_NotFound():
return notFound(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LyricFetchDto_Found value)?  found,TResult? Function( LyricFetchDto_NotFound value)?  notFound,}){
final _that = this;
switch (_that) {
case LyricFetchDto_Found() when found != null:
return found(_that);case LyricFetchDto_NotFound() when notFound != null:
return notFound(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LyricDocumentDto document)?  found,TResult Function()?  notFound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LyricFetchDto_Found() when found != null:
return found(_that.document);case LyricFetchDto_NotFound() when notFound != null:
return notFound();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LyricDocumentDto document)  found,required TResult Function()  notFound,}) {final _that = this;
switch (_that) {
case LyricFetchDto_Found():
return found(_that.document);case LyricFetchDto_NotFound():
return notFound();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LyricDocumentDto document)?  found,TResult? Function()?  notFound,}) {final _that = this;
switch (_that) {
case LyricFetchDto_Found() when found != null:
return found(_that.document);case LyricFetchDto_NotFound() when notFound != null:
return notFound();case _:
  return null;

}
}

}

/// @nodoc


class LyricFetchDto_Found extends LyricFetchDto {
  const LyricFetchDto_Found({required this.document}): super._();


 final  LyricDocumentDto document;

/// Create a copy of LyricFetchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricFetchDto_FoundCopyWith<LyricFetchDto_Found> get copyWith => _$LyricFetchDto_FoundCopyWithImpl<LyricFetchDto_Found>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricFetchDto_Found&&(identical(other.document, document) || other.document == document));
}


@override
int get hashCode => Object.hash(runtimeType,document);

@override
String toString() {
  return 'LyricFetchDto.found(document: $document)';
}


}

/// @nodoc
abstract mixin class $LyricFetchDto_FoundCopyWith<$Res> implements $LyricFetchDtoCopyWith<$Res> {
  factory $LyricFetchDto_FoundCopyWith(LyricFetchDto_Found value, $Res Function(LyricFetchDto_Found) _then) = _$LyricFetchDto_FoundCopyWithImpl;
@useResult
$Res call({
 LyricDocumentDto document
});




}
/// @nodoc
class _$LyricFetchDto_FoundCopyWithImpl<$Res>
    implements $LyricFetchDto_FoundCopyWith<$Res> {
  _$LyricFetchDto_FoundCopyWithImpl(this._self, this._then);

  final LyricFetchDto_Found _self;
  final $Res Function(LyricFetchDto_Found) _then;

/// Create a copy of LyricFetchDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? document = null,}) {
  return _then(LyricFetchDto_Found(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as LyricDocumentDto,
  ));
}


}

/// @nodoc


class LyricFetchDto_NotFound extends LyricFetchDto {
  const LyricFetchDto_NotFound(): super._();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricFetchDto_NotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LyricFetchDto.notFound()';
}


}




/// @nodoc
mixin _$PlaybackResolutionDto {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackResolutionDto);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaybackResolutionDto()';
}


}

/// @nodoc
class $PlaybackResolutionDtoCopyWith<$Res>  {
$PlaybackResolutionDtoCopyWith(PlaybackResolutionDto _, $Res Function(PlaybackResolutionDto) __);
}


/// Adds pattern-matching-related methods to [PlaybackResolutionDto].
extension PlaybackResolutionDtoPatterns on PlaybackResolutionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaybackResolutionDto_Playable value)?  playable,TResult Function( PlaybackResolutionDto_Preview value)?  preview,TResult Function( PlaybackResolutionDto_Denied value)?  denied,TResult Function( PlaybackResolutionDto_Unavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable() when playable != null:
return playable(_that);case PlaybackResolutionDto_Preview() when preview != null:
return preview(_that);case PlaybackResolutionDto_Denied() when denied != null:
return denied(_that);case PlaybackResolutionDto_Unavailable() when unavailable != null:
return unavailable(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaybackResolutionDto_Playable value)  playable,required TResult Function( PlaybackResolutionDto_Preview value)  preview,required TResult Function( PlaybackResolutionDto_Denied value)  denied,required TResult Function( PlaybackResolutionDto_Unavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable():
return playable(_that);case PlaybackResolutionDto_Preview():
return preview(_that);case PlaybackResolutionDto_Denied():
return denied(_that);case PlaybackResolutionDto_Unavailable():
return unavailable(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaybackResolutionDto_Playable value)?  playable,TResult? Function( PlaybackResolutionDto_Preview value)?  preview,TResult? Function( PlaybackResolutionDto_Denied value)?  denied,TResult? Function( PlaybackResolutionDto_Unavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable() when playable != null:
return playable(_that);case PlaybackResolutionDto_Preview() when preview != null:
return preview(_that);case PlaybackResolutionDto_Denied() when denied != null:
return denied(_that);case PlaybackResolutionDto_Unavailable() when unavailable != null:
return unavailable(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? bitRate,  int? durationSecs)?  playable,TResult Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? endMs,  int? bitRate,  int? durationSecs)?  preview,TResult Function( int? status,  int? failProcess)?  denied,TResult Function()?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable() when playable != null:
return playable(_that.url,_that.artworkUrl,_that.quality,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Preview() when preview != null:
return preview(_that.url,_that.artworkUrl,_that.quality,_that.endMs,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Denied() when denied != null:
return denied(_that.status,_that.failProcess);case PlaybackResolutionDto_Unavailable() when unavailable != null:
return unavailable();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? bitRate,  int? durationSecs)  playable,required TResult Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? endMs,  int? bitRate,  int? durationSecs)  preview,required TResult Function( int? status,  int? failProcess)  denied,required TResult Function()  unavailable,}) {final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable():
return playable(_that.url,_that.artworkUrl,_that.quality,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Preview():
return preview(_that.url,_that.artworkUrl,_that.quality,_that.endMs,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Denied():
return denied(_that.status,_that.failProcess);case PlaybackResolutionDto_Unavailable():
return unavailable();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? bitRate,  int? durationSecs)?  playable,TResult? Function( String url,  String? artworkUrl,  AudioQualityDto quality,  int? endMs,  int? bitRate,  int? durationSecs)?  preview,TResult? Function( int? status,  int? failProcess)?  denied,TResult? Function()?  unavailable,}) {final _that = this;
switch (_that) {
case PlaybackResolutionDto_Playable() when playable != null:
return playable(_that.url,_that.artworkUrl,_that.quality,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Preview() when preview != null:
return preview(_that.url,_that.artworkUrl,_that.quality,_that.endMs,_that.bitRate,_that.durationSecs);case PlaybackResolutionDto_Denied() when denied != null:
return denied(_that.status,_that.failProcess);case PlaybackResolutionDto_Unavailable() when unavailable != null:
return unavailable();case _:
  return null;

}
}

}

/// @nodoc


class PlaybackResolutionDto_Playable extends PlaybackResolutionDto {
  const PlaybackResolutionDto_Playable({required this.url, this.artworkUrl, required this.quality, this.bitRate, this.durationSecs}): super._();
  

 final  String url;
 final  String? artworkUrl;
 final  AudioQualityDto quality;
 final  int? bitRate;
 final  int? durationSecs;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackResolutionDto_PlayableCopyWith<PlaybackResolutionDto_Playable> get copyWith => _$PlaybackResolutionDto_PlayableCopyWithImpl<PlaybackResolutionDto_Playable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackResolutionDto_Playable&&(identical(other.url, url) || other.url == url)&&(identical(other.artworkUrl, artworkUrl) || other.artworkUrl == artworkUrl)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.durationSecs, durationSecs) || other.durationSecs == durationSecs));
}


@override
int get hashCode => Object.hash(runtimeType,url,artworkUrl,quality,bitRate,durationSecs);

@override
String toString() {
  return 'PlaybackResolutionDto.playable(url: $url, artworkUrl: $artworkUrl, quality: $quality, bitRate: $bitRate, durationSecs: $durationSecs)';
}


}

/// @nodoc
abstract mixin class $PlaybackResolutionDto_PlayableCopyWith<$Res> implements $PlaybackResolutionDtoCopyWith<$Res> {
  factory $PlaybackResolutionDto_PlayableCopyWith(PlaybackResolutionDto_Playable value, $Res Function(PlaybackResolutionDto_Playable) _then) = _$PlaybackResolutionDto_PlayableCopyWithImpl;
@useResult
$Res call({
 String url, String? artworkUrl, AudioQualityDto quality, int? bitRate, int? durationSecs
});




}
/// @nodoc
class _$PlaybackResolutionDto_PlayableCopyWithImpl<$Res>
    implements $PlaybackResolutionDto_PlayableCopyWith<$Res> {
  _$PlaybackResolutionDto_PlayableCopyWithImpl(this._self, this._then);

  final PlaybackResolutionDto_Playable _self;
  final $Res Function(PlaybackResolutionDto_Playable) _then;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? artworkUrl = freezed,Object? quality = null,Object? bitRate = freezed,Object? durationSecs = freezed,}) {
  return _then(PlaybackResolutionDto_Playable(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,artworkUrl: freezed == artworkUrl ? _self.artworkUrl : artworkUrl // ignore: cast_nullable_to_non_nullable
as String?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as AudioQualityDto,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,durationSecs: freezed == durationSecs ? _self.durationSecs : durationSecs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class PlaybackResolutionDto_Preview extends PlaybackResolutionDto {
  const PlaybackResolutionDto_Preview({required this.url, this.artworkUrl, required this.quality, this.endMs, this.bitRate, this.durationSecs}): super._();
  

 final  String url;
 final  String? artworkUrl;
 final  AudioQualityDto quality;
 final  int? endMs;
 final  int? bitRate;
 final  int? durationSecs;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackResolutionDto_PreviewCopyWith<PlaybackResolutionDto_Preview> get copyWith => _$PlaybackResolutionDto_PreviewCopyWithImpl<PlaybackResolutionDto_Preview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackResolutionDto_Preview&&(identical(other.url, url) || other.url == url)&&(identical(other.artworkUrl, artworkUrl) || other.artworkUrl == artworkUrl)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.durationSecs, durationSecs) || other.durationSecs == durationSecs));
}


@override
int get hashCode => Object.hash(runtimeType,url,artworkUrl,quality,endMs,bitRate,durationSecs);

@override
String toString() {
  return 'PlaybackResolutionDto.preview(url: $url, artworkUrl: $artworkUrl, quality: $quality, endMs: $endMs, bitRate: $bitRate, durationSecs: $durationSecs)';
}


}

/// @nodoc
abstract mixin class $PlaybackResolutionDto_PreviewCopyWith<$Res> implements $PlaybackResolutionDtoCopyWith<$Res> {
  factory $PlaybackResolutionDto_PreviewCopyWith(PlaybackResolutionDto_Preview value, $Res Function(PlaybackResolutionDto_Preview) _then) = _$PlaybackResolutionDto_PreviewCopyWithImpl;
@useResult
$Res call({
 String url, String? artworkUrl, AudioQualityDto quality, int? endMs, int? bitRate, int? durationSecs
});




}
/// @nodoc
class _$PlaybackResolutionDto_PreviewCopyWithImpl<$Res>
    implements $PlaybackResolutionDto_PreviewCopyWith<$Res> {
  _$PlaybackResolutionDto_PreviewCopyWithImpl(this._self, this._then);

  final PlaybackResolutionDto_Preview _self;
  final $Res Function(PlaybackResolutionDto_Preview) _then;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? artworkUrl = freezed,Object? quality = null,Object? endMs = freezed,Object? bitRate = freezed,Object? durationSecs = freezed,}) {
  return _then(PlaybackResolutionDto_Preview(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,artworkUrl: freezed == artworkUrl ? _self.artworkUrl : artworkUrl // ignore: cast_nullable_to_non_nullable
as String?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as AudioQualityDto,endMs: freezed == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int?,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,durationSecs: freezed == durationSecs ? _self.durationSecs : durationSecs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class PlaybackResolutionDto_Denied extends PlaybackResolutionDto {
  const PlaybackResolutionDto_Denied({this.status, this.failProcess}): super._();
  

 final  int? status;
 final  int? failProcess;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackResolutionDto_DeniedCopyWith<PlaybackResolutionDto_Denied> get copyWith => _$PlaybackResolutionDto_DeniedCopyWithImpl<PlaybackResolutionDto_Denied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackResolutionDto_Denied&&(identical(other.status, status) || other.status == status)&&(identical(other.failProcess, failProcess) || other.failProcess == failProcess));
}


@override
int get hashCode => Object.hash(runtimeType,status,failProcess);

@override
String toString() {
  return 'PlaybackResolutionDto.denied(status: $status, failProcess: $failProcess)';
}


}

/// @nodoc
abstract mixin class $PlaybackResolutionDto_DeniedCopyWith<$Res> implements $PlaybackResolutionDtoCopyWith<$Res> {
  factory $PlaybackResolutionDto_DeniedCopyWith(PlaybackResolutionDto_Denied value, $Res Function(PlaybackResolutionDto_Denied) _then) = _$PlaybackResolutionDto_DeniedCopyWithImpl;
@useResult
$Res call({
 int? status, int? failProcess
});




}
/// @nodoc
class _$PlaybackResolutionDto_DeniedCopyWithImpl<$Res>
    implements $PlaybackResolutionDto_DeniedCopyWith<$Res> {
  _$PlaybackResolutionDto_DeniedCopyWithImpl(this._self, this._then);

  final PlaybackResolutionDto_Denied _self;
  final $Res Function(PlaybackResolutionDto_Denied) _then;

/// Create a copy of PlaybackResolutionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? failProcess = freezed,}) {
  return _then(PlaybackResolutionDto_Denied(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int?,failProcess: freezed == failProcess ? _self.failProcess : failProcess // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class PlaybackResolutionDto_Unavailable extends PlaybackResolutionDto {
  const PlaybackResolutionDto_Unavailable(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackResolutionDto_Unavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaybackResolutionDto.unavailable()';
}


}




// dart format on
