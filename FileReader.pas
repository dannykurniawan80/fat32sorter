{ ============================================================================
    File Name   : FileReader.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : Classes to read file entries from FAT32 volumes
    License     : GPLv3
  ============================================================================ }
unit FileReader;

interface

uses
  Classes, SysUtils, Generics.Defaults,
  FAT32, FAT32Struct,
  ID3, ID3Struct;

type
  FileReaderException = class(Exception)
  end;

  TDirEntryItem = class(TCollectionItem)
  private
    FFAT32EntryItem: TFAT32EntryItem;

    FPath: string;
    FLongFileName: string;
    FCreateDateTime: TDateTime;
    FLastAccessDate: TDate;
    FWriteDateTime: TDateTime;

    FID3: TID3;

    function GetAttribute: Integer;
    function GetFileName: string;
    function GetShortFileName: string;
    function GetSize: Cardinal;
    function GetFirstClusterNum: Cardinal;

  protected
    procedure Init(AFAT32EntryItem: TFAT32EntryItem; APath: string);

  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function IsDirectory: Boolean;
    function IsFile: Boolean;
    function IsVolume: Boolean;

    property FAT32EntryItem: TFAT32EntryItem read FFAT32EntryItem;

    property Path: string read FPath;
    property FileName: string read GetFileName;
    property ShortFileName: string read GetShortFileName;
    property Attribute: Integer read GetAttribute;
    property Size: Cardinal read GetSize;
    property CreateDateTime: TDateTime read FCreateDateTime;
    property WriteDateTime: TDateTime read FWriteDateTime;
    property LastAccessDate: TDate read FLastAccessDate;

    property FirstClusterNum: Cardinal read GetFirstClusterNum;

    property ID3: TID3 read FID3;
  end;


  PPathRec = ^TPathRec;
  TPathRec = record
    DirName: string;
    DirClusterNum: Cardinal;
  end;


  TDirEntryComparer = function(const Left, Right: TDirEntryItem): Integer of object;


  TDirEntries = class(TCollection)
  protected
    function GetItem(Index: Integer): TDirEntryItem;

  public
    constructor Create;
    destructor Destroy; override;

    function Add: TDirEntryItem;
    function IndexOf(FileName: string): Integer;

    procedure Sort(const AComparer: TDirEntryComparer); reintroduce;

    property Items[Index: Integer]: TDirEntryItem read GetItem;
  end;


  TFileReader = class
  private
    FDriveLetter: string;
    FCurrentPath: string;
    FCurrentDirEntries: TDirEntries;

    FAT32Reader: TFAT32Reader;
    PathStack: TList;

    function PushPath(DirName: string; DirClusterNum: Cardinal): PPathRec;
    function PopPath: PPathRec;
    function GetLastPathRec: PPathRec;
    procedure RemoveLastPathRec;
    procedure ClearPathStack;

    procedure UpdateCurrentPath;

    function GetOpened: Boolean;
    function GetCurrentDir: string;

  protected
    procedure FAT32EntryProc(FileEntry: TFAT32EntryItem);

  public
    constructor Create;
    destructor Destroy; override;

    procedure OpenDrive(ADriveLetter: string);
    procedure CloseDrive;

    procedure ChDir(DirName: string); overload;
    procedure ChDir(DirEntryItem: TDirEntryItem); overload;
    procedure ChDirUp;
    procedure ChRootDir;

    procedure ReloadCurrentDirEntries;
    procedure WriteCurrentDirEntries;

    property Opened: Boolean read GetOpened;
    property DriveLetter: string read FDriveLetter;
    property CurrentPath: string read FCurrentPath;
    property CurrentDir: string read GetCurrentDir;

    property CurrentDirEntries: TDirEntries read FCurrentDirEntries;
  end;


implementation

uses
  Windows;


{ TDirEntryItem }

constructor TDirEntryItem.Create;
begin
  FFAT32EntryItem := nil;
  FLongFileName := '';
  FID3 := nil;
end;

destructor TDirEntryItem.Destroy;
begin
  if Assigned(FFAT32EntryItem) then FFAT32EntryItem.Free;
  if Assigned(ID3) then ID3.Free;
  inherited;
end;

procedure TDIrEntryItem.Init(AFAT32EntryItem: TFAT32EntryItem; APath: string);
var
  i: Integer;
