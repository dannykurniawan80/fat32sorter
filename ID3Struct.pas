unit ID3Struct;

interface

const
  ID3v1TagID = 'TAG';
  ID3v2TagID = 'ID3';

const
  // NOTE: Since ID3 is using Big-Endian byte-order, we need to reverse Major and Minor byte for using with TID3v2Version.Raw field.
  ID3_VERSION_2_2 = $0002;
  ID3_VERSION_2_3 = $0003;
  ID3_VERSION_2_4 = $0004;

type
  TID3v11 = packed record
    ID: array[0..2] of AnsiChar;
    _Title: array[0..29] of AnsiChar;
    _Artist: array[0..29] of AnsiChar;
    _Album: array[0..29] of AnsiChar;
    _Year: array[0..3] of AnsiChar;
    _Comment: array[0..28] of AnsiChar;
    Track: Byte;
    Genre: Byte;

    function Title: string;
    function Artist: string;
    function Album: string;
    function Year: Integer;
    function Comment: string;
    function GenreAsString: string;
  end;

  TID3v2Version = packed record
    case Integer of
      0: ( Raw: Word );
      1: (
           Major: Byte;
           Minor: Byte;
         );
  end;

  TBigEndianInt = packed record
    Raw: array[0..3] of Byte;

    function AsCardinal: Cardinal;
    function AsInteger: Integer;
  end;

  // SyncSafe Integer is using 7-bit for each byte, which MSB bit being ignored
  TID3v2SyncSafeInt = packed record
    Raw: array[0..3] of Byte;  // ID3 is using Big-Endian byte-order

    function Value: Cardinal;
  end;

  TID3v2Header = packed record
    ID: array[0..2] of AnsiChar;
    Version: TID3v2Version;
    Flags: Byte;
    Size: TID3v2SyncSafeInt;

    function UnsynchronisationSet: Boolean;
    function HasExtendedHeader: Boolean;
    function ExperimentalIndicator: Boolean;
    function FooterPresent: Boolean;
  end;

  TID3v2ExtendedHeader = packed record
    Size: TID3v2SyncSafeInt;
    ExtendedFlags: array[0..1] of Byte;
  end;

  TID3v2FrameHeader = packed record
    FrameID: array[0..3] of AnsiChar;
    Size: TBigEndianInt;
    Flags: array[0..1] of Byte;
  end;


