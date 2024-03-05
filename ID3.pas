{ ============================================================================
    File Name   : ID3.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : ID3 functionality class
    License     : GPLv3
  ============================================================================ }
unit ID3;

interface

uses
  Classes, SysUtils,
  ID3Struct;

type
  TID3 = class
  private
    V11: TID3v11;
    V2Header: TID3v2Header;
    V2ExtendedHeader: TID3v2ExtendedHeader;

    FHasID3v1: Boolean;
    FHasID3v2: Boolean;

    FTrack: Integer;
    FDisc: Integer;
    FTitle: string;
    FArtist: string;
    FAlbum: string;
    FYear: Integer;

  public
    constructor Create(const FileName: string); overload;
    constructor Create(const Stream: TStream); overload;

    property HasID3v1: Boolean read FHasID3v1;
    property HasID3v2: Boolean read FHasID3v2;

    property Track: Integer read FTrack;
    property Disc: Integer read FDisc;
    property Title: string read FTitle;
    property Artist: string read FArtist;
    property Album: string read FAlbum;
    property Year: Integer read FYear;
  end;


function CheckFileForID3(const FileName: string): TID3;


implementation


var
  BigEndianUnicodeEncoding: TBigEndianUnicodeEncoding;


function CheckFileForID3(const FileName: string): TID3;
begin
  Result := TID3.Create(FileName);
  if (not Result.HasID3v1) and (not Result.HasID3v2) then
    FreeAndNil(Result);
end;

procedure TrimEndOfString(var S: string);
var
  i: Integer;
begin
  for i := 1 to Length(S) do
    if S[i] = #0 then
    begin
      SetLength(S, i - 1);
      Break;
    end;
end;

function GetFirstInt(const S: string): Integer;
var
  i: Integer;
  Num: string;
begin
  Num := '';
  for i := 1 to Length(S) do
    if CharInSet(S[i], ['0'..'9']) then
      Num := Num + S[i]
    else
      Break;

  if Num = '' then
    Result := 0
  else
    Result := StrToInt(Num);
end;

function ReadStringFrameContent(Stream: TStream; Len: Integer): string;
var
  Encoding: Byte;
  BOM: array[0..1] of Byte;
  Buff: array of Byte;
  StrBuff: RawByteString;
begin
  Result := '';

  if Len > 1 then
  begin
    // Read Encoding first...
    Stream.Read(Encoding, 1);
    case Encoding of
      $00:  // ISO-8859-1
        begin
          SetLength(StrBuff, Len - 1);
          Stream.Read(StrBuff[1], Len - 1);
          Result := string(AnsiString(StrBuff));
          TrimEndOfString(Result);
        end;
      $01:  // UTF-16 with BOM
        begin
          // Read BOM first
          Stream.Read(BOM[0], 2);

          if (BOM[0] = $FE) and (BOM[1] = $FF) then  // Big-Endian UTF-16
          begin
            SetLength(Buff, Len - 3);
            Stream.Read(Buff[0], Len - 3);
            Result := BigEndianUnicodeEncoding.GetString(Buff);
            TrimEndOfString(Result);
          end
          else  // Otherwise, assume it's Little-Endian UTF-16
          begin
            SetLength(Result, (Len - 3) div 2);
            Stream.Read(Result[1], Len - 3);
            TrimEndOfString(Result);
          end;
        end;
      $02:  // UTF-16 without BOM
        begin
          SetLength(Result, (Len - 1) div 2);
          Stream.Read(Result[1], Len - 1);
          TrimEndOfString(Result);
        end;
      $03:  // UTF-8
        begin
          SetLength(StrBuff, Len - 1);
          Stream.Read(StrBuff[1], Len - 1);
          Result := UTF8ToUnicodeString(StrBuff);
          TrimEndOfString(Result);
        end;
    else  // Unknown encoding, just skip it!
      Stream.Seek(Len - 1, soFromCurrent);
    end;
  end;
end;


{ TID3 }

constructor TID3.Create(const FileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Create(FS);
  finally
    FS.Free;
  end;
end;

constructor TID3.Create(const Stream: TStream);
var
  HeaderSize: Int64;
  Pos: Int64;
  Done: Boolean;
  ID3v2FrameHeader: TID3v2FrameHeader;
  TrackString: string;
  DiscString: string;
  YearString: string;
begin
  FHasID3v1 := False;
  FHasID3v2 := False;

  FTrack := 0;
  FDisc := 0;
  FTitle := '';
  FArtist := '';
  FAlbum := '';
  FYear := 0;

  Stream.Seek(0, soFromBeginning);

  // Read first ID3v2 header...
  Stream.Read(V2Header, SizeOf(TID3v2Header));
  if ValidID3v2Present(V2Header) then
  begin
    FHasID3v2 := True;

    if V2Header.HasExtendedHeader then
    begin
      Stream.Read(V2ExtendedHeader, SizeOf(TID3v2ExtendedHeader));

      // Skip headers...
      HeaderSize := V2Header.Size.Value + V2ExtendedHeader.Size.Value;
      Stream.Seek(HeaderSize, soFromBeginning);
    end;

    Pos := Stream.Position;
    Done := False;

    // Seek for important frames (only)...
    while (Pos < V2Header.Size.Value) and (not Done) do
    begin
      if Stream.Size - Pos > SizeOf(TID3v2FrameHeader) then
      begin
        Stream.Read(ID3v2FrameHeader, SizeOf(TID3v2FrameHeader));

        with ID3v2FrameHeader do
          if FrameID = 'TRCK' then       // Track Frame
            begin
              TrackString := ReadStringFrameContent(Stream, Size.AsInteger);
              FTrack := GetFirstInt(TrackString);
            end
          else if FrameID = 'TPOS' then  // Disc
            begin
              DiscString := ReadStringFrameContent(Stream, Size.AsInteger);
              FDisc := GetFirstInt(DiscString);
            end
          else if FrameID = 'TIT2' then  // Song Title
            begin
              FTitle := ReadStringFrameContent(Stream, Size.AsInteger);
            end
          else if FrameID = 'TPE1' then  // Artist
            begin
              FArtist := ReadStringFrameContent(Stream, Size.AsInteger);
            end
          else if FrameID = 'TALB' then  // Album
            begin
              FAlbum := ReadStringFrameContent(Stream, Size.AsInteger)
            end
          else if FrameID = 'TYER' then  // Year (for v2.3)
            begin
              YearString := ReadStringFrameContent(Stream, Size.AsInteger);
              FYear := GetFirstInt(YearString);
            end
          else if FrameID = 'TDRC' then  // Recoding Time (for v2.4 - we take Year from here)
            begin
              YearString := ReadStringFrameContent(Stream, Size.AsInteger);
              FYear := GetFirstInt(YearString);
            end
          else if FrameID[0] = #0 then
            Done := True
          else
            Stream.Seek(Size.AsInteger, soFromCurrent);

        Pos := Stream.Position;
      end
      else
        Done := True;
    end;

  end
  else
    if Stream.Size > SizeOf(TID3v11) then
    begin  // if ID3v2 not found, check for ID3v1
      Stream.Seek(SizeOf(TID3v11), soFromEnd);
      Stream.Read(V11, SizeOf(TID3v11));

      if ValidID3v1Present(V11) then
      begin
        FHasID3v1 := True;
      end;
    end;
end;


initialization
  BigEndianUnicodeEncoding := TBigEndianUnicodeEncoding.Create;
finalization
  BigEndianUnicodeEncoding.Free;
end.