begin
  FFAT32EntryItem := AFAT32EntryItem;
  FPath := APath;

  FLongFileName := '';
  with FFAT32EntryItem do
  begin
    for i := 0 to Length(_LFNEntries) - 1 do
      FLongFileName := _LFNEntries[i].LDIR_Name + FLongFileName;

    if (FLongFileName = '') then
      if (_DirEntry.DIR_Attr and ATTR_VOLUME_ID) = 0 then
        FLongFileName := _DirEntry.DIR_Name_Format83
      else
        FLongFileName := _DirEntry.DIR_Name_Volume;

    FCreateDateTime := _DirEntry.DIR_CreateDateTime;
    FLastAccessDate := _DirEntry.DIR_LastAccessDate;
    FWriteDateTime := _DirEntry.DIR_WriteDateTime;
  end;

  // Check for ID3 if it is an MP3
  if IsFile and (UpperCase(ExtractFileExt(FLongFileName)) = '.MP3') then
    FID3 := CheckFileForID3(FPath + FLongFileName)
  else
    FID3 := nil;
end;

function TDirEntryItem.GetAttribute: Integer;
begin
  Result := FFAT32EntryItem._DirEntry.DIR_Attr;
end;

function TDirEntryItem.GetFileName: string;
begin
  Result := FLongFileName;
end;

function TDirEntryItem.GetShortFileName: string;
begin
  with FFAT32EntryItem._DirEntry do
    if DIR_Attr and 8 = 8 then
      Result := DIR_Name_Volume
    else
      Result := DIR_Name_Format83;
end;

function TDirEntryItem.GetSize: Cardinal;
begin
  Result := FFAT32EntryItem._DirEntry.DIR_FileSize;
end;

function TDirEntryItem.IsDirectory: Boolean;
begin
  Result := FFAT32EntryItem._DirEntry.DIR_Attr and faDirectory <> 0;
end;

function TDirEntryItem.IsFile: Boolean;
begin
  Result := FFAT32EntryItem._DirEntry.DIR_Attr and faDirectory = 0;
end;

function TDirEntryItem.IsVolume: Boolean;
begin
  Result := FFAT32EntryItem._DirEntry.DIR_Attr and 8 = 8;
end;

function TDirEntryItem.GetFirstClusterNum: Cardinal;
begin
  Result := FFAT32EntryItem._DIREntry.DIR_FirstCluster;
end;


{ TFileReader }

constructor TFileReader.Create;
begin
  FCurrentDirEntries := TDirEntries.Create;
  FAT32Reader := nil;
  PathStack := TList.Create;
end;

destructor TFileReader.Destroy;
begin
  if Opened then CloseDrive;
  if Assigned(FAT32Reader) then FreeAndNil(FAT32Reader);

  PathStack.Free;
  FCurrentDirEntries.Free;

  inherited;
end;


procedure TFileReader.FAT32EntryProc(FileEntry: TFAT32EntryItem);
begin
  with FCurrentDirEntries.Add do
    Init(FileEntry, CurrentPath);
end;

procedure TFileReader.UpdateCurrentPath;
var
  i: Integer;
begin
  FCurrentPath := '';
  for i := 0 to PathStack.Count - 1 do
    FCurrentPath := FCurrentPath + PPathRec(PathStack.Items[i])^.DirName + '\';
end;

function TFileReader.GetOpened: Boolean;
begin
  Result := Assigned(FAT32Reader);
end;