const
  ID3v1GenreList: array[0..191] of string = (
      'Blues',                   // 0
      'Classic rock',            // 1
      'Country',                 // 2
      'Dance',                   // 3
      'Disco',                   // 4
      'Funk',                    // 5
      'Grunge',                  // 6
      'Hip-hop',                 // 7
      'Jazz',                    // 8
      'Metal',                   // 9
      'New age',                 // 10
      'Oldies',                  // 11
      'Other',                   // 12
      'Pop',                     // 13
      'Rhythm and blues',        // 14
      'Rap',                     // 15
      'Reggae',                  // 16
      'Rock',                    // 17
      'Techno',                  // 18
      'Industrial',              // 19
      'Alternative',             // 20
      'Ska',                     // 21
      'Death metal',             // 22
      'Pranks',                  // 23
      'Soundtrack',              // 24
      'Euro-techno',             // 25
      'Ambient',                 // 26
      'Trip-hop',                // 27
      'Vocal',                   // 28
      'Jazz & funk',             // 29
      'Fusion',                  // 30
      'Trance',                  // 31
      'Classical',               // 32
      'Instrumental',            // 33
      'Acid',                    // 34
      'House',                   // 35
      'Game',                    // 36
      'Sound clip',              // 37
      'Gospel',                  // 38
      'Noise',                   // 39
      'Alternative rock',        // 40
      'Bass',                    // 41
      'Soul',                    // 42
      'Punk',                    // 43
      'Space',                   // 44
      'Meditative',              // 45
      'Instrumental pop',        // 46
      'Instrumental rock',       // 47
      'Ethnic',                  // 48
      'Gothic',                  // 49
      'Darkwave',                // 50
      'Techno-industrial',       // 51
      'Electronic',              // 52
      'Pop-folk',                // 53
      'Eurodance',               // 54
      'Dream',                   // 55
      'Southern rock',           // 56
      'Comedy',                  // 57
      'Cult',                    // 58
      'Gangsta',                 // 59
      'Top 40',                  // 60
      'Christian rap',           // 61
      'Pop/funk',                // 62
      'Jungle music',            // 63
      'Native US',               // 64
      'Cabaret',                 // 65
      'New wave',                // 66
      'Psychedelic',             // 67
      'Rave',                    // 68
      'Showtunes',               // 69
      'Trailer',                 // 70
      'Lo-fi',                   // 71
      'Tribal',                  // 72
      'Acid punk',               // 73
      'Acid jazz',               // 74
      'Polka',                   // 75
      'Retro',                   // 76
      'Musical',                 // 77
      'Rock ''n'' roll',         // 78
      'Hard rock',               // 79
      'Folk',                    // 80
      'Folk rock',               // 81
      'National folk',           // 82
      'Swing',                   // 83
      'Fast fusion',             // 84
      'Bebop',                   // 85
      'Latin',                   // 86
      'Revival',                 // 87
      'Celtic',                  // 88
      'Bluegrass',               // 89
      'Avantgarde',              // 90
      'Gothic rock',             // 91
      'Progressive rock',        // 92
      'Psychedelic rock',        // 93
      'Symphonic rock',          // 94
      'Slow rock',               // 95
      'Big band',                // 96
      'Chorus',                  // 97
      'Easy listening',          // 98
      'Acoustic',                // 99
      'Humour',                  // 100
      'Speech',                  // 101
      'Chanson',                 // 102
      'Opera',                   // 103
      'Chamber music',           // 104
      'Sonata',                  // 105
      'Symphony',                // 106
      'Booty bass',              // 107
      'Primus',                  // 108
      'Porn groove',             // 109
      'Satire',                  // 110
      'Slow jam',                // 111
      'Club',                    // 112
      'Tango',                   // 113
      'Samba',                   // 114
      'Folklore',                // 115
      'Ballad',                  // 116
      'Power ballad',            // 117
      'Rhythmic Soul',           // 118
      'Freestyle',               // 119
      'Duet',                    // 120
      'Punk rock',               // 121
      'Drum solo',               // 122
      'A cappella',              // 123
      'Euro-house',              // 124
      'Dance hall',              // 125
      'Goa music',               // 126
      'Drum & bass',             // 127
      'Club-house',              // 128
      'Hardcore techno',         // 129
      'Terror',                  // 130
      'Indie',                   // 131
      'Britpop',                 // 132
      'Negerpunk',               // 133
      'Polsk punk',              // 134
      'Beat',                    // 135
      'Christian gangsta rap',   // 136
      'Heavy metal',             // 137
      'Black metal',             // 138
      'Crossover',               // 139
      'Contemporary Christian',  // 140
      'Christian rock',          // 141

      // 142 to 147 (since 1 June 1998 [Winamp 1.91])
      'Merengue',                // 142
      'Salsa',                   // 143
      'Thrash metal',            // 144
      'Anime',                   // 145
      'Jpop',                    // 146
      'Synthpop',                // 147

      // 148 to 191 (from November 2010 [Winamp 5.6])
      'Christmas',               // 148
      'Art rock',                // 149
      'Baroque',                 // 150
      'Bhangra',                 // 151
      'Big beat',                // 152
      'Breakbeat',               // 153
      'Chillout',                // 154
      'Downtempo',               // 155
      'Dub',                     // 156
      'EBM',                     // 157
      'Eclectic',                // 158
      'Electro',                 // 159
      'Electroclash',            // 160
      'Emo',                     // 161
      'Experimental',            // 162
      'Garage',                  // 163
      'Global',                  // 164
      'IDM',                     // 165
      'Illbient',                // 166
      'Industro-Goth',           // 167
      'Jam Band',                // 168
      'Krautrock',               // 169
      'Leftfield',               // 170
      'Lounge',                  // 171
      'Math rock',               // 172
      'New romantic',            // 173
      'Nu-breakz',               // 174
      'Post-punk',               // 175
      'Post-rock',               // 176
      'Psytrance',               // 177
      'Shoegaze',                // 178
      'Space rock',              // 179
      'Trop rock',               // 180
      'World music',             // 181
      'Neoclassical',            // 182
      'Audiobook',               // 183
      'Audio theatre',           // 184
      'Neue Deutsche Welle',     // 185
      'Podcast',                 // 186
      'Indie rock',              // 187
      'G-Funk',                  // 188
      'Dubstep',                 // 189
      'Garage rock',             // 190
      'Psybient'                 // 191
    );


