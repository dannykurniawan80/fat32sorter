unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FAT32, ID3;

const
  APPLICATION_NAME = 'FAT32 Sorter';

type
  TMainForm = class(TForm)
    btnRefreshDriveList: TButton;
    cbbDriveList: TComboBox;
    lvFolderList: TListView;
    btnSort: TButton;
    cbbSortFuncList: TComboBox;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure lvFolderListData(Sender: TObject; Item: TListItem);
    procedure FormDestroy(Sender: TObject);
    procedure lvFolderListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure lvFolderListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure btnSortClick(Sender: TObject);
    procedure lvFolderListDblClick(Sender: TObject);
    procedure cbbDriveListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure cbbDriveListChange(Sender: TObject);
    procedure btnRefreshDriveListClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    DriveList: TList;
    FAT32: TFAT32;
    PathEntries: TList;
    FileEntries: TFileEntries;
    MP3Data: TList;

    procedure ClearDriveList;
    procedure RefreshDriveList;

    procedure CloseDrive;
    procedure OpenDrive(DriveLetter: string);

    function GetPath(PathDelimiter: string = '\'): string;

    procedure AddPathEntry(DirName: string; ClusterNum: Cardinal);
    procedure RemoveLastPathEntry;

    procedure ReadMP3Data;
    procedure ClearMP3Data;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

type
  PPathRec = ^TPathRec;
  TPathRec = record
    DirName: string;
    DirClusterNum: Cardinal;
  end;

  PDriveInfo = ^TDriveInfo;
  TDriveInfo = record
    DriveLetter: string;
    VolumeName: string;
    FileSystemName: string;
  end;

  TSortRec = record
    SortName: string;
    SortFunc: TFileEntryCompareFunc;
  end;

const
  ROOT_DIR_CLUSTER = 2;

var
  SortFuncList: array of TSortRec;


procedure GetDriveList(List: TStrings);
var
  i: Integer;
  LogicalDrives: Cardinal;
  DriveLetter: string;
  VolumeName: string;
  MaxComponentLen: Cardinal;
  FileSystemFlag: Cardinal;
  FileSystemName: string;
begin
  List.Clear;
  LogicalDrives := GetLogicalDrives;
  for i := 0 to 25 do
    if (LogicalDrives shr i) and 1 <> 0 then
    begin
      DriveLetter := Chr(65 + i) + ':';
      VolumeName := StringOfChar(#0, MAX_PATH + 1);
      FileSystemName := StringOfChar(#0, MAX_PATH + 1);

      GetVolumeInformation(
          PChar(DriveLetter + '\'),
          @VolumeName[1],
          MAX_PATH,
          nil,
          MaxComponentLen,
          FileSystemFlag,
          @FileSystemName[1],
          MAX_PATH
        );

      VolumeName := Trim(VolumeName);
      FileSystemName := Trim(FileSystemName);

      if VolumeName <> '' then
        VolumeName := ' [' + VolumeName + ']';
      List.Append(Format('%s [%s]%s', [DriveLetter, FileSystemName, VolumeName]));
    end;
end;


function TMainForm.GetPath(PathDelimiter: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to PathEntries.Count - 1 do
    Result := Result + PPathRec(PathEntries.Items[i])^.DirName + PathDelimiter;
end;

procedure TMainForm.AddPathEntry(DirName: string; ClusterNum: Cardinal);
var
  PathRec: PPathRec;
begin
  New(PathRec);
  PathRec^.DirName := DirName;
  PathRec^.DirClusterNum := ClusterNum;
  PathEntries.Add(PathRec);
end;

procedure TMainForm.ClearDriveList;
var
  DriveInfo: PDriveInfo;
begin
  cbbDriveList.Items.Clear;
  while DriveList.Count > 0 do
  begin
    DriveInfo := PDriveInfo(DriveList.Items[0]);
    DriveList.Delete(0);
    Dispose(DriveInfo);
  end;
end;

procedure TMainForm.ReadMP3Data;
var
  i: Integer;
  CurrentPath: string;
  FilePath: string;
  ID3: TID3;
begin
  if Assigned(FileEntries) then
  begin
    CurrentPath := GetPath;

    for i := 0 to FileEntries.Count - 1 do
    begin
      ID3 := nil;

      with FileEntries.Items[i] do
      begin
        if (not IsDirectory) and (UpperCase(ExtractFileExt(FileName)) = '.MP3')  then
        begin
          FilePath := CurrentPath + FileName;
          OutputDebugString(PChar(Format('[MP3] Processing [%s]', [FilePath])));
          ID3 := CheckFileForID3(FilePath);
        end;
      end;

      MP3Data.Add(ID3);
    end;
  end;
end;

procedure TMainForm.ClearMP3Data;
var
  ID3: TID3;
begin
  while MP3Data.Count > 0 do
  begin
    ID3 := TID3(MP3Data.Items[0]);
    MP3Data.Delete(0);
    if Assigned(ID3) then
      ID3.Free;
  end;
end;

procedure TMainForm.RefreshDriveList;
var
  i: Integer;
  LogicalDrives: Cardinal;
  DriveLetter: string;
  VolumeName: string;
  MaxComponentLen: Cardinal;
  FileSystemFlag: Cardinal;
  FileSystemName: string;
  DriveInfo: PDriveInfo;
begin
  cbbDriveList.ItemIndex := -1;
  ClearDriveList;

  LogicalDrives := GetLogicalDrives;
  for i := 0 to 25 do
    if (LogicalDrives shr i) and 1 <> 0 then
    begin
      DriveLetter := Chr(65 + i) + ':';
      VolumeName := StringOfChar(#0, MAX_PATH + 1);
      FileSystemName := StringOfChar(#0, MAX_PATH + 1);

      GetVolumeInformation(
          PChar(DriveLetter + '\'),
          @VolumeName[1],
          MAX_PATH,
          nil,
          MaxComponentLen,
          FileSystemFlag,
          @FileSystemName[1],
          MAX_PATH
        );

      VolumeName := Trim(VolumeName);
      FileSystemName := Trim(FileSystemName);

      New(DriveInfo);
      DriveInfo^.DriveLetter := DriveLetter;
      DriveInfo^.VolumeName := VolumeName;
      DriveInfo^.FileSystemName := FileSystemName;

      DriveList.Add(DriveInfo);

      cbbDriveList.Items.Add(Format('%s [%s] %s', [DriveLetter, FileSystemName, VolumeName]));
    end;
end;

procedure TMainForm.RemoveLastPathEntry;
var
  PathRec: PPathRec;
begin
  if PathEntries.Count > 0 then
  begin
    PathRec := PPathRec(PathEntries.Items[PathEntries.Count - 1]);
    PathEntries.Delete(PathEntries.Count - 1);
    Dispose(PathRec);
  end;
end;

procedure TMainForm.CloseDrive;
begin
  lvFolderList.Items.Clear;

  if Assigned(FAT32) then
    FreeAndNil(FAT32);
  if Assigned(FileEntries) then
    FreeAndNil(FileEntries);
  while PathEntries.Count > 0 do
    RemoveLastPathEntry;
end;

procedure TMainForm.OpenDrive(DriveLetter: string);
begin
  FAT32 := TFAT32.Create(DriveLetter, False);

  FileEntries := FAT32.ReadRootDirEntry;
  AddPathEntry(DriveLetter, FileEntries.ClusterNum);

  ReadMP3Data;

  lvFolderList.Items.Count := FileEntries.Count;
  lvFolderList.Refresh;

  Caption := Format('%s [%s]', [APPLICATION_NAME, GetPath]);

  with FAT32.FAT32Volume do
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
end;

procedure TMainForm.btnRefreshDriveListClick(Sender: TObject);
begin
  CloseDrive;
  ClearDriveList;
  RefreshDriveList;
end;

procedure TMainForm.btnSortClick(Sender: TObject);
begin
  if Assigned(FileEntries) and (cbbSortFuncList.ItemIndex >= 0) then
  begin
    FileEntries.Sort(SortFuncList[cbbSortFuncList.ItemIndex].SortFunc);
    lvFolderList.Refresh;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  if Assigned(FileEntries) then
    if FAT32.WriteDirEntry(FileEntries) then
      ShowMessage('Success!')
    else
      ShowMessage('Failed!');
end;

procedure TMainForm.cbbDriveListChange(Sender: TObject);
var
  DriveLetter: string;
begin
  if cbbDriveList.ItemIndex >= 0 then
  begin
    CloseDrive;
    DriveLetter := Copy(cbbDriveList.Items[cbbDriveList.ItemIndex], 1, 2);
    OpenDrive(DriveLetter);
  end;
end;

procedure TMainForm.cbbDriveListDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  S: string;
begin
  with cbbDriveList.Canvas do
  begin
    if PDriveInfo(DriveList.Items[Index])^.FileSystemName <> 'FAT32' then
    begin
      Font.Style := [fsItalic];
      if odSelected in State then
        Font.Color := clInactiveCaptionText
      else
        Font.Color := clGrayText;
    end
    else
      Font.Style := [fsBold];

    Brush.Style := bsSolid;
    FillRect(Rect);
    InflateRect(Rect, -2, -1);

    S := cbbDriveList.Items[Index];
    DrawText(Handle, PChar(S), Length(S), Rect, DT_LEFT or DT_VCENTER);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  FAT32 := nil;
  FileEntries := nil;
  DriveList := TList.Create;
  PathEntries := TList.Create;
  MP3Data := TList.Create;

  RefreshDriveList;

  for i := Low(SortFuncList) to High(SortFuncList) do
    cbbSortFuncList.Items.Add(SortFuncList[i].SortName);

  Caption := APPLICATION_NAME;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ClearDriveList;
  CloseDrive;
  ClearMP3Data;

  MP3Data.Free;
  PathEntries.Free;
  DriveList.Free;
end;

procedure TMainForm.lvFolderListData(Sender: TObject; Item: TListItem);
var
  SizeStr: string;
begin
  if FileEntries <> nil then
    with FileEntries.Items[Item.Index] do
    begin
      Item.Caption := FileName;
      SizeStr := '';

      Item.SubItems.Append(FormatDateTime('dd-mmm-yyyy hh:nn:ss', WriteDateTime));

      if Attribute and faDirectory <> 0 then
        Item.SubItems.Append('File folder')
      else if Attribute and 8 <> 0 then
        Item.SubItems.Append('Volume ID')
      else
      begin
        Item.SubItems.Append('File');
        SizeStr := FormatFloat('#,##0', Size);
      end;

      Item.SubItems.Append(SizeStr);

      if Assigned(MP3Data.Items[Item.Index]) then
        with TID3(MP3Data.Items[Item.Index]) do
        begin
          Item.SubItems.Append(IntToStr(Track));
          Item.SubItems.Append(Album);
          Item.SubItems.Append(Artist);
          Item.SubItems.Append(Title);
          Item.SubItems.Append(IntToStr(Year));
          Item.SubItems.Append(IntToStr(Disc));
        end;
    end;
end;

procedure TMainForm.lvFolderListDblClick(Sender: TObject);
var
  PathRec: TPathRec;
  PrevDirName, DirName: string;
  DirClusterNum: Cardinal;
  Selected: TFileEntry;
begin
  if Assigned(FileEntries) and (lvFolderList.ItemIndex >= 0) then
  begin
    PrevDirName := '';
    Selected := FileEntries.Items[lvFolderList.ItemIndex];

    if Selected.IsDirectory then
      if Selected.FileName <> '.' then
      begin
        if (Selected.FileName = '..') and (PathEntries.Count > 1) then  // go up
        begin
          PrevDirName := PPathRec(PathEntries.Last)^.DirName;
          RemoveLastPathEntry;

          PathRec := PPathRec(PathEntries.Items[PathEntries.Count - 1])^;
          DirClusterNum := PathRec.DirClusterNum;

          FileEntries.Free;
          FileEntries := FAT32.ReadDirEntry(DirClusterNum, PathRec.DirName);

          ClearMP3Data;
          ReadMP3Data;
        end
        else
        begin
          DirName := Selected.FileName;
          DirClusterNum := Selected.FirstClusterNum;

          FileEntries.Free;
          FileEntries := FAT32.ReadDirEntry(DirClusterNum, DirName);

          AddPathEntry(DirName, DirClusterNum);

          ClearMP3Data;
          ReadMP3Data;
        end;

        lvFolderList.Items.Count := FileEntries.Count;
        lvFolderList.Refresh;
        lvFolderList.ClearSelection;

        if PrevDirName <> '' then
          lvFolderList.ItemIndex := FileEntries.IndexOf(PrevDirName);

        Caption := GetPath;
      end;
  end;
end;

procedure TMainForm.lvFolderListDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i: Integer;
  DropItemIndex, SelectionCount: Integer;
  DropItem: TListItem;
  MovedItemList: TList;
begin
  SelectionCount := 0;
  if Sender = Source then
  begin
    MovedItemList := TList.Create;
    try
      with TListView(Sender) do
      begin
        for i := 0 to Items.Count - 1 do
          if Items[i].Selected then
          begin
            MovedItemList.Add(Pointer(i));
            Inc(SelectionCount);
          end;

        DropItem := GetItemAt(X, Y);
        if DropItem <> nil then
          DropItemIndex := DropItem.Index
        else
          DropItemIndex := FileEntries.Count - 1;

        for i := 0 to MovedItemList.Count - 1 do
        begin
          FileEntries.Move(Integer(MovedItemList.Items[i]), DropItemIndex + i);
          MP3Data.Move(Integer(MovedItemList.Items[i]), DropItemIndex + i);
        end;

        ClearSelection;
        if DropItemIndex >= 0 then
        begin
          ItemIndex := DropItemIndex;
          for i := 1 to SelectionCount - 1 do
            Items[DropItemIndex + i].Selected := True;
        end;

        Refresh;
      end;
    finally
      MovedItemList.Free;
    end;
  end;
end;

procedure TMainForm.lvFolderListDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Sender = lvFolderList;
end;


function CreateSortRec(SortName: string; SortFunc: TFileEntryCompareFunc): TSortRec;
begin
  Result.SortName := SortName;
  Result.SortFunc := SortFunc;
end;

function DefaultSort(Item1, Item2: TFileEntry): Integer;
begin
  if Item1.IsVolume then
    Result := -1
  else if Item2.IsVolume then
    Result := 1
  else if Item1.IsDirectory and Item2.IsFile then
    Result := -1
  else if Item1.IsFile and Item2.IsDirectory then
    Result := 1
  else if Item1.IsDirectory and (Item1.FileName = '.') then
    Result := -1
  else if Item2.IsDirectory and (Item2.FileName = '.') then
    Result := 1
  else if Item1.IsDirectory and (Item1.FileName = '..') then
    Result := -1
  else if Item2.IsDirectory and (Item2.FileName = '..') then
    Result := 1
  else
    Result := -99;
end;

initialization
  SetLength(SortFuncList, 4);

  SortFuncList[0] := CreateSortRec('File Name [A-Z] (Case Sensitive)',
      function(Item1, Item2: TFileEntry): Integer
      begin
        Result := DefaultSort(Item1, Item2);
        if Result = -99 then
          if (Item1.IsDirectory and Item2.IsDirectory) or (Item1.IsFile and Item2.IsFile) then
          begin
            if Item1.FileName < Item2.FileName then
              Result := -1
            else if Item1.FileName > Item2.FileName then
              Result := 1
            else
              Result := 0;
          end;
      end
    );

  SortFuncList[1] := CreateSortRec('File Name [A-Z] (Case Insensitive)',
      function(Item1, Item2: TFileEntry): Integer
      begin
        Result := DefaultSort(Item1, Item2);
        if Result = -99 then
          if (Item1.IsDirectory and Item2.IsDirectory) or (Item1.IsFile and Item2.IsFile) then
          begin
            if UpperCase(Item1.FileName) < UpperCase(Item2.FileName) then
              Result := -1
            else if UpperCase(Item1.FileName) > UpperCase(Item2.FileName) then
              Result := 1
            else
              Result := 0;
          end;
      end
    );

  SortFuncList[2] := CreateSortRec('Date Modified [A-Z]',
      function(Item1, Item2: TFileEntry): Integer
      begin
        Result := DefaultSort(Item1, Item2);
        if Result = -99 then
          if (Item1.IsDirectory and Item2.IsDirectory) or (Item1.IsFile and Item2.IsFile) then
          begin
            if Item1.WriteDateTime < Item2.WriteDateTime then
              Result := -1
            else if Item1.WriteDateTime > Item2.WriteDateTime then
              Result := 1
            else
              Result := 0;
          end;
      end
    );

  SortFuncList[3] := CreateSortRec('Date Modified [Z-A]',
      function(Item1, Item2: TFileEntry): Integer
      begin
        Result := DefaultSort(Item1, Item2);
        if Result = -99 then
          if (Item1.IsDirectory and Item2.IsDirectory) or (Item1.IsFile and Item2.IsFile) then
          begin
            if Item1.WriteDateTime > Item2.WriteDateTime then
              Result := -1
            else if Item1.WriteDateTime < Item2.WriteDateTime then
              Result := 1
            else
              Result := 0;
          end;
      end
    );

end.