procedure TFileReader.OpenDrive(ADriveLetter: string);
begin
  if not Assigned(FAT32Reader) then
  begin
    FAT32Reader := TFAT32Reader.Create(ADriveLetter, False);

    {$IFDEF DEBUG}
    with FAT32Reader.FAT32Volume do
      OutputDebugString(PChar(Format(
          'Jump Boot              : [%s]'#13#10 +
          'OEM Name               : [%s]'#13#10 +
          'Bytes Per Sector       : [%d]'#13#10 +
          'Sectors Per Cluster    : [%d]'#13#10 +
          'Reserved Sectors Count : [%d]'#13#10 +
          'Num. FATs              : [%d]'#13#10 +
          '------------------------'#13#10 +
          'Sectors Per FAT        : [%d]'#13#10 +
          'File System Version    : [%d.%d]'#13#10 +
          'Root Dir First Cluster : [0x%x]'#13#10 +
          'FSInfo                 : [%d]'#13#10 +
          'Volume ID              : [%s]'#13#10 +
          'Volume Label           : [%s]'#13#10 +
          'File System Type       : [%s]'#13#10 +
          '------------------------'#13#10 +
          'First Cluster Sector   : [%d]'
        ,[
          '0x' + IntToHex(BS_JmpBoot[0], 2) + ' 0x' + IntToHex(BS_JmpBoot[1], 2) + ' 0x' + IntToHex(BS_JmpBoot[2], 2),
          BS_OEMName_AsString,
          BPB_BytesPerSec,
          BPB_SecPerClus,
          BPB_RsvdSecCnt,
          BPB_NumFATs,

          BPB_FATSz32,
          Hi(BPB_FSVer), Lo(BPB_FSVer),
          BPB_RootClus,
          BPB_FSInfo,
          BS_VolID_AsString,
          BS_VolLab_AsString,
          BS_FilSysType_AsString,

          UInt64(BPB_RsvdSecCnt) + UInt64(BPB_NumFATs * BPB_FATSz32)
        ])));
    {$ENDIF}

    FDriveLetter := ADriveLetter;
    PushPath(FDriveLetter, ROOTDIR_START_CLUSTER);

    FAT32Reader.ReadRootDir(FAT32EntryProc);
  end
  else
    raise FileReaderException.Create('Can''t open new Drive. Reader is still open!');
end;

function TFileReader.PushPath(DirName: string; DirClusterNum: Cardinal): PPathRec;
begin
  New(Result);
  Result^.DirName := DirName;
  Result^.DirClusterNum := DirClusterNum;
  PathStack.Add(Result);

  UpdateCurrentPath;
end;

function TFileReader.PopPath: PPathRec;
begin
  Result := GetLastPathRec;
  PathStack.Delete(PathStack.Count - 1);

  UpdateCurrentPath;
end;

function TFileReader.GetLastPathRec: PPathRec;
begin
  Result := PPathRec(PathStack.Items[PathStack.Count - 1]);
end;

procedure TFileReader.RemoveLastPathRec;
begin
  Dispose(PopPath);
end;

procedure TFileReader.ClearPathStack;
var
  PathRec: PPathRec;
begin
  while PathStack.Count > 0 do
  begin
    PathRec := PPathRec(PathStack.Items[0]);
    PathStack.Delete(0);
    Dispose(PathRec);
    FCurrentPath := '';
  end;
end;

procedure TFileReader.CloseDrive;
begin
  if Assigned(FAT32Reader) then
  begin
    ClearPathStack;
    FCurrentDirEntries.Clear;
    FreeAndNil(FAT32Reader);
  end
  else
    raise FileReaderException.Create('Reader is not open!');
end;

function TFileReader.GetCurrentDir: string;
begin
  Result := GetLastPathRec^.DirName;
end;


procedure TFileReader.ChDir(DirName: string);
var
  i: Integer;
begin
  for i := 0 to FCurrentDirEntries.Count - 1 do
    if FCurrentDirEntries.Items[i].FileName = DirName then
    begin
      ChDir(FCurrentDirEntries.Items[i]);
      Break;
    end;
end;

procedure TFileReader.ChDir(DirEntryItem: TDirEntryItem);
var
  PathRec: PPathRec;
begin
  if not Assigned(FAT32Reader) then
    raise FileReaderException.Create('Drive is not open!');

  if DirEntryItem.IsDirectory then
  begin
    if DirEntryItem.FileName <> '.' then
    begin
      if DirEntryItem.FileName = '..' then
        ChDirUp
      else
      begin
        PathRec := PushPath(DirEntryItem.FileName, DirEntryItem.FirstClusterNum);

        if Assigned(FCurrentDirEntries) then
          FCurrentDirEntries.Clear;

        FAT32Reader.ReadDirEntry(PathRec^.DirClusterNum, FAT32EntryProc);
      end;
    end;
  end
  else
    raise FileReaderException.Create(Format('"%s" is not a directory.', [DirEntryItem.FileName]));
end;

procedure TFileReader.ChDirUp;
var
  PathRec: PPathRec;