function ValidID3v1Present(var Buff): Boolean;  // NOTE: Buff must have at least 128 bytes in size
function ValidID3v2Present(var Buff): Boolean;  // NOTE: Buff must have at least 10 bytes in size


implementation


function ValidID3v1Present(var Buff): Boolean;  // NOTE: Buff must have at least 128 bytes in size
var
  Tag: TID3v11;
begin
  Move(Buff, Tag, SizeOf(TID3v11));
  // ID3 Tag validity check...
  Result := (Tag.ID = ID3v1TagID);  // Make sure it has correct tag...
end;

function ValidID3v2Present(var Buff): Boolean;  // NOTE: Buff must have at least 10 bytes in size
var
  Header: TID3v2Header;
begin
  Move(Buff, Header, SizeOf(TID3v2Header));
  // ID3 Tag validity check...
  Result := (Header.ID = ID3v2TagID) and  // Make sure it has correct tag...
            (Header.Version.Major < $FF) and (Header.Version.Minor < $FF) and  // ...Version Major and Minor is never $FF...
            (Header.Size.Raw[0] < $80) and (Header.Size.Raw[1] < $80) and (Header.Size.Raw[2] < $80) and (Header.Size.Raw[3] < $80);  // ...all 4 bytes of size should never exceed $80, since in SyncSafe Int highest bit always 0
end;


{ TID3v2Size }

function TID3v2SyncSafeInt.Value: Cardinal;
begin
  Result := (Raw[3] and $7F) or
           ((Raw[2] and $7F) shl 7) or
           ((Raw[1] and $7F) shl 14) or
           ((Raw[0] and $7F) shl 21);
end;

{ TID3v2Header }

function TID3v2Header.UnsynchronisationSet: Boolean;
begin
  Result := Flags and $80 <> 0;
end;

function TID3v2Header.HasExtendedHeader: Boolean;
begin
  Result := Flags and $40 <> 0;
end;

function TID3v2Header.ExperimentalIndicator: Boolean;
begin
  Result := Flags and $20 <> 0;
end;

function TID3v2Header.FooterPresent: Boolean;
begin
  Result := Flags and $10 <> 0;
end;

{ TBigEndianInt }

function TBigEndianInt.AsCardinal: Cardinal;
begin
  Result := Raw[3] or
           (Raw[2] shl 8) or
           (Raw[1] shl 16) or
           (Raw[0] shl 24);
end;

function TBigEndianInt.AsInteger: Integer;
begin
  Result := Integer(AsCardinal);
end;

{ TID3v1 }

function GetID3v1String(var Buff; MaxLen: Integer): AnsiString;
var
  i: Integer;
begin
  SetLength(Result, MaxLen);
  FillChar(Result[1], 0, MaxLen);
  Move(Buff, Result[1], MaxLen);
  for i := 1 to MaxLen do
    if Result[i] = #0 then
    begin
      SetLength(Result, i - 1);
      Break;
    end;
end;

function TID3v11.Title: string;
begin
  Result := GetID3v1String(_Title, Length(_Title));
end;

function TID3v11.Artist: string;
begin
  Result := GetID3v1String(_Artist, Length(_Artist));
end;

function TID3v11.Album: string;
begin
  Result := GetID3v1String(_Album, Length(_Album));
end;

function TID3v11.Year: Integer;
var
  Code: Integer;
begin
  Val(GetID3v1String(_Year, 4), Result, Code);
  if Code > 0 then
    Result := 0;
end;

function TID3v11.Comment: string;
begin
  Result := GetID3v1String(_Comment, Length(_Comment));
end;

function TID3v11.GenreAsString: string;
begin
  if Genre < Length(ID3v1GenreList) then
    Result := ID3v1GenreList[Genre]
  else
    Result := 'Unknown';
end;

end.
