unit FileSorter;

interface

uses
  FileReader;

type
  TSortDirection = (sdAscending, sdDescending);
  TSortDirectoryOption = (sdoDirectoryFirst, sdoDirectoryLast, sdoNone);


  TFileSortClass = class of TFileSortBase;

  TFileSortBase = class
  private
    FSortTitle: string;
    FSortSystemDirs: Boolean;
    FSortDirectoryOption: TSortDirectoryOption;
    FSortDirection: TSortDirection;

  protected
    procedure SetSortTitle(const SortTitle: string);
    procedure SetSortDirectoryOption(const Value: TSortDirectoryOption); virtual;
    procedure SetSortDirection(const Value: TSortDirection); virtual;

  public
    constructor Create(SortDirectoryOption: TSortDirectoryOption = sdoDirectoryFirst);

    function Compare(const Left, Right: TDirEntryItem): Integer; virtual;

    property SortTitle: string read FSortTitle;
    property SortSystemDirs: Boolean read FSortSystemDirs write FSortSystemDirs;
    property SortDirectoryOption: TSortDirectoryOption read FSortDirectoryOption write SetSortDirectoryOption;
    property SortDirection: TSortDirection read FSortDirection write SetSortDirection;
  end;


  TFileSortByStringBase = class(TFileSortBase)
  private
    FCaseSensitive: Boolean;
  protected
    procedure SetCaseSensitive(const Value: Boolean); virtual;
    function CompareString(Left, Right: string): Integer; virtual;
  public
    constructor Create;
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive;
  end;

  // Sort by File Name
  TFileSortByFileName = class(TFileSortByStringBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by Modified Date
  TFileSortByModifiedDate = class(TFileSortBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by Creation Date
  TFileSortByCreationDate = class(TFileSortBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by Size
  TFileSortBySize = class(TFileSortBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;


  // Sort by ID3 Base Class
  TFileSortByID3Base = class(TFileSortBase)
  private
    FSortHasID3First: Boolean;
  protected
    procedure SetSortHasID3First(const Value: Boolean); virtual;
    function CompareHasID3(const Left, Right: TDirEntryItem): Integer; virtual;
  public
    constructor Create;
    property SortHasID3First: Boolean read FSortHasID3First write SetSortHasID3First;
  end;

  // Sort by ID3 String Base Class
  TFileSortByID3StringBase = class(TFileSortByID3Base)
  private
    FCaseSensitive: Boolean;
  protected
    procedure SetCaseSensitive(const Value: Boolean); virtual;
    function CompareString(Left, Right: string): Integer; virtual;
  public
    constructor Create;
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive;
  end;

  // Sort by ID3 Track
  TFileSortByID3Track = class(TFileSortByID3Base)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by ID3 Disc
  TFileSortByID3Disc = class(TFileSortByID3Base)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by ID3 Title
  TFileSortByID3Title = class(TFileSortByID3StringBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by ID3 Artist
  TFileSortByID3Artist = class(TFileSortByID3StringBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by ID3 Album
  TFileSortByID3Album = class(TFileSortByID3StringBase)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;

  // Sort by ID3 Year
  TFileSortByID3Year = class(TFileSortByID3Base)
  public
    constructor Create;
    function Compare(const Left, Right: TDirEntryItem): Integer; override;
  end;


implementation

uses
  SysUtils;

const
  LEFT_ITEM: array[TSortDirection] of Integer = ( -1, 1 );
  RIGHT_ITEM: array[TSortDirection] of Integer = ( 1, -1 );

{ TBasicFileComparer }

constructor TFileSortBase.Create(SortDirectoryOption: TSortDirectoryOption);
begin
  FSortTitle := 'Default';
  FSortSystemDirs := True;
  FSortDirectoryOption := SortDirectoryOption;
  FSortDirection := sdAscending;
end;

procedure TFileSortBase.SetSortTitle(const SortTitle: string);
begin
  FSortTitle := SortTitle;
end;

procedure TFileSortBase.SetSortDirectoryOption(const Value: TSortDirectoryOption);
begin
  FSortDirectoryOption := Value;
end;

procedure TFileSortBase.SetSortDirection(const Value: TSortDirection);
begin
  FSortDirection := Value;
end;

function TFileSortBase.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := -99;

  if FSortSystemDirs then
  begin
    if Left.IsVolume then
      Result := -1
    else if Right.IsVolume then
      Result := 1
    else if Left.IsDirectory and (Left.FileName = '.') then
      Result := -1
    else if Right.IsDirectory and (Right.FileName = '.') then
      Result := 1
    else if Left.IsDirectory and (Left.FileName = '..') then
      Result := -1
    else if Right.IsDirectory and (Right.FileName = '..') then
      Result := 1
    else if Left.IsDirectory and Right.IsFile then
    begin
      case FSortDirectoryOption of
        sdoDirectoryFirst:
          Result := -1;
        sdoDirectoryLast:
          Result := 1;
      end;
    end
    else if Left.IsFile and Right.IsDirectory then
    begin
      case FSortDirectoryOption of
        sdoDirectoryFirst:
          Result := 1;
        sdoDirectoryLast:
          Result := -1;
      end;
    end;
  end;
end;

{ TFileSortByStringBase }

constructor TFileSortByStringBase.Create;
begin
  inherited Create;
  FCaseSensitive := True;
end;

procedure TFileSortByStringBase.SetCaseSensitive(const Value: Boolean);
begin
  FCaseSensitive := Value;
end;

function TFileSortByStringBase.CompareString(Left, Right: string): Integer;
begin
  if not FCaseSensitive then
  begin
    Left := UpperCase(Left);
    Right := UpperCase(Right);
  end;

  if Left < Right then
    Result := LEFT_ITEM[SortDirection]
  else if Left > Right then
    Result := RIGHT_ITEM[SortDirection]
  else
    Result := 0;
end;

{ TFileSortByFileName }

constructor TFileSortByFileName.Create;
begin
  inherited Create;
  SetSortTitle('File Name')
end;

function TFileSortByFileName.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsDirectory or Left.IsFile) and (Right.IsDirectory or Right.IsFile) then
      Result := CompareString(Left.FileName, Right.FileName)
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByModifiedDate }

constructor TFileSortByModifiedDate.Create;
begin
  inherited Create;
  SetSortTitle('File Modified Date');
end;

function TFileSortByModifiedDate.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsDirectory and Right.IsDirectory) or (Left.IsFile and Right.IsFile) then
    begin
      if Left.WriteDateTime < Right.WriteDateTime then
        Result := LEFT_ITEM[SortDirection]
      else if Left.WriteDateTime > Right.WriteDateTime then
        Result := RIGHT_ITEM[SortDirection]
      else
        Result := 0;
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByCreationDate }

constructor TFileSortByCreationDate.Create;
begin
  inherited Create;
  SetSortTitle('File Creation Date');
end;

function TFileSortByCreationDate.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsDirectory and Right.IsDirectory) or (Left.IsFile and Right.IsFile) then
    begin
      if Left.CreateDateTime < Right.CreateDateTime then
        Result := LEFT_ITEM[SortDirection]
      else if Left.CreateDateTime > Right.CreateDateTime then
        Result := RIGHT_ITEM[SortDirection]
      else
        Result := 0;
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortBySize }

constructor TFileSortBySize.Create;
begin
  inherited Create;
  SetSortTitle('File Size');
end;

function TFileSortBySize.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsDirectory and Right.IsDirectory) or (Left.IsFile and Right.IsFile) then
    begin
      if Left.Size < Right.Size then
        Result := LEFT_ITEM[SortDirection]
      else if Left.Size > Right.Size then
        Result := RIGHT_ITEM[SortDirection]
      else
        Result := 0;
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByID3Base }

constructor TFileSortByID3Base.Create;
begin
  inherited Create;
  FSortHasID3First := True;
end;

procedure TFileSortByID3Base.SetSortHasID3First(const Value: Boolean);
begin
  FSortHasID3First := Value;
end;

function TFileSortByID3Base.CompareHasID3(const Left, Right: TDirEntryItem): Integer;
begin
  if FSortHasID3First then
  begin
    if Assigned(Left.ID3) and (not Assigned(Right.ID3)) then
      Result := -1
    else if (not Assigned(Left.ID3)) and Assigned(Right.ID3) then
      Result := 1
    else
      Result := 0;
  end
  else
  begin
    if (not Assigned(Left.ID3)) and Assigned(Right.ID3) then
      Result := -1
    else if Assigned(Left.ID3) and (not Assigned(Right.ID3)) then
      Result := 1
    else
      Result := 0;
  end;