begin
  if not Assigned(FAT32Reader) then
    raise FileReaderException.Create('Drive is not open!');

  if PathStack.Count > 1 then
  begin
    RemoveLastPathRec;
    PathRec := GetLastPathRec;

    if Assigned(FCurrentDirEntries) then
      FCurrentDirEntries.Clear;

    FAT32Reader.ReadDirEntry(PathRec^.DirClusterNum, FAT32EntryProc);
  end
  else
    raise FileReaderException.Create('Already at root directory');
end;

procedure TFileReader.ChRootDir;
var
  PathRec: PPathRec;
begin
  if not Assigned(FAT32Reader) then
    raise FileReaderException.Create('Drive is not open!');

  while PathStack.Count > 1 do
    RemoveLastPathRec;

  if Assigned(FCurrentDirEntries) then
    FCurrentDirEntries.Clear;

  PathRec := GetLastPathRec;
  FAT32Reader.ReadDirEntry(PathRec^.DirClusterNum, FAT32EntryProc);
end;

procedure TFileReader.ReloadCurrentDirEntries;
var
  PathRec: PPathRec;
begin
  if not Assigned(FAT32Reader) then
    raise FileReaderException.Create('Drive is not open!');

  PathRec := GetLastPathRec;

  if Assigned(FCurrentDirEntries) then
    FCurrentDirEntries.Clear;

  FAT32Reader.ReadDirEntry(PathRec^.DirClusterNum, FAT32EntryProc);
end;

procedure TFileReader.WriteCurrentDirEntries;
var
  i: Integer;
  CurPathRec: PPathRec;
  FAT32Entries: array of TFAT32EntryItem;
begin
  if Assigned(FAT32Reader) then
  begin
    CurPathRec := GetLastPathRec;

    SetLength(FAT32Entries, CurrentDirEntries.Count);
    for i := 0 to CurrentDirEntries.Count - 1 do
      FAT32Entries[i] := CurrentDirEntries.Items[i].FAT32EntryItem;

    FAT32Reader.WriteDirEntry(CurPathRec^.DirClusterNum, FAT32Entries);

  end;
end;


{ TDirEntries }

constructor TDirEntries.Create;
begin
  inherited Create(TDirEntryItem);
end;

destructor TDirEntries.Destroy;
begin
  inherited;
end;

function TDirEntries.GetItem(Index: Integer): TDirEntryItem;
begin
  Result := TDirEntryItem(inherited GetItem(Index));
end;

function TDirEntries.Add: TDirEntryItem;
begin
  Result := TDirEntryItem(inherited Add);
end;

function TDirEntries.IndexOf(FileName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
    if Items[i].FileName = FileName then
    begin
      Result := i;
      Break;
    end;
end;



(*
type
  TDirEntriesCompare = class(TInterfacedObject, IComparer<TCollectionItem>)
    DirEntryCompare: TDirEntryComparer;
    constructor Create(AComparer: TDirEntryComparer);
    function Compare(const Left, Right: TCollectionItem): Integer;
  end;

constructor TDirEntriesCompare.Create(AComparer: TDirEntryComparer);
begin
  DirEntryCompare := AComparer;
end;

function TDirEntriesCompare.Compare(const Left, Right: TCollectionItem): Integer;
begin
  Result := DirEntryCompare(TDirEntryItem(Left), TDirEntryItem(Right));
end;

procedure TDirEntries.Sort(const AComparer: TDirEntryComparer);
var
  DirEntriesCompare: TDirEntriesCompare;
begin
  DirEntriesCompare := TDirEntriesCompare.Create(AComparer);
  try
    inherited Sort(DirEntriesCompare);
  finally
    DirEntriesCompare.Free;
  end;
end;
*)

procedure TDirEntries.Sort(const AComparer: TDirEntryComparer);
var
  i: Integer;
  List: TList;
begin
  List := TList.Create;
  try
    for i := 0 to Count - 1 do
      List.Add(Items[i]);

    List.SortList(
        function(Left, Right: Pointer): Integer
        begin
          Result := AComparer(TDirEntryItem(Left), TDirEntryItem(Right));
        end
      );

    for i := 0 to List.Count - 1 do
      TDirEntryItem(List[i]).Index := i;
  finally
    List.Free;
  end;
end;

end.