end;

{ TFileSortByID3StringBase }

constructor TFileSortByID3StringBase.Create;
begin
  inherited Create;
  FCaseSensitive := True;
end;

procedure TFileSortByID3StringBase.SetCaseSensitive(const Value: Boolean);
begin
  FCaseSensitive := Value;
end;

function TFileSortByID3StringBase.CompareString(Left, Right: string): Integer;
begin
  if not FCaseSensitive then
  begin
    Left := UpperCase(Left);
    Right := UpperCase(Right);
  end;

  if Left < Right then
    Result := LEFT_ITEM[SortDirection]
  else if Left > Right then
    Result := RIGHT_ITEM[SortDirection]
  else
    Result := 0;
end;

{ TFileSortByID3Track }

constructor TFileSortByID3Track.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Track Number');
end;

function TFileSortByID3Track.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
      begin
        if Left.ID3.Track < Right.ID3.Track then
          Result := LEFT_ITEM[SortDirection]
        else if Left.ID3.Track > Right.ID3.Track then
          Result := RIGHT_ITEM[SortDirection]
        else
          Result := 0;
      end
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;
  end;
end;

{ TFileSortByID3Disc }

constructor TFileSortByID3Disc.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Disc');
end;

function TFileSortByID3Disc.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
      begin
        if Left.ID3.Disc < Right.ID3.Disc then
          Result := LEFT_ITEM[SortDirection]
        else if Left.ID3.Disc > Right.ID3.Disc then
          Result := RIGHT_ITEM[SortDirection]
        else
          Result := 0;
      end
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByID3Title }

constructor TFileSortByID3Title.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Title');
end;

function TFileSortByID3Title.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
        Result := CompareString(Left.ID3.Title, Right.ID3.Title)
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByID3Artist }

constructor TFileSortByID3Artist.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Artist');
end;

function TFileSortByID3Artist.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
        Result := CompareString(Left.ID3.Artist, Right.ID3.Artist)
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByID3Album }

constructor TFileSortByID3Album.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Album');
end;

function TFileSortByID3Album.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
        Result := CompareString(Left.ID3.Album, Right.ID3.Album)
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

{ TFileSortByID3Year }

constructor TFileSortByID3Year.Create;
begin
  inherited Create;
  SetSortTitle('ID3 Year');
end;

function TFileSortByID3Year.Compare(const Left, Right: TDirEntryItem): Integer;
begin
  Result := inherited;
  if Result = -99 then
  begin
    if (Left.IsFile and Right.IsFile) then
    begin
      if Assigned(Left.ID3) and Assigned(Right.ID3) then  // if both has ID3...
      begin
        if Left.ID3.Year < Right.ID3.Year then
          Result := LEFT_ITEM[SortDirection]
        else if Left.ID3.Year > Right.ID3.Year then
          Result := RIGHT_ITEM[SortDirection]
        else
          Result := 0;
      end
      else
        Result := CompareHasID3(Left, Right);  // in case one of them doesn't have ID3...
    end
    else
      Result := 0;  // Make sure we're note returning -99
  end;
end;

end.
